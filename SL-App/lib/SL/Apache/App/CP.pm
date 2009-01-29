package SL::Apache::App::CP;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT AUTH_REQUIRED );

use Apache2::Log             ();
use Apache2::SubRequest      ();
use Apache2::Connection      ();
use Apache2::Request         ();
use Apache2::SubRequest      ();
use Apache::Session::DB_File ();

use base 'SL::Apache::App';

use Data::Dumper;
use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Regexp::Common qw( net );
use Mail::Mailer     ();
use DateTime         ();
use Business::PayPal ();

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

our $Cookie_name = 'SLN CP';

use SL::Payment                 ();
use SL::Apache::App::CookieAuth ();

use constant DEBUG     => $ENV{SL_DEBUG}     || 0;
use constant TEST_MODE => $ENV{SL_TEST_MODE} || 0;

our $From = 'SLN Support <support@silverliningnetworks.com>';

use SL::Model;
use SL::Model::App;    # works for now

our ( $Config, %Sess_opts );

BEGIN {
    require SL::Config;
    $Config = SL::Config->new();

    # session
    unless ( -d $Config->sl_app_session_dir ) {
        system( 'mkdir -p ' . $Config->sl_app_session_dir ) == 0 or die $!;
    }

    %Sess_opts = (
        FileName => join( '/',
            $Config->sl_app_session_dir, $Config->sl_app_session_lock_file ),
        LockDirectory => $Config->sl_app_session_dir,
        Transaction   => 1,
    );
}

sub check {
    my ( $class, $r ) = @_;

    my $req  = Apache2::Request->new($r);
    my $mac  = $req->param('mac');
    my $plan = $req->param('plan');

    my %payment_args = (
        mac             => $mac,
        account_id      => $r->pnotes('router')->account_id->account_id,
        approved        => 't',
        token_processed => 't',
    );

    # hack to separate paid vs ad supported, very bad
    if ( $plan && ( $plan eq 'ads' ) ) {
        $payment_args{'amount'} = '$0.00';
    }
    else {

        # look for paid plans
        $payment_args{'amount'} = { '>', '$0.00' };
    }

    # get the most recent payment for payment args
    my ($payment) =
      SL::Model::App->resultset('Payment')
      ->search( \%payment_args, { order_by => 'cts DESC', }, );

    if ( DEBUG && $payment ) {
        $r->log->debug( "payment is " . Dumper($payment) );
    }

    return Apache2::Const::NOT_FOUND unless $payment;

    my $now = DateTime->now( time_zone => 'local' );
    my $stop = DateTime::Format::Pg->parse_datetime( $payment->stop );
    $stop->set_time_zone('local');

    # see if the payment is expired
    if ( $now > $stop ) {

        $r->log->info(
            sprintf(
                "auth mac %s expired, now %s, expired %s, payment id %s",
                $mac,                          $now->mdy . ' ' . $now->hms,
                $stop->mdy . ' ' . $stop->hms, $payment->payment_id
            )
        );
        return Apache2::Const::AUTH_REQUIRED;
    }

    $r->log->info(
        sprintf(
            "auth mac %s valid, now %s, expires %s, payment id %s",
            $mac,                          $now->mdy . ' ' . $now->hms,
            $stop->mdy . ' ' . $stop->hms, $payment->payment_id
        )
    );

    return Apache2::Const::OK;
}

sub post {
    my ( $class, $r ) = @_;

    my $req      = Apache2::Request->new($r);
    my $dest_url = $req->param('url');
    my $mac      = $req->param('mac');

    my $router = $r->pnotes('router') || die 'router missing';
    my $splash_href = $router->splash_href
      || die 'router not configured for CP';

    my $location = $class->make_post_url( $splash_href, $dest_url );

    $r->log->info("splash page redirecting to $location for mac $mac");

    $r->headers_out->set( Location => $location );
    $r->no_cache(1);

    return Apache2::Const::REDIRECT;
}

sub make_post_url {
    my ( $class, $splash_url, $dest_url ) = @_;

    $dest_url = URI::Escape::uri_escape($dest_url);
    my $separator;
    if ( $splash_url =~ m/\?/ ) {

        # user has some args
        $separator = '&';
    }
    else {
        $separator = '?';
    }

    my $location = $splash_url . $separator . "url=$dest_url";

    return $location;
}

sub paypal_notify {
    my ( $class, $r ) = @_;

    my $req   = Apache2::Request->new($r);
    my %query = %{ $req->param };

    $r->log->error( "Notify Query params is " . Dumper( \%query ) );

    my $id = $query{custom};
    $r->log->error("ID is $id");

    my $paypal = Business::PayPal->new($id);
    my ( $txnstatus, $reason ) = $paypal->ipnvalidate( \%query );
    if ( !$txnstatus ) {
        $r->log->error("PayPal failed: $reason");
        return Apache2::Const::SERVER_ERROR;
    }

    # transaction is ok
    my $payment;
    eval { $payment = SL::Payment->paypal_save( \%query ) };
    if ($@) {
        $r->log->error(
            "could not save Paypal IPN to database: $@\n" . Dumper( \%query ) );
        return Apache2::Const::SERVER_ERROR;
    }

    return Apache2::Const::OK;
}

sub paypal_return {
    my ( $class, $r ) = @_;

    my $req    = Apache2::Request->new($r);
    my %query  = %{ $req->param };
    my $custom = $query{custom} || die "No custom field: " . Dumper( \%query );

    # grab the cookies
    my $jar    = Apache2::Cookie::Jar->new($r);
    my $cookie = $jar->cookies($Cookie_name);

    unless ($cookie) {

        # no cookie is definitely a problem, means the cookie disappeared betwee
        # paypal and us
        $r->log->error(
            "$$ cookie missing for return query " . Dumper( \%query ) );
        return Apache2::Const::NOT_FOUND;
    }

    # decode the cookie
    my %state      = $class->decode( $cookie->value );
    my $session_id = $state{session_id};

    # load the session
    my %session;
    eval {
        tie %session, 'Apache::Session::DB_File', $session_id, \%Sess_opts;
        $r->log->error( "tied session $session_id: " . Dumper( \%session ) )
          if DEBUG;
    };

    if ($@) {
        $r->log->error(
            "session missing id $session_id, args " . Dumper( \%query ) );
        return Apache2::Const::SERVER_ERROR;
    }

    # get the router
    my $router =
      SL::Model::App->resultset('Router')
      ->search( { router_id => $session{router_id} } );

    unless ($router) {
        $r->log->error(
            "router id not found for session " . Dumper( \%session ) );
        return Apache2::Const::SERVER_ERROR;
    }

    my $splash_href = $router->splash_href;
    unless ($splash_href) {
        $r->log->error( "router not configured for CP: " . Dumper($router) );

        # send to a safe landing
        $r->headers_out->set(
            Location => 'http://www.silverliningnetworks.com/' );
        return Apache2::Const::REDIRECT;
    }
    else {
        $r->headers_out->set( Location => $splash_href );
    }

    return Apache2::Const::REDIRECT;
}

sub auth {
    my ( $class, $r ) = @_;

    my $req     = Apache2::Request->new($r);
    my $mac     = $req->param('mac');
    my $url     = $req->param('url');
    my $expired = $req->param('expired');

    unless ($mac) {
        $r->log->error( "$$ auth page called without mac from ip "
              . $r->connection->remote_ip
              . " url: "
              . $r->construct_url( $r->unparsed_uri ) );
        return Apache2::Const::NOT_FOUND;
    }

    $mac = URI::Escape::uri_unescape($mac);
    unless ( $mac =~ m/$RE{net}{MAC}/ ) {
        $r->log->error( "$$ auth page called with invalid mac $mac from ip "
              . $r->connection->remote_ip );
        return Apache2::Const::SERVER_ERROR;
    }

    my $output;
    $mac = URI::Escape::uri_escape($mac);
    $url = URI::Escape::uri_escape($url);
    my %args = (
        mac => $mac,
        url => $url,
    );
    if ( defined $req->param('expired') ) {
        $args{'expired'} = 1;
    }

    my $ok = $Tmpl->process( 'auth/index.tmpl', \%args, \$output, $r );
    $ok
      ? return $class->ok( $r, $output )
      : return $class->error( $r, "Template error: " . $Tmpl->error() );
}

sub valid_plan {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/(?:one|four|day|month)/ );
        return;
      }
}

sub valid_first {

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val eq 'First';

        return $val;
      }
}

sub valid_last {

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val eq 'Last';

        return $val;
      }
}

sub valid_cvv {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        return $val;
      }
}

sub valid_city {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val =~ /^ex\./;

        return $val;
      }
}

sub valid_street {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val =~ /^ex\./;

        return $val;
      }
}

sub valid_month {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        my $month = $1;

        return if $val < 1 || $val > 12;

        return $month;
      }
}

sub valid_year {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return if $val !~ /^(\d+)$/;

        my $year = $1;

        $val += ( $val < 70 ) ? 2000 : 1900 if $val < 1900;
        my @now = localtime();
        $now[5] += 1900;

        return if ( $val < $now[5] ) || ( $val == $now[5] && $val <= $now[4] );

        return $year;
      }
}

sub token {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $token = $req->param('token');
    my $mac   = $req->param('mac');

    $r->log->info("token $token, mac $mac");

    unless ( $token && $mac ) {
        $r->log->error("$$ sub token called without token $token and mac $mac");
        return Apache2::Const::SERVER_ERROR;
    }

    # verify that the token is good
    my ($payment) = SL::Model::App->resultset('Payment')->search(
        {
            mac        => $mac,
            md5        => $token,
            ip         => $r->connection->remote_ip,
            account_id => $r->pnotes('router')->account_id->account_id,
            approved   => 't',
        }
    );

    unless ($payment) {
        $r->log->error(
            "$$ missing payment request for mac $mac, token $token, ip "
              . $r->connection->remote_ip );
        return Apache2::Const::NOT_FOUND;
    }

    # check to make sure this payment hasn't already been called
    if ( $payment->token_processed ) {
        $r->log->error( "$$ duplicate processing attempt for payment id "
              . $payment->payment_id . ", ip "
              . $r->connection->remote_ip );
        return Apache2::Const::NOT_FOUND;
    }

    # check to make sure the payment hasn't expired
    my $stop = DateTime::Format::Pg->parse_datetime( $payment->stop );

    my $now = DateTime->now( time_zone => 'local' );
    if ( $now > $stop ) {

        # payment expired
        $r->log->info(
            "$$ token attempt for expired payment, token $token, mac $mac, ip "
              . $r->connection->remote_ip
              . ", stop time "
              . $stop->mdy . " "
              . $stop->hms
              . " epoch "
              . $stop->epoch
              . ", now time "
              . $now->mdy . " "
              . $now->hms
              . " epoch "
              . $now->epoch
              . " payment id "
              . $payment->payment_id );
        return Apache2::Const::AUTH_REQUIRED;
    }

    # ok the payment looks valid, return ok
    $payment->token_processed(1);
    $payment->update;

    $r->log->info("token $token, mac $mac VERIFIED");

    return Apache2::Const::OK;
}

sub send_cookie {
    my ( $class, $r, $session_id ) = @_;

    require Carp && Carp::confess('bad cookie attempt!')
      unless $session_id;

    # Give the user a new cookie
    my %state = (
        last_seen  => time(),
        session_id => $session_id,
    );

    my $cookie = Apache2::Cookie->new(
        $r,
        -name    => $Cookie_name,
        -value   => SL::Apache::App::CookieAuth->encode( \%state ),
        -expires => '15m',
        -path    => $Config->sl_app_base_uri,
    );

    $cookie->bake($r);

    # they're ok
    $r->log->debug( "send_cookie for state " . Data::Dumper::Dumper( \%state ) )
      if DEBUG;

    return 1;
}

sub paid {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $mac  = $req->param('mac');
    my $dest = $req->param('url');
    unless ($mac) {
        $r->log->error( "$$ auth page called without mac from ip "
              . $r->connection->remote_ip
              . " url: "
              . $r->construct_url( $r->unparsed_uri ) );
        return Apache2::Const::NOT_FOUND;
    }

    unless ( $mac =~ m/$RE{net}{MAC}/ ) {
        $r->log->error( "$$ auth page called with invalid mac from ip "
              . $r->connection->remote_ip );
        return Apache2::Const::SERVER_ERROR;
    }

    my $router = $r->pnotes('router');
    unless ($router) {
        $r->log->error('router not set');
        return Apache2::Const::SERVER_ERROR;
    }

    # apache request bug
    my $plan = $req->param('plan');

    # plan passed on GET
    my %tmpl_data = (
        errors => $args_ref->{errors},
        req    => $req,
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $account = $r->pnotes('router')->account_id;
        my $url     = $r->construct_url( $r->unparsed_uri );
        my @button_args =
          ( 'test', $url, $account->name . ' WiFi Purchase', 1 );

        # add the paypal button
        my ( $button, $id ) = SL::Payment->paypal_button(@button_args);
        $tmpl_data{paypal_button} = $button;

        # tie a session
        my %session;
        eval { tie %session, 'Apache::Session::DB_File', undef, \%Sess_opts; };

        if ($@) {
            $r->log->error("Could not tie session");
            return Apache2::Const::SERVER_ERROR;
        }

        my $session_id = $session{_session_id};
        $session{account_id} = $account->account_id;
        $session{mac}        = $mac;
        $session{ip}         = $r->connection->remote_ip;
        $session{custom}     = $id;

        # cookie the user with the id
        $class->send_cookie( $r, $session_id );

        my $output;
        my $ok = $Tmpl->process( 'auth/paid.tmpl', \%tmpl_data, \$output, $r );

        return $class->ok( $r, $output ) if $ok;
        return $class->error( $r, "Template error: " . $Tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        ## processing a payment, here we go

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

        my %payment_profile = (
            required => [
                qw( first_name last_name card_type card_number cvv2
                  month year street city zip state email plan mac )
            ],
            constraint_methods => {
                email       => email(),
                zip         => zip(),
                first_name  => valid_first(),
                last_name   => valid_last(),
                month       => valid_month(),
                year        => valid_year(),
                cvv2        => valid_cvv(),
                city        => valid_city(),
                street      => valid_street(),
                card_type   => cc_type(),
                card_number => cc_number( { fields => ['card_type'] } ),
                plan        => valid_plan(),
                mac         => qr/$RE{net}{MAC}/,
            }
        );

        $r->log->info("$$ about to validate form");
        my $results = Data::FormValidator->check( $req, \%payment_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            $r->log->error( "results: " . Dumper($results) );

            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->paid(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        $r->log->info("$$ about to process payment");
        ## process the payment
        my $account = $r->pnotes('router')->account_id;
        my $fname   = $req->param('first_name');
        my $lname   = $req->param('last_name');
        my $street  = $req->param('street');
        my $city    = $req->param('city');
        my $state   = $req->param('state');
        my $zip     = $req->param('zip');
        my $email   = $req->param('email');

        my $payment = SL::Payment->process(
            {
                account_id  => $account->account_id,
                mac         => $req->param('mac'),
                email       => $req->param('email'),
                card_type   => $req->param('card_type'),
                card_number => $req->param('card_number'),
                card_exp =>
                  join( '/', $req->param('month'), $req->param('year') ),
                cvv2       => $req->param('cvv2'),
                email      => $email,
                zip        => $zip,
                first_name => $fname,
                last_name  => $lname,
                ip         => $r->connection->remote_ip,
                street     => $street,
                city       => $city,
                state      => $state,
                referer    => $r->headers_in->{'referer'},
                plan       => $req->param('plan'),
            }
        );

        if ( $payment->error_message ) {

            # process errors
            $r->log->info(
                "$$ got payment errors: " . $payment->error_message );

            return $class->paid(
                $r,
                {
                    errors => { payment => $payment->error_message, },
                    req    => $req,
                }
            );
        }

        $r->log->info( "$$ payment auth code "
              . $payment->authorization_code
              . " processed OK" );

        # payment success, send receipt
        ($payment) =
          SL::Model::App->resultset('Payment')
          ->search( { payment_id => $payment->payment_id } );
        my $authorization_code = sprintf( "%s", $payment->authorization_code );

        my $mailer    = Mail::Mailer->new('qmail');
        my %mail_args = (
            'To'      => $email,
            'From'    => $From,
            'CC'      => $From,
            'Subject' => "WiFi Internet Receipt",
        );

        if ( $account->aaa_email_cc ) {
            $mail_args{'CC'} = $account->aaa_email_cc;
        }

        $mailer->open( \%mail_args );

        # plan is '4 hours'
        my $plan_hash = SL::Payment->plan($plan);
        my $duration  = join( ' ',
            ( values %{ $plan_hash->{duration} } )[0],
            ( keys %{ $plan_hash->{duration} } )[0] );

        my $date         = DateTime->now->mdy('/');
        my $network_name = $account->name;

        my $mail;
        my %tmpl_data = (
            email              => $email,
            fname              => $fname,
            lname              => $lname,
            city               => $city,
            state              => $state,
            street             => $street,
            zip                => $zip,
            plan               => $duration,
            network_name       => $network_name,
            authorization_code => $authorization_code,
            date               => $date,
            amount             => $plan_hash->{cost},
        );

        my $ok = $Tmpl->process( 'auth/receipt.tmpl', \%tmpl_data, \$mail, $r );
        return $class->error( $r, $mail ) if !$ok;

        print $mailer $mail;

        $mailer->close unless TEST_MODE;

        $r->log->info("$$ receipt for payment $authorization_code: $mail");

        my $lan_ip = $router->lan_ip
          || die 'router not configured for CP';

        ## payment successful, redirect to auth
        $mac  = URI::Escape::uri_escape($mac);
        $dest = URI::Escape::uri_escape($dest);
        $r->headers_out->set(
            Location => "http://$lan_ip/paid?mac=$mac&url=$dest&token="
              . $payment->md5 );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }
}

sub free {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    # apache request bug
    my $plan     = $req->param('plan');
    my $mac      = $req->param('mac');
    my $dest_url = $req->param('url');

    my $router = $r->pnotes('router');
    unless ($router) {
        $r->log->error('router not set');
        return Apache2::Const::SERVER_ERROR;
    }

    my $lan_ip = $router->lan_ip
      || die 'router not configured for CP';

    my $timeout = $router->splash_timeout || die 'router not configured for CP';

    my $account = $router->account_id;

    my $stop =
      DateTime::Format::Pg->format_datetime(
        DateTime->now( time_zone => 'local' )->add( 'minutes' => $timeout ) );

    # make a free payment entry
    my $payment = SL::Model::App->resultset('Payment')->create(
        {
            account_id => $account->account_id,
            mac        => $mac,
            amount     => '$0.00',
            stop       => $stop,
            email      => 'guest',
            last_four  => 0,
            card_type  => 'ads',
            ip         => $r->connection->remote_ip,
            expires    => $timeout,
            approved   => 't',
        }
    );

    $payment->update;

    # grab it for the md5
    ($payment) =
      SL::Model::App->resultset('Payment')
      ->search( { payment_id => $payment->payment_id } );

    ## payment successful, redirect to auth
    $mac      = URI::Escape::uri_escape($mac);
    $dest_url = URI::Escape::uri_escape($dest_url);
    $r->headers_out->set(
        Location => "http://$lan_ip/ads?mac=$mac&url=$dest_url&token="
          . $payment->md5 );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub publisher {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    # apache request bug
    my $plan = $req->param('plan');

    # plan passed on GET
    my %tmpl_data = (
        errors => $args_ref->{errors},
        req    => $req,
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $output;
        my $ok =
          $Tmpl->process( 'billing/publisher.tmpl', \%tmpl_data, \$output, $r );

        return $class->ok( $r, $output ) if $ok;
        return $class->error( $r, "Template error: " . $Tmpl->error() );

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        ## processing a payment, here we go

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

        my %payment_profile = (
            required => [
                qw( first_name last_name card_type card_number cvv2
                  month year street city zip state email plan )
            ],
            constraint_methods => {
                email       => email(),
                zip         => zip(),
                first_name  => valid_first(),
                last_name   => valid_last(),
                month       => valid_month(),
                year        => valid_year(),
                cvv2        => valid_cvv(),
                city        => valid_city(),
                street      => valid_street(),
                card_type   => cc_type(),
                card_number => cc_number( { fields => ['card_type'] } ),
            }
        );

        $r->log->info("$$ about to validate form");
        my $results = Data::FormValidator->check( $req, \%payment_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            $r->log->error( "results: " . Dumper($results) );

            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->publisher(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        $r->log->info("$$ about to process payment");
        ## process the payment
        my $fname  = $req->param('first_name');
        my $lname  = $req->param('last_name');
        my $street = $req->param('street');
        my $city   = $req->param('city');
        my $state  = $req->param('state');
        my $zip    = $req->param('zip');
        my $email  = $req->param('email');
        my $amount = $req->param('plan');

        my $payment = eval {
            SL::Payment->recurring(
                {
                    description => "Silver Lining Networks Publisher \$$amount/month",
                    email       => $req->param('email'),
                    card_type   => $req->param('card_type'),
                    card_number => $req->param('card_number'),
                    card_exp =>
                      join( '/', $req->param('month'), $req->param('year') ),
                    cvv2       => $req->param('cvv2'),
                    email      => $email,
                    zip        => $zip,
                    first_name => $fname,
                    last_name  => $lname,
                    ip         => $r->connection->remote_ip,
                    street     => $street,
                    city       => $city,
                    state      => $state,
                    referer    => $r->headers_in->{'referer'},
                    amount     => $amount,
                }
            );
        };

        if ($@) {

            # error processing payment
            $r->log->error("payment processing error: $@");
            return Apache2::Const::SERVER_ERROR;
        }

        if ( defined $payment->{error} ) {

            # process errors
            $r->log->info( "$$ got payment error: " . $payment->{error} );

            return $class->publisher(
                $r,
                {
                    errors => { payment => $payment->{error}, },
                    req    => $req,
                }
            );
        }

        # no errors, grab the auth code
        unless ( defined $payment->{auth_code} ) {
            $r->log->error( "payment success but no auth code: "
                  . Data::Dumper::Dumper($payment) );
            return Apache2::Const::SERVER_ERROR;
        }

        my $auth_code = $payment->{auth_code};
        $r->log->info("$$ payment auth code $auth_code processed OK");

        my $mailer    = Mail::Mailer->new('qmail');
        my %mail_args = (
            'To'      => $email,
            'From'    => $From,
            'CC'      => $From,
            'Subject' => "Publisher Recurring Billing Receipt",
        );

        $mailer->open( \%mail_args );

        my $date = DateTime->now->mdy('/');

        my $mail;
        my %tmpl_data = (
            email              => $email,
            fname              => $fname,
            lname              => $lname,
            city               => $city,
            state              => $state,
            street             => $street,
            zip                => $zip,
            authorization_code => $auth_code,
            date               => $date,
            amount             => $amount,
        );

        my $ok =
          $Tmpl->process( 'billing/pub_receipt.tmpl', \%tmpl_data, \$mail, $r );
        return $class->error( $r, $mail ) if !$ok;

        print $mailer $mail;

        if (TEST_MODE) {
            $r->log->error("TEST_MODE ENABLED, email would be '$mail'");
        }
        else {
            $mailer->close;
        }

        $r->log->info("$$ receipt for payment $auth_code: $mail");

        $r->headers_out->set( Location => $Config->sl_app_base_uri
              . "/billing/success?auth_code=$auth_code" );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }
}

sub billing_success {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $output;
    my $ok =
      $Tmpl->process( 'billing/success.tmpl',
        { auth_code => $req->param('auth_code') },
        \$output, $r );

    return $class->ok( $r, $output ) if $ok;
    return $class->error( $r, "Template error: " . $Tmpl->error() );
}

1;

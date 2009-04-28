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
        $r->log->debug( "payment is " . $class->Dumperb($payment) );
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

    $r->log->error( "Notify Query params is " . $class->Dumper( \%query ) );

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
            "could not save Paypal IPN to database: $@\n" . $class->Dumper( \%query ) );
        return Apache2::Const::SERVER_ERROR;
    }

    return Apache2::Const::OK;
}

sub paypal_return {
    my ( $class, $r ) = @_;

    my $req    = Apache2::Request->new($r);
    my %query  = %{ $req->param };
    my $custom = $query{custom} || die "No custom field: " . $class->Dumper( \%query );

    # grab the cookies
    my $jar    = Apache2::Cookie::Jar->new($r);
    my $cookie = $jar->cookies($Cookie_name);

    unless ($cookie) {

        # no cookie is definitely a problem, means the cookie disappeared betwee
        # paypal and us
        $r->log->error(
            "$$ cookie missing for return query " . $class->Dumper( \%query ) );
        return Apache2::Const::NOT_FOUND;
    }

    # decode the cookie
    my %state      = $class->decode( $cookie->value );
    my $session_id = $state{session_id};

    # load the session
    my %session;
    eval {
        tie %session, 'Apache::Session::DB_File', $session_id, \%Sess_opts;
        $r->log->error( "tied session $session_id: " . $class->Dumper( \%session ) )
          if DEBUG;
    };

    if ($@) {
        $r->log->error(
            "session missing id $session_id, args " . $class->Dumper( \%query ) );
        return Apache2::Const::SERVER_ERROR;
    }

    # get the router
    my $router =
      SL::Model::App->resultset('Router')
      ->search( { router_id => $session{router_id} } );

    unless ($router) {
        $r->log->error(
            "router id not found for session " . $class->Dumper( \%session ) );
        return Apache2::Const::SERVER_ERROR;
    }

    my $splash_href = $router->splash_href;
    unless ($splash_href) {
        $r->log->error( "router not configured for CP: " . $class->Dumper($router) );

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
	req => $req,
    );

    my $ok = $Tmpl->process( 'auth/index.tmpl', \%args, \$output, $r );
    $ok
      ? return $class->ok( $r, $output )
      : return $class->error( $r, "Template error: " . $Tmpl->error() );
}

sub valid_aaa_plan {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/(?:one|four|day|month)/ );
        return;
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
    $r->log->debug( "send_cookie for state " . $class->Dumper( \%state ) )
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
    my $ziponly = ($plan eq 'month') ? undef : 1;

    # plan passed on GET
    my %tmpl_data = (
        ziponly => $ziponly,
        errors  => $args_ref->{errors},
        req     => $req,
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

        my @ziponly_req = qw( first_name last_name card_type card_number cvv2
                  month year email plan mac zip );

        my @addr_req = qw( street city state );

        my @req = $ziponly ? ( @ziponly_req ) : ( @ziponly_req, @addr_req );

        my %payment_profile = (
            required => \@req,
            constraint_methods => {
                email       => email(),
                zip         => zip(),
                first_name  => $class->valid_first,
                last_name   => $class->valid_last,
                month       => $class->valid_month,
                year        => $class->valid_year,
                cvv2        => $class->valid_cvv,
                city        => $class->valid_city,
                street      => $class->valid_street,
                card_type   => cc_type(),
                card_number => cc_number( { fields => ['card_type'] } ),
                plan        => valid_aaa_plan(),
                mac         => qr/$RE{net}{MAC}/,
            }
        );

        my $results = Data::FormValidator->check( $req, \%payment_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            $r->log->error( "results: " . $class->Dumper($results) );

            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->paid(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        ## process the payment
        $r->log->debug("$$ about to process payment") if DEBUG;
        my $account = $r->pnotes('router')->account_id;
        my $fname   = $req->param('first_name');
        my $lname   = $req->param('last_name');
        my $zip     = $req->param('zip');
        my $email   = $req->param('email');

        my %payment_args = (
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

                referer    => $r->headers_in->{'referer'},
                ip         => $r->connection->remote_ip,
                plan       => $req->param('plan'),
                            );

        my $payment;
        if ($ziponly) {
          $payment = SL::Payment->process( \%payment_args );

          } else {

            my %addr = (
                street     => $req->param('street'),
                city       => $req->param('city'),
                state      => $req->param('state'), );

            $payment = SL::Payment->recurring({ %payment_args, %addr });
        }

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

        $r->log->debug( "$$ payment auth code "
              . $payment->authorization_code
              . " processed OK" ) if DEBUG;

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
            ziponly            => $ziponly,
            email              => $email,
            fname              => $fname,
            lname              => $lname,
            plan               => $duration,
            network_name       => $network_name,
            authorization_code => $payment->authorization_code,
            date               => $date,
            amount             => $plan_hash->{cost},
        );

        if (!$ziponly) {
            my %addr = (
                street     => $req->param('street'),
                city       => $req->param('city'),
                state      => $req->param('state'), );

            %tmpl_data = ( %tmpl_data, %addr ) if !$ziponly;
        }

        my $ok = $Tmpl->process( 'auth/receipt.tmpl', \%tmpl_data, \$mail, $r );
        return $class->error( $r, $mail ) if !$ok;

        print $mailer $mail;

        $mailer->close unless TEST_MODE;

        $r->log->debug(sprintf("receipt for payment %s: %s",
                               $payment->authorization_code, $mail)) if DEBUG;

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

sub coupon {
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

    return Apache2::Const::SERVER_ERROR
	unless ( $r->method_number == Apache2::Const::M_POST );

    $r->method_number(Apache2::Const::M_GET);

    my $coupon = $req->param('coupon');

    unless ($coupon eq '@1rCl0ud') {

        return $class->paid(
                $r,
                {
                    errors => { invalid => 'coupon' },
                    req    => $req
                }
 
       );
    }

    my $router = $r->pnotes('router');
    unless ($router) {
        $r->log->error('router not set');
        return Apache2::Const::SERVER_ERROR;
    }


        my $lan_ip = $router->lan_ip
          || die 'router not configured for CP';

        ## payment successful, redirect to auth
        $mac  = URI::Escape::uri_escape($mac);
        $dest = URI::Escape::uri_escape($dest);
        $r->headers_out->set(
            Location => "http://$lan_ip/paid?mac=$mac&url=$dest&token=" );
#              . $payment->md5 );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
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


1;

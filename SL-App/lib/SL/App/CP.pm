package SL::App::CP;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT AUTH_REQUIRED
  HTTP_METHOD_NOT_ALLOWED);

use Apache2::Log             ();
use Apache2::SubRequest      ();
use Apache2::Connection      ();
use Apache2::Request         ();
use Apache2::SubRequest      ();
use Apache::Session::DB_File ();

use base 'SL::App';

use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Mail::Mailer     ();
use DateTime         ();
use Business::PayPal ();

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

our $Cookie_name = 'SLN CP';

use SL::Payment                 ();
use SL::App::CookieAuth ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant TEST_MODE => $ENV{SL_TEST_MODE} || 0;

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
        $r->log->debug( "payment is " . $class->Dumper($payment) );
    }

    return Apache2::Const::NOT_FOUND unless $payment;

    my $now = DateTime->now( time_zone => 'local' );
    my $stop = DateTime::Format::Pg->parse_datetime( $payment->stop );
    $stop->set_time_zone('local');

    # see if the payment is expired
    if ( $now > $stop ) {

        $r->log->debug(
            sprintf(
                "auth mac %s expired, now %s, expired %s, payment id %s",
                $mac,                          $now->mdy . ' ' . $now->hms,
                $stop->mdy . ' ' . $stop->hms, $payment->payment_id
            )
        ) if DEBUG;
        return Apache2::Const::AUTH_REQUIRED;
    }

    $r->log->debug(
        sprintf(
            "auth mac %s valid, now %s, expires %s, payment id %s",
            $mac,                          $now->mdy . ' ' . $now->hms,
            $stop->mdy . ' ' . $stop->hms, $payment->payment_id
        )
    ) if DEBUG;

    return Apache2::Const::OK;
}

sub post {
    my ( $class, $r ) = @_;

    my $req      = Apache2::Request->new($r);
    my $dest_url = $req->param('url');
    my $mac      = $req->param('mac');

    my $router = $r->pnotes('router');

    my $location = $class->make_post_url( $router->splash_href, $dest_url );

    $r->log->debug("splash page redir to $location for mac $mac") if DEBUG;
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
        $r->log->error( "could not save IPN: $@" . $class->Dumper( \%query ) );
        return Apache2::Const::SERVER_ERROR;
    }

    return Apache2::Const::OK;
}

sub paypal_return {
    my ( $class, $r ) = @_;

    my $req    = Apache2::Request->new($r);
    my %query  = %{ $req->param };
    my $custom = $query{custom}
      || die "No custom field: " . $class->Dumper( \%query );

    # grab the cookies
    my $jar    = Apache2::Cookie::Jar->new($r);
    my $cookie = $jar->cookies($Cookie_name);

    unless ($cookie) {

        # no cookie is a problem, means the cookie disappeared betwee
        # paypal and us
        $r->log->error( "cookie missing, query " . $class->Dumper( \%query ) );
        return Apache2::Const::NOT_FOUND;
    }

    # decode the cookie
    my %state      = $class->decode( $cookie->value );
    my $session_id = $state{session_id};

    # load the session
    my %session;
    eval {
        tie %session, 'Apache::Session::DB_File', $session_id, \%Sess_opts;
        $r->log->error( "sessid $session_id: " . $class->Dumper( \%session ) )
          if DEBUG;
    };

    if ($@) {
        $r->log->error(
            "no sess, id $session_id, " . $class->Dumper( \%query ) );
        return Apache2::Const::SERVER_ERROR;
    }

    # get the router
    my ($router) =
      SL::Model::App->resultset('Router')
      ->search( { router_id => $session{router_id} } );

    unless ($router) {
        $r->log->error("router id not found, sess id $session_id");
        return Apache2::Const::SERVER_ERROR;
    }

    my $splash_href = $router->splash_href;
    unless ($splash_href) {
        $r->log->error( "router not setup aaa: " . $class->Dumper($router) );

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
    my $expired = $req->param('expired');

    unless ($req->param('mac')) {

        $r->log->error( sprintf("auth page called without mac, ip %s, url %s",
              $r->connection->remote_ip,
              $r->construct_url( $r->unparsed_uri ) ));
        return Apache2::Const::NOT_FOUND;
    }

    my $mac = URI::Escape::uri_unescape($req->param('mac'));
    unless ( SL::App::check_mac($mac) ) {

        $r->log->error( sprintf('auth called with invalid mac %s from ip %s',
              $mac, $r->connection->remote_ip ));
        return Apache2::Const::SERVER_ERROR;
    }

    my $output;
    my $url = URI::Escape::uri_escape($req->param('url'));
    my %args = ( mac => $mac, url => $url, req => $req, );

    $Tmpl->process( 'auth/index.tmpl', \%args, \$output, $r ) ||
        return $class->error( $r, $Tmpl->error );
    return $class->ok( $r, $output )
}

sub token {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);
#    my ($mac, $token ) = map { $req->param($_) } qw( mac token );
    my $mac = $req->param('mac');
    my $token = $req->param('token');

    unless ( $token && $mac ) {
        $r->log->error(sprintf('sub token called w/o token %s, mac %s',
                               $token, $mac ));
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

        $r->log->error(sprintf('missing payment mac %s, token %s, ip %s',
              $mac, $token, $r->connection->remote_ip ));
        return Apache2::Const::NOT_FOUND;
    }

    # check to make sure this payment hasn't already been called
    if ( $payment->token_processed ) {

        $r->log->error( sprintf('dupe attempt for payment %s, ip %s, mac %s',
              $payment->payment_id,
              $r->connection->remote_ip, $mac ));
        return Apache2::Const::NOT_FOUND;
    }

    # check to make sure the payment hasn't expired
    my $stop = DateTime::Format::Pg->parse_datetime( $payment->stop );
    my $now = DateTime->now( time_zone => 'local' );
    if ( $now > $stop ) {

        # payment expired
        $r->log->debug(
            sprintf("expired payment %s, tkn %s, mac %s, ip %s, stop %s %s, now %s", $payment->payment_id, $token, $mac, $r->connection->remote_ip, $stop->mdy, $stop->hms, $now->mdy,$now->hms)) if DEBUG;
        return Apache2::Const::AUTH_REQUIRED;
    }

    # ok the payment looks valid, return ok
    $payment->token_processed(1);
    $payment->update;

    $r->log->debug("token $token, mac $mac VERIFIED") if DEBUG;

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
        -value   => SL::App::CookieAuth->encode( \%state ),
        -expires => '15m',
        -path    => $Config->sl_app_base_uri,
    );

    $cookie->bake($r);

    # they're ok
    $r->log->debug( "cookie state " . $class->Dumper( \%state ) ) if DEBUG;

    return 1;
}

sub paid {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    #my ( $plan, $mac, $dest ) = map { $req->param($_) } ('plan','mac', 'url' );
    my $mac = $req->param('mac');
    my $dest = $req->param('url');
    my $plan = $req->param('plan');

    return Apache2::Const::NOT_FOUND
      unless $plan && SL::App::check_mac( $mac );

    my $router = $r->pnotes('router');
    my $ziponly = ( $plan eq 'month' ) ? undef: 1;


    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $url = $r->construct_url( $r->unparsed_uri );

        my %tmpl_data = (
                         ziponly => $ziponly,
                         errors  => $args_ref->{errors},
                         req     => $req,
                        );

        ######################################
        ## paypal
        my @button_args =
          ( 'test', $url, $router->account_id->name . ' WiFi Purchase', 1 );

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
        $session{account_id} = $router->account_id->account_id;
        $session{mac}        = $mac;
        $session{ip}         = $r->connection->remote_ip;
        $session{custom}     = $id;

        # cookie the user with the id
        $class->send_cookie( $r, $session_id );
        ###############################

        my $output;
        $Tmpl->process( 'auth/paid.tmpl', \%tmpl_data, \$output, $r )
          || return $class->error( $r, $Tmpl->error );
        return $class->ok( $r, $output );

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        my @ziponly_req = qw( first_name last_name card_type card_number cvv2
          month year email plan mac zip );
        my @addr_req = qw( street city state );
        my @req = $ziponly ? (@ziponly_req) : ( @ziponly_req, @addr_req );

        my %payment_profile = (
            required           => \@req,
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
                plan        => $class->valid_aaa_plan,
                mac         => $class->valid_mac,
            }
        );

        my $results = Data::FormValidator->check( $req, \%payment_profile );

        if ( $results->has_missing or $results->has_invalid ) {

            $r->log->debug( $class->Dumper($results) ) if DEBUG;
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
        $r->log->debug("about to process payment") if DEBUG;

        my %payment_args = (
            account_id  => $router->account_id->account_id,
            mac         => $mac,
            email       => $req->param('email'),
            card_type   => $req->param('card_type'),
            card_number => $req->param('card_number'),
            card_exp => join( '/', $req->param('month'), $req->param('year') ),
            cvv2     => $req->param('cvv2'),
            zip      => $req->param('zip'),
            first_name => $req->param('first_name'),
            last_name  => $req->param('last_name'),
            referer    => $r->headers_in->{'referer'},
            ip         => $r->connection->remote_ip,
        );

        my $payment;
        my %addr;
        if ($ziponly) {

            $payment_args{plan} = $plan;
            $payment = eval { SL::Payment->process( \%payment_args ) };
        }
        else {

            %addr = (
                street => $req->param('street'),
                city   => $req->param('city'),
                state  => $req->param('state'),
                amount     => SL::Payment->plan($plan)->{cost},
            );

            $payment =
              eval { SL::Payment->recurring( { %payment_args, %addr } ) };
        }

        if ($@) {

            $r->log->error("Serious payment error:  $@");
            return $class->paid(
                $r,
                {
                    errors => { payment => $SL::App::Tech_error, },
                    req    => $req,
                }
            );
        }
        if ( $payment->error_message ) {

            $r->log->debug( 'err: ' . $payment->error_message ) if DEBUG;
            return $class->paid(
                $r,
                {
                    errors => { payment => $payment->error_message, },
                    req    => $req,
                }
            );
        }

        my $code =
          ( defined $ziponly )
          ? $payment->authorization_code
          : $payment->order_number;

        my $mailer    = Mail::Mailer->new('qmail');
        my %mail_args = (
              'To'      => $req->param('email'),
              'From'    => $SL::App::From,
              'CC'      => $router->account_id->aaa_email_cc,
              'Subject' => "WiFi Internet Receipt",
        );

        $mailer->open( \%mail_args );

        # plan is '4 hours'
        my $plan_hash = SL::Payment->plan($plan);
        my $duration  = join( ' ',
              ( values %{ $plan_hash->{duration} } )[0],
              ( keys %{ $plan_hash->{duration} } )[0] );

        my %tmpl_data = (
              ziponly      => $ziponly,
              req          => $req,
              plan         => $duration,
              network_name => $router->account_id->name,
              code         => $code,
              date         => DateTime->now->mdy('/'),
              amount       => $plan_hash->{cost},
        );

        %tmpl_data = ( %tmpl_data, %addr ) if !$ziponly;

        my $mail;
        $Tmpl->process( 'auth/receipt.tmpl', \%tmpl_data, \$mail, $r )
          || return $class->error( $r, $mail );

        print $mailer $mail;

        if (TEST_MODE) {
              $r->log->error("TEST_MODE ENABLED, email would be \n$mail");
        }
        else {
              $mailer->close;
        }

        $r->log->debug("payment plan $plan ok, redirecting") if DEBUG;
        return $class->auth_dest( $r, 'paid', $router, $mac, $dest, $payment );
    }
}

sub coupon {
      my ( $class, $r, $args_ref ) = @_;

      return Apache2::Const::HTTP_METHOD_NOT_ALLOWED
        unless ( $r->method_number == Apache2::Const::M_POST );
      $r->method_number(Apache2::Const::M_GET);

      my $req = $args_ref->{req} || Apache2::Request->new($r);
#      my ( $mac, $dest ) = map { $req->param($_) } qw( mac url );
      my $mac = $req->param('mac');
      my $dest = $req->param('url');
      my $plan = $req->param('plan');

      return Apache2::Const::NOT_FOUND unless SL::App::check_mac( $mac );

      my $router = $r->pnotes('router');
      my $coupon = $req->param('coupon');

      unless ( $coupon eq '@1rCl0ud' ) {

          return $class->paid(
              $r,
              {
                  errors => { invalid => 'coupon' },
                  req    => $req
              }

          );
      }

      $r->log->debug("coupon payment ok, redirecting") if DEBUG;
      return $class->auth_dest( $r, $router, 'paid', $mac, $dest );
}

sub free {
      my ( $class, $r, $args_ref ) = @_;

      my $req = $args_ref->{req} || Apache2::Request->new($r);
#      my ( $plan, $mac, $dest ) =
#        map { $req->param($_) } qw( plan mac url );

    my $mac = $req->param('mac');
    my $dest = $req->param('url');
    my $plan = $req->param('plan');


      return Apache2::Const::NOT_FOUND
        unless SL::App::check_mac( $mac ) && $plan;

      my $router = $r->pnotes('router');

      my $stop =
        DateTime::Format::Pg->format_datetime(
          DateTime->now( time_zone => 'local' )
            ->add( 'minutes' => $router->timeout ) );

      # make a free payment entry
      my $payment = SL::Model::App->resultset('Payment')->create( {
              account_id => $router->account->account_id,
              mac        => $mac,
              amount     => '$0.00',
              stop       => $stop,
              email      => 'guest',
              last_four  => 0,
              card_type  => 'ads',
              ip         => $r->connection->remote_ip,
              expires    => $router->timeout,
              approved   => 't',
      } );

      $payment->update;

      $r->log->debug("free payment ok, redirecting") if DEBUG;
      return $class->auth_dest( $r, 'ads', $router, $mac, $dest, $payment );
}

sub auth_dest {
      my ( $class, $r, $type, $router, $mac, $dest, $payment ) = @_;

      # grab it for the md5
      ($payment) =
        SL::Model::App->resultset('Payment')->search(
          { payment_id => $payment->payment_id } );

      ## payment successful, redirect to auth
      $mac      = URI::Escape::uri_escape($mac);
      $dest = URI::Escape::uri_escape($dest);

      my $location = sprintf(
              'http://%s/%s?mac=%s&url=%s&token=%s',
              $router->lan_ip, $type, $mac, $dest, $payment->md5
      );
      $r->log->debug("redirecting to $location") if DEBUG;

      $r->headers_out->set( Location => $location );
      $r->no_cache(1);
      return Apache2::Const::REDIRECT;

}

1;

package SL::Apache::App::Billing;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT AUTH_REQUIRED );

use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Connection ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::Apache::App';

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

use SL::Payment                 ();
use SL::Apache::App::CookieAuth ();

use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);

use constant DEBUG     => $ENV{SL_DEBUG} || $ENV{SL_TEST_MODE} || 0;
use constant TEST_MODE => $ENV{SL_TEST_MODE} || 0;

our $Tech_error = 'Technical error, please repeat transaction';
our $From       = 'SLN Support <support@silverliningnetworks.com>';

use SL::Model;
use SL::Model::App;    # don't ask me why we need both

use SL::Config;
our $Config = SL::Config->new;

sub publisher {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    # gotta hava a plan
    my $plan = $req->param('plan');
    unless ($plan) {
        $r->log->error("missing plan");
        return Apache2::Const::NOT_FOUND;
    }

    my %tmpl_data = (
        errors => $args_ref->{errors},
        req    => $req,
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $output;
        $Tmpl->process( 'billing/publisher.tmpl', \%tmpl_data, \$output, $r )
          || return $class->error( $r, $Tmpl->error );

        return $class->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);

        my @free_req = qw( email password retype );
        my @paid_req = qw( first_name last_name card_type card_number cvv2
          month year street city zip state plan );

        my %payment_profile = (
            required =>
              [ ( $plan eq 'free' ) ? @free_req : ( @free_req, @paid_req ) ],
            constraint_methods => {
                password => $class->check_password,
                retype   => $class->check_retype(
                    { fields => [ 'password', 'retype' ] }
                ),
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
            }
        );

        my $results = Data::FormValidator->check( $req, \%payment_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {

            $r->log->debug( $class->Dumper($results) ) if DEBUG;
            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->publisher(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        if ( $req->param('plan') == 'free' ) {
            goto ACCOUNT;
        }

        # if this is a paid account then process the payment
        $r->log->debug("$$ about to process payment") if DEBUG;
        my $fname  = $req->param('first_name');
        my $lname  = $req->param('last_name');
        my $street = $req->param('street');
        my $city   = $req->param('city');
        my $state  = $req->param('state');
        my $zip    = $req->param('zip');
        my $email  = $req->param('email');
        my $amount = $req->param('plan');

        $r->log->debug("making recurring payment") if DEBUG;
        my $payment = eval {
            SL::Payment->recurring(
                {
                    account_id => 1,
                    description =>
                      "Silver Lining Networks Publisher \$$amount/month",
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

            # error processing payment, try again
            $r->log->error( sprintf( "fatal payment error: %s", $@ ) );
            return $class->publisher(
                $r,
                {
                    errors => { payment => $Tech_error, },
                    req    => $req,
                }
            );
        }

        if ( $payment->error_message ) {

            $r->log->error(
                sprintf( "payment error: %s", $payment->error_message ) );

            return $class->publisher(
                $r,
                {
                    errors => { payment => $payment->error_message, },
                    req    => $req,
                }
            );
        }

        $r->log->debug( "receipt #" . $payment->order_number ) if DEBUG;
        my $mailer    = Mail::Mailer->new('qmail');
        my %mail_args = (
            'To'      => $email,
            'From'    => $From,
            'CC'      => $From,
            'Subject' => "Welcome to Silver Lining Networks",
        );

        $mailer->open( \%mail_args );

        my $mail;
        my %tmpl_data = (
            plan         => $plan,
            email        => $email,
            fname        => $fname,
            lname        => $lname,
            city         => $city,
            state        => $state,
            street       => $street,
            zip          => $zip,
            order_number => $payment->order_number,
            date         => DateTime->now->mdy('/'),
            amount       => $amount,
        );

        $Tmpl->process( 'billing/publisher/receipt.tmpl',
            \%tmpl_data, \$mail, $r )
          || return $class->error( $r, $mail );

        print $mailer $mail;

        if (TEST_MODE) {
            $r->log->error("TEST_MODE ENABLED, email would be \n$mail");
        }
        else {
            $mailer->close;
        }

        # create the account
        my $reg;

        ###############################
        # create a session
        my %session;
        tie %session, 'Apache::Session::DB_File', undef,
          \%SL::Apache::App::CookieAuth::SESS_OPTS;
        my $session_id = $session{_session_id};
        $r->pnotes( 'session' => \%session );

        # auth the user and log them in
        SL::Apache::App::CookieAuth->send_cookie( $r, $reg, $session_id );

        $r->headers_out->set( Location => $Config->sl_app_base_uri
              . "/app/home/index?order_number="
              . $payment->order_number );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;

        $r->internal_redirect("/app/home/index");

        return SL::Apache::App::CookieAuth->auth_ok( $r, $reg );
    }

    #        $r->headers_out->set( Location => $Config->sl_app_base_uri
    #              . "/billing/success?auth_code=$auth_code" );
    #        $r->no_cache(1);
    #        return Apache2::Const::REDIRECT;

}

sub advertiser {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    # apache request bug
    my $plan   = $req->param('plan');
    my $coupon = $req->param('coupon');

    # plan passed on GET
    my %tmpl_data = (
        errors => $args_ref->{errors},
        req    => $req,
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $output;
        $Tmpl->process( 'billing/advertiser.tmpl', \%tmpl_data, \$output, $r )
          || return $class->error( $r, $Tmpl->error );
        return $class->ok( $r, $output );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        my %payment_profile = (
            required => [
                qw( first_name last_name card_type card_number cvv2
                  month year street city zip state email plan )
            ],
            constraint_methods => {
                email       => email(),
                zip         => zip(),
                first_name  => $class->valid_first(),
                last_name   => $class->valid_last(),
                month       => $class->valid_month(),
                year        => $class->valid_year(),
                cvv2        => $class->valid_cvv(),
                city        => $class->valid_city(),
                street      => $class->valid_street(),
                card_type   => cc_type(),
                card_number => cc_number( { fields => ['card_type'] } ),
            }
        );

        my $results = Data::FormValidator->check( $req, \%payment_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {

            $r->log->debug( $class->Dumper($results) ) if DEBUG;
            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->advertiser(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        ## process the payment
        my $fname  = $req->param('first_name');
        my $lname  = $req->param('last_name');
        my $street = $req->param('street');
        my $city   = $req->param('city');
        my $state  = $req->param('state');
        my $zip    = $req->param('zip');
        my $email  = $req->param('email');
        my $amount = $req->param('plan');

        my %payment_args = (
            account_id  => 1,
            description => "Silver Lining Networks Advertiser \$$amount/month",
            email       => $req->param('email'),
            card_type   => $req->param('card_type'),
            card_number => $req->param('card_number'),
            card_exp => join( '/', $req->param('month'), $req->param('year') ),
            cvv2     => $req->param('cvv2'),
            email    => $email,
            zip      => $zip,
            first_name => $fname,
            last_name  => $lname,
            ip         => $r->connection->remote_ip,
            street     => $street,
            city       => $city,
            state      => $state,
            referer    => $r->headers_in->{'referer'},
            amount     => $amount,
        );

        if ( $req->param('special') ) {
            $payment_args{special} = $req->param('special');
        }

        $r->log->debug("making recurring payment") if DEBUG;
        my $payment = eval { SL::Payment->recurring( \%payment_args ); };

        if ( $@ or !$payment ) {

            $r->log->error( sprintf("serious payment error for %s:%s"),
                $req->param('emai'), $@ );

            return $class->advertiser(
                $r,
                {
                    errors => { payment => $Tech_error, },
                    req    => $req,
                }
            );
        }

        if ( $payment->error_message ) {

            $r->log->error( sprintf("advertiser %s payment error %s"),
                $req->param('email'), $payment->error_message );

            return $class->advertiser(
                $r,
                {
                    errors => { payment => $payment->error_message, },
                    req    => $req,
                }
            );
        }

        my $mailer    = Mail::Mailer->new('qmail');
        my %mail_args = (
            'To'      => $email,
            'From'    => $From,
            'CC'      => $From,
            'Subject' => "Advertiser Recurring Billing Receipt",
        );

        $mailer->open( \%mail_args );

        my $mail;
        my %tmpl_data = (
            email              => $email,
            fname              => $fname,
            lname              => $lname,
            city               => $city,
            state              => $state,
            street             => $street,
            zip                => $zip,
            order_number       => $payment->order_number,
            date               => DateTime->now->mdy('/'),
            amount             => $amount,
        );

        $Tmpl->process( 'billing/advertiser/receipt.tmpl',
            \%tmpl_data, \$mail, $r )
          || return $class->error( $r, $mail );

        print $mailer $mail;

        if (TEST_MODE) {
            $r->log->error("TEST_MODE ENABLED, email would be \n$mail");
        }
        else {
            $mailer->close;
        }

        $r->headers_out->set( Location => $Config->sl_app_base_uri
              . "/billing/success?auth_code=" . $payment->order_number );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }
}

sub billing_success {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $output;
    $Tmpl->process( 'billing/success.tmpl',
        { auth_code => $req->param('auth_code') },
        \$output, $r )
      || return $class->error( $r, $Tmpl->error );

    return $class->ok( $r, $output );
}

1;

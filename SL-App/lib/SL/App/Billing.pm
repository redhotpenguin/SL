package SL::App::Billing;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST REDIRECT AUTH_REQUIRED );

use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Connection ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use base 'SL::App';

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

use SL::Payment         ();
use SL::App::CookieAuth ();

use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);

use constant DEBUG     => $ENV{SL_DEBUG}     || 0;
use constant TEST_MODE => $ENV{SL_TEST_MODE} || 0;

use SL::Model;
use SL::Model::App;    # don't ask me why we need both

our %Plans = (
    enterprise => '$249.00',
    premium    => '$99.00',
    plus       => '$49.00',
    basic      => '$24.00',
);

use SL::Config;
our $Config = SL::Config->new;

sub publisher {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    # gotta hava a plan
    unless ( $req->param('plan') ) {
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

        $r->method_number(Apache2::Const::M_GET);

        my @free_req = qw( email password retype first_name last_name);
        my @paid_req = qw( card_type card_number cvv2
          month year street city zip state plan );

        my %payment_profile = (
            required => [
                ( $req->param('plan') eq 'free' )
                ? @free_req
                : ( @free_req, @paid_req )
            ],
            constraint_methods => {
                password => [
                    $class->check_password,
                    $class->valid_username(
                        { fields => [ 'email', 'password' ] }
                    )
                ],
                retype => $class->check_retype(
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

        # big conditional is better than goto
        my $payment;
        if ( $req->param('plan') ne 'free' ) {

            $r->log->debug("making recurring payment") if DEBUG;
            my $amount      = $Plans{ $req->param('plan') };
            my $description = sprintf( 'Network Operator % plan, $%/month',
                $req->param('plan'), $amount );

            $payment = eval {
                SL::Payment->recurring(
                    {
                        account_id  => 1,
                        description => $description,
                        email       => $req->param('email'),
                        card_type   => $req->param('card_type'),
                        card_number => $req->param('card_number'),
                        card_exp    => join(
                            '/', $req->param('month'), $req->param('year')
                        ),
                        cvv2       => $req->param('cvv2'),
                        email      => $req->param('email'),
                        zip        => $req->param('zip'),
                        first_name => $req->param('first_name'),
                        last_name  => $req->param('last_name'),
                        ip         => $r->connection->remote_ip,
                        street     => $req->param('street'),
                        city       => $req->param('city'),
                        state      => $req->param('state'),
                        referer    => $r->headers_in->{'referer'},
                        amount     => $amount,
                    }
                );
            };

            if ($@) {

                # error processing payment, try again
                $r->log->error("fatal payment error: $@");
                return $class->publisher(
                    $r,
                    {
                        errors => { payment => $SL::App::Tech_error, },
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

        }

        # send the welcome email / receipt
        my $mailer    = Mail::Mailer->new('qmail');
        my %mail_args = (
            'To'      => $req->param('email'),
            'From'    => $SL::App::From,
            'CC'      => $SL::App::Signup,
            'Subject' => "Welcome to Silver Lining Networks",
        );

        $mailer->open( \%mail_args );

        my $mail;
        my %tmpl_data = (
            req  => $req,
            date => DateTime->now->mdy('/'),
        );

        if ( $req->param('plan') ne 'free' ) {
            $tmpl_data{'amount'}       = $Plans{ $req->param('plan') };
            $tmpl_data{'order_number'} = $payment->order_number;
        }

        $Tmpl->process( 'billing/publisher/receipt.tmpl',
            \%tmpl_data, \$mail, $r )
          || return $class->error( $r, $Tmpl->error );

        print $mailer $mail;

        if (TEST_MODE) {
            $r->log->error("TEST_MODE ENABLED, email would be \n$mail");
        }
        else {
            $mailer->close;
        }

        # look to see if this is an upgrade
        my ($reg) =
          SL::Model::App->resultset('Reg')
          ->search( { email => $req->param('email') } );
        my $account;
        unless ($reg) {

            $r->log->debug(
                sprintf( 'new account for email %s', $req->param('email') ) );

            $reg =
              SL::Model::App->results('Reg')
              ->create( { email => $req->param('email') } );

            $account =
              SL::Model::App->results('Account')
              ->create( { name => $req->param('email') } );

            ## setup defaults and assign id
            $account->update_example_ad_zones;
            $reg->account_id( $account->account_id );
        }
        else {

            $r->log->debug(
                sprintf( 'upgrading account account for email %s',
                    $req->param('email') )
            );

            $account = $reg->account_id;
        }

        $account->plan( $req->param('plan') );
        $reg->first_name( $req->param('first_name') );
        $reg->last_name( $req->param('last_name') );
        $reg->password_md5( Digest::MD5::md5_hex( $req->param('password') ) );

        if ( $req->param('plan') ne 'free' ) {

            $reg->street( $req->param('street') );
            $reg->state( $req->param('state') );
            $reg->city( $req->param('city') );
            $reg->zip( $req->param('zip') );

            $reg->card_type( $req->param('card_type') );
            $reg->card_expires(
                join( '/', $req->param('month'), $req->param('year') ) );
            $reg->card_last_four(
                substr(
                    $req->param('card_number'),
                    length( $req->param('card_number') ) - 4
                )
            );
        }

        $account->update;
        $reg->update;

        ###############################
        # create a session
        my %session;
        tie %session, 'Apache::Session::DB_File', undef,
          \%SL::App::CookieAuth::SESS_OPTS;
        my $session_id = $session{_session_id};
        $r->pnotes( 'session' => \%session );

        # auth the user and log them in
        SL::App::CookieAuth->send_cookie( $r, $reg, $session_id );

        $r->headers_out->set(
            Location => $Config->sl_app_base_uri . "/app/home/index" );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;

        $r->internal_redirect("/app/home/index");

        return SL::App::CookieAuth->auth_ok( $r, $reg );
    }
}

sub advertiser {
    my ( $class, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $plan = $req->param('plan');

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

        my %payment_args = (
            account_id => 1,
            description =>
              sprintf( 'Silver Lining Networks Advertiser $%s/month',
                $req->param('plan') ),
            email       => $req->param('email'),
            card_type   => $req->param('card_type'),
            card_number => $req->param('card_number'),
            card_exp => join( '/', $req->param('month'), $req->param('year') ),
            cvv2     => $req->param('cvv2'),
            email    => $req->param('email'),
            zip      => $req->param('zip'),
            first_name => $req->param('first_name'),
            last_name  => $req->param('last_name'),
            ip         => $r->connection->remote_ip,
            street     => $req->param('street'),
            city       => $req->param('city'),
            state      => $req->param('state'),
            referer    => $r->headers_in->{'referer'},
            amount     => $req->param('plan'),
        );

        if ( $req->param('special') ) {
            $payment_args{special} = $req->param('special');
        }

        $r->log->debug("making recurring payment") if DEBUG;
        my $payment = eval { SL::Payment->recurring( \%payment_args ); };

        if ( $@ or !$payment ) {

            $r->log->error( sprintf("serious payment error for %s:%s"),
                $req->param('email'), $@ );

            return $class->advertiser(
                $r,
                {
                    errors => { payment => $SL::App::Tech_error, },
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
            'To'      => $req->param('email'),
            'From'    => $SL::App::From,
            'CC'      => $SL::App::Signup,
            'Subject' => "Advertiser Recurring Billing Receipt",
        );

        $mailer->open( \%mail_args );

        my $mail;
        my %tmpl_data = (
            email        => $req->param('email'),
            fname        => $req->param('first_name'),
            lname        => $req->param('last_name'),
            city         => $req->param('city'),
            state        => $req->param('state'),
            street       => $req->param('street'),
            zip          => $req->param('zip'),
            order_number => $payment->order_number,
            date         => DateTime->now->mdy('/'),
            amount       => $req->param('plan'),
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
              . "/billing/success?auth_code="
              . $payment->order_number );
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

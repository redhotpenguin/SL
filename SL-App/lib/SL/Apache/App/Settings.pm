package SL::Apache::App::Settings;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET );
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::Upload     ();
use Apache2::ServerUtil ();
use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Digest::MD5 ();

use SL::App::Template ();
use SL::Config        ();
use SL::Model::App    ();
use base 'SL::Apache::App';

our $CONFIG    = SL::Config->new();
our $DATA_ROOT = $CONFIG->sl_data_root;
our $TMPL      = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

require Data::Dumper if DEBUG;

sub dispatch_index {
    my ( $self, $r ) = @_;

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data;
        my $output;

        if ($r->pnotes( $r->user )->root) {
            my @accounts = SL::Model::App->resultset('Account')->all;
            $tmpl_data{accounts} = \@accounts;
        }

        my $ok =
          $TMPL->process( 'settings/index.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
}

sub dispatch_root {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    return $self->error( $r, "Root error for user " . $r->user) unless ($reg->root);

    # this user can proceed
    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $account_id = $req->param('account_id');
    return $self->error( $r, "No account for " . $r->user) unless $account_id;
    $reg->account_id( $account_id );
    $reg->update;

    $r->headers_out->set(
        Location => $r->headers_in->{'Referer'}  );
    return Apache2::Const::REDIRECT;

}


sub dispatch_account {
    my ( $self, $r, $args_ref ) = @_;

    my $req = $args_ref->{req} || Apache2::Request->new($r);
    my $email = $req->param('email');    # libapreq workaround

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            errors => $args_ref->{errors},
            req    => $req,
        );

        my $output;
        my $ok =
          $TMPL->process( 'settings/account.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);

        my %profile = (
            required => [
                qw( password current_email retype email
                  first_name last_name)
            ],
            constraint_methods => {
                email => [
                    email(),
                    not_current_user(
                        { fields => [ 'email', 'current_email' ] },
                    )
                ],
                password => SL::Apache::App::check_password(
                    { fields => [ 'retype', 'password' ] }
                ),
            },
        );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug( "$$ form errors:" . Data::Dumper::Dumper($errors) )
              if DEBUG;

            return $self->dispatch_account(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

    }

    # update the password
    my $reg = $r->pnotes( $r->user );
    $reg->password_md5( Digest::MD5::md5_hex( $req->param('password') ) );

    my $update_cookies;
    if ( $reg->email ne $req->param('email') ) {
        $update_cookies = 1;
    }

    foreach my $param (qw( email first_name last_name )) {
        $reg->$param( $req->param($param) );
    }
    $reg->update;

    if ($update_cookies) {

        # gah I hate this part
        # re-auth the user
        $r->user( $reg->email );
        $r->pnotes( $r->user => $reg );
        SL::Apache::App::CookieAuth->send_cookie( $r, $reg,
            $r->pnotes('session')->{_session_id} );
    }

    $r->pnotes('session')->{msg} = "Account settings have been updated";

    $r->headers_out->set(
        Location => $r->construct_url('/app/settings/index') );
    return Apache2::Const::REDIRECT;
}

sub dispatch_users {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my @users =
      SL::Model::App->resultset('Reg')
      ->search( { account_id => $reg->account_id->account_id } );

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            errors => $args_ref->{errors},
            users  => \@users,
        );

        my $output;
        my $ok =
          $TMPL->process( 'settings/users.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }

}

sub dispatch_paymentfoo {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $email = $req->param('first_name');    # weird libapreq bug

    # look for existing cc info
    my ($cc) =
      SL::Model::App->resultset('Cc')
      ->search( { account_id => $reg->account_id->account_id } );

    my %cc;
    if ($cc) {
        _decode_cc( $cc, \%cc );
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = (
            req    => $req,
            errors => $args_ref->{errors},
            cc     => \%cc,
            ip     => $r->connection->remote_ip,
        );

        my $output;
        my $ok =
          $TMPL->process( 'settings/payment.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);
        my @fields = qw( first_name last_name country
          brand number expires_month expires_year cvv
          address_one city state zipcode email ip check);

        my %profile = (
            required           => \@fields,
            constraint_methods => {
                brand   => cc_type(),
                zipcode => zip(),
                state   => state(),
                number  => cc_number { fields => ['brand'] },
                check   => valid_card( { fields => \@fields }, ),
            },
        );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {

            my $errors = $self->SUPER::_results_to_errors($results);

            $r->log->debug(
                "posting - ERRORS " . Data::Dumper::Dumper($results) )
              if DEBUG;

            return $self->dispatch_payment(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }

        $r->log->debug( "posting - results " . Data::Dumper::Dumper($results) )
          if DEBUG;

        $r->pnotes('session')->{msg} = "Payment settings have been updated";

        $r->headers_out->set(
            Location => $r->construct_url('/app/settings/index') );
        return Apache2::Const::REDIRECT;
    }
}

sub valid_card {
    return sub {
        my $dfv  = shift;
        my $val  = $dfv->get_current_constraint_value;
        my $data = $dfv->get_filtered_data;

        my $paypal = SL::Model::App::Payment->new('sandbox');

        warn( "Running valid card, my paypal object is "
              . Data::Dumper::Dumper($paypal) );

        my %resp = $paypal->{pp}->DoDirectPaymentRequest(
            PaymentAction     => 'Authorization',
            OrderTotal        => 1.00,
            TaxTotal          => 0.0,
            ShippingTotal     => 0.0,
            ItemTotal         => 0.0,
            HandlingTotal     => 0.0,
            CreditCardType    => $data->{brand},
            CreditCardNumber  => $data->{number},
            ExpMonth          => $data->{expires_month},
            ExpYear           => $data->{expires_year},
            CVV2              => $data->{cvv},
            FirstName         => $data->{first_name},
            LastName          => $data->{last_name},
            Street1           => $data->{streetone},
            Street2           => $data->{streettwo},
            CityName          => $data->{city},
            StateOrProvince   => $data->{state},
            PostalCode        => $data->{zip},
            Country           => $data->{country},
            Payer             => $data->{email},
            CurrencyID        => 'USD',
            IPAddress         => $data->{ip},
            MerchantSessionID => 420,
        );

        if ( $resp{Ack} ne 'Success' ) {

            warn(   "paypal request failed:"
                  . Data::Dumper::Dumper( \%resp )
                  . "\n" );
            return;

        }
        else {

            warn(
                "request succeeded: " . Data::Dumper::Dumper( \%resp ) . "\n" );
            return $val;
        }
      }
}

sub not_current_user {
    return sub {
        my $dfv     = shift;
        my $val     = $dfv->get_current_constraint_value;
        my $data    = $dfv->get_filtered_data;
        my $email   = $data->{email};
        my $current = $data->{current_email};

        return $val if ( $email eq $current );    # no change

        my ($reg) =
          SL::Model::App->resultset('Reg')->search( { email => $email } );
        return if $reg;                           # oops duplicate user attempt;

        return $val;
      }
}

sub valid_threshold {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( ( $val =~ m/^\d{1,3}$/ ) && ( $val > 4 ) );
        return;
      }
}

1;

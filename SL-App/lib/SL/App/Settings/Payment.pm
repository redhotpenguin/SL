package SL::App::Settings::Payment;

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
use base 'SL::App';
use Data::Dumper;

our $CONFIG    = SL::Config->new();
our $DATA_ROOT = $CONFIG->sl_data_root;
our $TMPL      = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub dispatch_index {
    my ( $self, $r ) = @_;

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = ( msg => delete $r->pnotes('session')->{msg} );
        my $output;
        $TMPL->process( 'settings/payment/index.tmpl', \%tmpl_data,
                        \$output, $r ) ||
                          return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );

    }
}

sub dispatch_payment {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $email = $req->param('first_name');    # weird libapreq bug

    # look for existing cc info
    my ($cc) =
      SL::Model::App->resultset('Cc')
      ->search( { account_id => $reg->account->account_id } );

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
        $TMPL->process( 'settings/payment.tmpl', \%tmpl_data, \$output, $r ) |
          return $self->error( $r, $TMPL->error );
        return $self->ok( $r, $output );
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

sub valid_threshold {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( ( $val =~ m/^\d{1,3}$/ ) && ( $val > 4 ) );
        return;
      }
}

1;

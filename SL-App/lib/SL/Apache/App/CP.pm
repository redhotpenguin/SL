package SL::Apache::App::CP;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK SERVER_ERROR NOT_FOUND M_GET M_POST);
use Apache2::Log        ();
use Apache2::SubRequest ();
use Apache2::Connection ();
use Apache2::Request    ();
use Apache2::SubRequest ();

use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Regexp::Common          qw( net );

use base 'SL::Apache::App';

use SL::App::Template ();
our $Tmpl = SL::App::Template->template();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

# this specific template logic
use Data::Dumper;
use SL::Model;
use SL::Model::App;    # works for now

sub auth {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $mac = $req->param('mac');
    unless ($mac) {
        $r->log->error( "$$ auth page called without mac from ip "
              . $r->connection->remote_ip . " url: " . $r->construct_url($r->unparsed_uri) );;
        return Apache2::Const::NOT_FOUND;
    }

    unless ($mac  =~ m/$RE{net}{MAC}/) {
        $r->log->error( "$$ auth page called with invalid mac from ip "
              . $r->connection->remote_ip );
        return Apache2::Const::SERVER_ERROR;
    }

    my %tmpl_data = ( mac => $mac );

    my $output;
    my $ok = $Tmpl->process( 'auth/index.tmpl', \%tmpl_data, \$output, $r );
    $ok
      ? return $class->ok( $r, $output )
      : return $class->error( $r, "Template error: " . $Tmpl->error() );
}

sub valid_plan {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/(?:day|month|hour)/ );
        return;
      }
}

sub valid_macaddr {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        # first see if the mac is valid
        # thx regexp::common
        return unless $val =~ m/$RE{net}{MAC}/;

        return $val;
      }
}



sub paid {
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
                qw( first_name last_name card_type card_number cvc
                  month year street city zip state email plan )
            ],
            constraint_methods => {
                mac         => valid_macaddr(),
                email       => email(),
                zip         => zip(),
                card_expiry => cc_exp(),
                card_type   => cc_type(),
                card_number => cc_number( { fields => ['card_type'] } ),
                plan        => valid_plan(),
            }
        );

        my $results = Data::FormValidator->check( $req, \%payment_profile );

        if (DEBUG) {
            require Data::Dumper;
            $r->log->error("results: " . Data::Dumper::Dumper($results));
          }

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $class->SUPER::_results_to_errors($results);
            return $class->paid(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }


        our %Amounts = (
             hour => '$1.99',
             day  => '$3.99',
             month => '$19.99', );

        ## process the payment
        my $payment = SL::Model::App->resultset('Payment')->create({
                            account_=> AIRCLOUD_ACCOUNT_ID,
                            mac     => $req->param('mac'),
                            amount =>  $Amounts{$req->param('plan')},
                            


    #  my $output;
    #  my $ok = $Tmpl->process('auth/paid.tmpl', \%tmpl_data, \$output, $r);
    my $ok = 1;

    my $output = 'yep it worked';
    $ok
      ? return $class->ok( $r, $output )
      : return $class->error( $r, "Template error: " . $Tmpl->error() );

}

1;

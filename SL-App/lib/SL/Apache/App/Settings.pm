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

        my %tmpl_data = ( msg => delete $r->pnotes('session')->{msg} );
        my $output;
        my $ok =
          $TMPL->process( 'settings/index.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
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
            required => [qw( password retype email first_name last_name)],
            constraint_methods => {
                email    => email(),
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

sub dispatch_payment {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my $paypal_id = $req->param('paypal_id');    # weird libapreq bug

    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl_data = ( errors => $args_ref->{errors}, );

        my $output;
        my $ok =
          $TMPL->process( 'settings/payment.tmpl', \%tmpl_data, \$output, $r );

        return $self->ok( $r, $output ) if $ok;
        return $self->error( $r, "Template error: " . $TMPL->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);
        my %profile = (
            required           => [qw( paypal_id payment_threshold )],
            constraint_methods => {
                paypal_id         => email(),
                payment_threshold => valid_threshold(),
            }
        );

        my $results = Data::FormValidator->check( $req, \%profile );

        if ( $results->has_missing or $results->has_invalid ) {

            my $errors = $self->SUPER::_results_to_errors($results);
            $r->log->info(
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

        $reg->paypal_id( $req->param('paypal_id') );
        $reg->payment_threshold( $req->param('payment_threshold') );
        $reg->update;

        my $sess = $r->pnotes('session');
        $sess->{msg} = "Payment settings have been updated";
        $r->pnotes( 'session' => $sess );
        $r->internal_redirect("/app/settings/index");
        return Apache2::Const::OK;
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

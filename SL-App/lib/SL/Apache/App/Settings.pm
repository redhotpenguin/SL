package SL::Apache::App::Settings;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET);
use Apache2::Log        ();
use Apache2::Request    ();
use Apache2::Upload     ();
use Apache2::ServerUtil ();
use Data::FormValidator ();
use Digest::MD5         ();
use SL::Model::App      ();
use Data::Dumper;

use base 'SL::Apache::App';
use SL::Config;
my $CONFIG    = SL::Config->new();
my $DATA_ROOT = $CONFIG->sl_data_root;

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new($r);

    # get all routers for this user
    my @router__regs = $r->pnotes( $r->user )->router__regs;
    my @routers      = map { $_->router_id } @router__regs;

# TODO
#my @routers = $r->pnotes( $r->user )->router__regs->get_column('router_id')->all;
    $r->log->debug( "session: " . Dumper( $r->pnotes('session') ) );

    # see if this ip is currently unregistered;
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            session => $r->pnotes('session'),
            root    => $r->pnotes('root'),
            reg     => $r->pnotes( $r->user ),
            status  => $req->param('status') || '',
        );
        if ( scalar(@routers) > 0 ) {
            $tmpl_data{routers} = \@routers;
        }

        my $output;
        my $ok = $tmpl->process( 'settings/index.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
}

sub dispatch_account {
    my ( $self, $r, $errors ) = @_;
    my $req = Apache2::Request->new($r);

    my %tmpl_data = (
        root             => $r->pnotes('root'),
        reg              => $r->pnotes( $r->user ),
        status           => $req->param('status') || '',
        password_updated => $req->param('password_updated') || '',
    );

    if ( $r->method_number == Apache2::Const::M_GET ) {
        $tmpl_data{'errors'} = $errors if ( keys %{$errors} );

        my $output;
        my $ok =
          $tmpl->process( 'settings/account.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        my %errors;

        $r->method_number(Apache2::Const::M_GET);

        # handle the password if present
        my $path = '?';
        if ( $req->param('password') or $req->param('retype') ) {
            unless ( $req->param('password') eq $req->param('retype') ) {
                $errors{'password'} = '1';
            }
            else {

                # update the password
                $r->pnotes( $r->user )
                  ->password_md5(
                    Digest::MD5::md5_hex( $req->param('password') ) );
                $r->pnotes( $r->user )->update;
                $path .= 'password_updated=1&';
            }
        }

        # handle errors
        if ( keys %errors ) {
            ;
            return $self->dispatch_account( $r, \%errors );
        }

        # handle the email
        if ( $req->param('email')
            && ( $req->param('email') ne $r->pnotes( $r->user )->email ) )
        {
            $r->pnotes( $r->user )->email( $req->param('email') );
            $r->pnotes( $r->user )->update;
            $path .= 'email_updated=1&';
        }

        my $redir = $r->construct_url( $r->uri . "$path" );

        $r->internal_redirect($redir);
        return Apache2::Const::OK;
    }
}

sub dispatch_router {
    my ( $self, $r, $args_ref ) = @_;

    # use an existing request if we have one
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my ( $router, @locations );
    if ( $req->param('id') ) {

        # grab existing router
        ($router) =
          SL::Model::App->resultset('Router')
          ->search( { router_id => $req->param('id'), } );
        return Apache2::Const::NOT_FOUND unless $router;
        my @router__locations = $router->router__locations;
        @locations = map { $_->location_id } @router__locations;
    }

    # GET
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root   => $r->pnotes('root'),
            reg    => $r->pnotes( $r->user ),
            router => $router,
            errors => $args_ref->{errors},
            status => $args_ref->{status},
            req    => $req,
        );
        if ( scalar(@locations) > 0 ) {
            $tmpl_data{locations} = \@locations;
        }
        my $output;
        my $ok =
          $tmpl->process( 'settings/router.tmpl', \%tmpl_data, \$output );

        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # reset method to get for redirect
        $r->method_number(Apache2::Const::M_GET);
        my %router_profile = (
            required           => [qw( name macaddr )],
            constraint_methods => { macaddr => valid_macaddr() }
        );
        my $results = Data::FormValidator->check( $req, \%router_profile );

        # handle form errors
        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);
            return $self->dispatch_router(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }
    if ( not defined $router ) {

        # see if there is a router we don't know about
        ($router) =
          SL::Model::App->resultset('Router')
          ->search( { macaddr => $req->param('macaddr') } );
        unless ($router) {

            # adding a new router
            $router =
              SL::Model::App->resultset('Router')->new( { active => 't' } );
            $router->insert;
            $router->update;
        }

        # see if a router reg exists
        my %router__reg_args = (
            reg_id    => $r->pnotes( $r->user )->reg_id,
            router_id => $router->router_id,
        );
        my ($router__reg) =
          SL::Model::App->resultset('RouterReg')->search( \%router__reg_args );

        unless ($router__reg) {

            # nothing so make a new one
            $router__reg =
              SL::Model::App->resultset('RouterReg')->new( \%router__reg_args );
        }
        $router__reg->insert;
        $router__reg->update;
    }

    # no errors update the router
    foreach my $param qw( name macaddr serial_number ) {
        $router->$param( $req->param($param) );
    }
    $router->update;

    # set session msg
    $r->pnotes('session')->{msg} =
      sprintf( "Router '%s' has been updated", $req->param('name') );

    $r->internal_redirect( $CONFIG->sl_app_base_uri . "/app/settings/index" );
    return Apache2::Const::OK;
}

sub valid_macaddr {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        return $val if ( $val =~ m/^([0-9a-f]{2}([:-]|$)){6}$/i );
        return;
      }
}

1;

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
our $SCHEMA = SL::Model::App->schema;

use base 'SL::Apache::App';
use SL::Config;
my $config    = SL::Config->new();
my $DATA_ROOT = $config->sl_data_root;

use SL::App::Template ();
our $tmpl = SL::App::Template->template();

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $req     = Apache2::Request->new($r);
    # get all routers for this user

   my @router__regs = $r->pnotes( $r->user )->router__regs;
   my @routers = map { $_->router_id } @router__regs;

   # TODO
   #my @routers = $r->pnotes( $r->user )->router__regs->get_column('router_id')->all;


    # see if this ip is currently unregistered;
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root    => $r->pnotes('root'),
            reg     => $r->pnotes( $r->user ),
            status  => $req->param('status') || '',
        );
        if (scalar(@routers) > 0 ) {
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
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new( $r, TEMP_DIR => '/tmp' );

    my ($router, @locations);
    if ($req->param('id') == -1) {
      # adding a new router
      $router = SL::Model::App->resultset('Router')->new( 
          { ip => $r->connection->remote_ip, 
            reg_id => $r->pnotes($r->user)->reg_id, });
      $router->insert;
      $router->update;
    } elsif ($req->param('id')) {

      # using existing router
      ($router) = $SCHEMA->resultset('Router')->search({
            router_id => $req->param('id'),
        });
      my @router__locations = $router->router__locations;
      @locations = map { $_->location_id } @router__locations;
    }
    return Apache2::Const::NOT_FOUND unless $router;

    # grab the locations where this router has been 

    my $status;
    # GET
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root         => $r->pnotes('root'),
            reg          => $r->pnotes( $r->user ),
            status       => $req->param('status') || '',
            updated_name => $req->param('updated_name') || '',
            router       => $router,
        );
        if (scalar(@locations) > 0) {
          $tmpl_data{locations} = \@locations;
        }

        my $output;
        my $ok =
          $tmpl->process( 'settings/router.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }   elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        my $updated_name;
        if ( $req->param('name') && ( $req->param('name') ne $router->name ) ) {
            $router->name( $req->param('name') );
            $router->update;
            $updated_name = 'ok';
        }
        my $uri = '?';

        if ($updated_name) {
            $uri .= "updated_name=$updated_name&";
        }
        $uri .= "id=" . $router->router_id;
        $r->log->error("URI is $uri");
        $r->internal_redirect( $r->construct_url( $r->uri . $uri ) );
        return Apache2::Const::OK;
    }
}

1;

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

sub dispatch_friends {
    my ( $self, $r, $args_ref ) = @_;

    my $reg = $r->pnotes( $r->user );
    my $req = $args_ref->{req} || Apache2::Request->new($r);

    my @friends = $reg->friends;

    my $friend = $req->param('friend'); # weird libapreq bug
    # see if this ip is currently unregistered;
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            session => $r->pnotes('session'),
            root    => $r->pnotes('root'),
            friends => \@friends,
            reg     => $reg,
            errors  => $args_ref->{errors},
            user  => $friend,
        );

        my $output;
        my $ok =
          $tmpl->process( 'settings/friends.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        $r->method_number(Apache2::Const::M_GET);
        my %friend_profile = (
            required           => [qw( friend )],
            constraint_methods => { friend => valid_friend() }
        );
$r->log->debug("AAAAA " . $req->param('friend') );
        my $results = Data::FormValidator->check( $req, \%friend_profile );

        if ( $results->has_missing or $results->has_invalid ) {
            my $errors = $self->SUPER::_results_to_errors($results);
            return $self->dispatch_friends(
                $r,
                {
                    errors => $errors,
                    req    => $req
                }
            );
        }
    }

    # create the relationship
    my ($friend_obj) = SL::Model::App->resultset('Reg')->search({
          email => $req->param('friend') });
    my ($reg__reg) =
      SL::Model::App->resultset('RegReg')
      ->create( { first_reg_id => $friend_obj->reg_id,
                  sec_reg_id => $reg->reg_id } );

    # done with argument processing
    $r->pnotes('session')->{msg} =
      sprintf( "User %s was added to your list", $req->param('friend') );
    $r->internal_redirect("/app/settings/friends");
    return Apache2::Const::OK;
}

sub valid_friend {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        my ($is_friend) =
          SL::Model::App->resultset('Reg')->search( { email => $val } );

        return $val if $is_friend;
        return;
      }
}

1;

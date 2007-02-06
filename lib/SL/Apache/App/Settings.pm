package SL::Apache::App::Settings;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK M_POST M_GET);
use Apache2::Log     ();
use Apache2::Request ();
use Apache2::Upload  ();
use Data::FormValidator ();
use Digest::MD5  ();

use base 'SL::Apache::App';
use SL::Config;
my $config    = SL::Config->new();
my $DATA_ROOT = $config->sl_data_root;

use Template;
my %tmpl_config = ( INCLUDE_PATH => $config->tmpl_root . '/app' );
my $tmpl = Template->new( \%tmpl_config ) || $Template::ERROR;

sub dispatch_index {
    my ( $self, $r ) = @_;

    my $req     = Apache2::Request->new($r);
    my @routers =
      SL::Model::App->resultset('Router')
      ->search( { reg_id => $r->pnotes( $r->user )->reg_id } );
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root    => $r->pnotes('root'),
            reg     => $r->pnotes( $r->user ),
            status  => $req->param('status') || '',
            routers => \@routers
        );
        my $output;
        my $ok = $tmpl->process( 'settings/index.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );

    }
}

sub dispatch_account {
  my ($self, $r, $errors ) = @_;
  my $req = Apache2::Request->new($r);
 $r->log->error("IN !");
       my %tmpl_data = (
            root   => $r->pnotes('root'),
            reg    => $r->pnotes( $r->user ),
            status => $req->param('status') || '',
            password_updated => $req->param('password_updated') || '',
        );

  if ( $r->method_number == Apache2::Const::M_GET ) {
    $tmpl_data{'errors'} = $errors  if ( keys %{$errors} );

  my $output;
  my $ok = $tmpl->process( 'settings/account.tmpl', \%tmpl_data, \$output );
  $ok ?
    return $self->ok($r, $output )
  : return $self->error($r, "Template error: " . $tmpl->error );
  }
  elsif ($r->method_number == Apache2::Const::M_POST) {
     my %errors;
    
       $r->method_number(Apache2::Const::M_GET);
     # handle the password if present
     my $path = '?';
       if ($req->param('password') or $req->param('retype')) {
         unless ($req->param('password') eq $req->param('retype')) {
           $errors{'password'} = '1';
         } else {
         # update the password
         $r->pnotes($r->user)->password_md5(
             Digest::MD5::md5_hex($req->param('password')));
         $r->pnotes($r->user)->update;
         $path .= 'password_updated=1&';
       }
       }
     # handle errors
     if (keys %errors) {;
       return $self->dispatch_account($r, \%errors);
     }
       # handle the email
       if ($req->param('email') 
           && ($req->param('email') ne $r->pnotes($r->user)->email)) {
         $r->pnotes($r->user)->email($req->param('email'));
         $r->pnotes($r->user)->update;
         $path .= 'email_updated=1&';
       }

     my $redir = $r->construct_url( $r->uri . "$path");
     $r->log->error("REDIR is $redir");
      $r->internal_redirect($redir);
        return Apache2::Const::OK;
  }
}

sub dispatch_router {
    my ( $self, $r ) = @_;

    my $req = Apache2::Request->new( $r, TEMP_DIR => '/tmp' );
    my ($router) = SL::Model::App->resultset('Router')->search(
        {
            router_id => $req->param('id'),
            reg_id    => $r->pnotes( $r->user )->reg_id,
        }
    );

    return Apache2::Const::NOT_FOUND unless $router;

    my $subdir = $r->pnotes( $r->user )->reg_id . "/" . $router->ip . "/img";
    my $dir    = "$DATA_ROOT/$subdir";
    unless ( -d $dir ) {
        ( system("mkdir -p $dir") == 0 ) or die "DIR IS $dir " . $!;
    }
    my %img = ( file => "$dir/logo.gif", link => "/img/user/$subdir/logo.gif" );
    unless ( -e $img{'file'} ) {
        $img{'link'} =
          'http://www.redhotpenguin.com/images/sl/free_wireless.gif';
    }

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root   => $r->pnotes('root'),
            reg    => $r->pnotes( $r->user ),
            status => $req->param('status') || '',
            router => $router,
            file   => $img{'link'}
        );

        my $output;
        my $ok =
          $tmpl->process( 'settings/router.tmpl', \%tmpl_data, \$output );
        $ok
          ? return $self->ok( $r, $output )
          : return $self->error( $r, "Template error: " . $tmpl->error() );
    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        my $status;
        $r->method_number(Apache2::Const::M_GET);
        my $upload = $req->upload('bug');
        if ($upload) {

            # save the file
            if ( -e $img{'file'} ) {
                unlink $img{'file'} or die "Could not unlink $img{'file'}, $!";
            }
            $upload->link( $img{'file'} )
              or die "Could not link $img{'file'}, $!";

            # are you my type?
            my $type = `file -b $img{'file'}`;
            my ( $exact_type, $width, $height ) =
              $type =~
m/^Image type is (\w+) image data, version (?:\d+\w+), (\d+) x (\d+)/;
            unless ( $exact_type eq 'GIF' ) {
                $status = 'not_gif';
            }
            elsif ( ( $width > 100 ) or ( $height > 50 ) ) {
                $status = 'not_sized';
            }
            else {
                $status = 'ok';
                $r->log->error(
                    "type: $exact_type, height: $height, width: $width");
            }
        }

        if ( $req->param('name') ) {
            $router->name( $req->param('name') );
            $router->update;
            $status = 'ok';
        }

        $r->internal_redirect(
            $r->construct_url(
                $r->uri . "?status=$status&id=" . $router->router_id
            )
        );
        return Apache2::Const::OK;
    }
}

1;

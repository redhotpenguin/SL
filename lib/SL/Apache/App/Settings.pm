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
    my $status;

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my %tmpl_data = (
            root   => $r->pnotes('root'),
            reg    => $r->pnotes( $r->user ),
            status => $req->param('status') || '',
			updated_name => $req->param('updated_name') || '',
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
        $r->method_number(Apache2::Const::M_GET);
        my $upload = $req->upload('bug');
        if ($upload) {

            # save the file
            if ( -e $img{'file'} ) {
                unlink $img{'file'} or die "Could not unlink $img{'file'}, $!";
            }
            my $new = $img{'file'} . '.new';
			unlink ($new) if -e $new;
			$upload->link( $new) or die "Could not link $img{'file'}, $!";

			my $convert = `convert -sample 100 x 50 $new $img{'file'}`;
			$r->log->error("Log of convert: $convert");
			## are you my type?
			#my $type = `file -b $img{'file'}`;
			#if ( $type !~ m/GIF/ ) {
			#		$r->log->error("NOT A GIF - $type");
			#    $status = 'not_gif';
			#    unlink $img{'file'} or die "Could not unlink $img{'file'}, $!";
			# } else {
            # it's a gif at least
			# my ( $exact_type, $width, $height ) = $type =~
			# m/(\w+) image data, version (?:\d+\w+), (\d+) x (\d+)/;
		#m/^Image type is (\w+) image data, version (?:\d+\w+), (\d+) x (\d+)/;
		#$r->log->error("Type is $exact_type, wid $width, h $height"); 
                # is it the right size?
				#       if ( ( $width > 100 ) or ( $height > 50 ) ) {
				#		$status = 'not_sized';
				#		unlink $img{'file'} or die "Could not unlink $img{'file'}, $!";
				# }
				#else {
				$status = 'ok';
				#$r->log->error(
				#    "type: $exact_type, height: $height, width: $width");
				#}
            }
			# }

		my $updated_name;
        if ( $req->param('name') && ($req->param('name') ne $router->name) ) {
            $router->name( $req->param('name') );
            $router->update;
			$updated_name = 'ok';
        }
		my $uri = '?';
		if ($status) {
			$uri .= "status=$status&";
		}
		if ($updated_name) {
			$uri .= "updated_name=$updated_name&";
		}
		$uri .= "id=" . $router->router_id;
		$r->log->error("URI is $uri");
        $r->internal_redirect(
			$r->construct_url($r->uri . $uri)
        );
        return Apache2::Const::OK;
    }
}

1;

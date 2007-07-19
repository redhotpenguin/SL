package SL::Apache::App::CookieAuth;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw( OK FORBIDDEN REDIRECT M_POST M_GET HTTP_METHOD_NOT_ALLOWED);
use Apache2::Log    ();
use Apache2::Cookie ();
use Apache2::URI    ();

use base 'SL::Apache::App';
use SL::Model::App ();

use Digest::MD5 ();
use MIME::Lite  ();

our $CONFIG;
my ( $CIPHER, $TEMPLATE );

BEGIN {
    require SL::Config;
    $CONFIG = SL::Config->new();

    require Crypt::CBC;
    $CIPHER = Crypt::CBC->new(
        -key    => $CONFIG->sl_app_auth_secret,
        -cipher => 'Blowfish',
    );

}

use SL::App::Template ();
our $TEMPLATE = SL::App::Template->template();

sub authenticate {
    my ( $class, $r ) = @_;

    # subrequests ok
    unless ( $r->is_initial_req ) {
        # FIXME - abstract this out to match auth_ok
        $r->user($r->prev->user);
        $r->pnotes($r->user => $r->prev->pnotes($r->prev->user));
        if ($r->prev->pnotes('root')) {
            $r->pnotes('root' => 1);
        }
        return Apache2::Const::OK;
    }

    # grab the cookies
    my $jar    = Apache2::Cookie::Jar->new($r);
    my $cookie = $jar->cookies( $CONFIG->sl_app_cookie_name );

    my $dest = $r->construct_url( $CONFIG->sl_app_auth_uri );
    return $class->redirect_auth( $r, 'No Cookie', $dest ) unless ($cookie);

    # decode the cookie
    my %state = $class->decode( $cookie->value );

    # check for malformed cookie
    unless ( grep { exists $state{$_} } qw(email last_seen) ) {
        return $class->redirect_auth( $r, 'Malformed Cookie', $dest );
    }

    # grab the reg object - redirect if not present
    my ($reg) =
      SL::Model::App->resultset('Reg')->search( { email => $state{email} } );
    unless ($reg) {
        $r->log->error( "Warning - cookie processed for nonexistent reg email "
              . $state{email} );
        return $class->redirect_auth( $r,
            "Nonexistent reg email " . $state{email}, $dest );
    }

	# give them a cookie
	$class->send_cookie($r, $reg);

    return $class->auth_ok( $r, $reg );
}

sub login {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my $output;
        my $ok =
          $TEMPLATE->process( 'login.tmpl', 
         { status => $req->param('status') || '',
           error => $req->param('error') || '' },
            \$output );

        $ok
          ? return $class->ok( $r, $output )
          : return $class->ok( $r,
            "Template error: " . $TEMPLATE->error() );
    }

    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # check for both username and password present
        unless ( $req->param('email') && $req->param('password') ) {
            my $dest =
              $r->construct_url(
                $CONFIG->sl_app_auth_uri . '/?error=incomplete' );
            return $class->redirect_auth( $r, "username, password missing",
                $dest );
        }

        # grab the reg object from the database
        my ($reg) = SL::Model::App->resultset('Reg')->search(
            {
                email    => $req->param('email'),
                password_md5 => Digest::MD5::md5_hex( $req->param('password') )
            }
        );

        # send them back to the login page if pass is invalid
        unless ($reg) {
            my $dest =
              $r->construct_url( $CONFIG->sl_app_auth_uri . '/?error=invalid' );
            return $class->redirect_auth( $r, "username, password missing",
                $dest );
        }

		# give them a cookie
		$class->send_cookie($r, $reg);

        # they're ok
        return $class->redirect_auth( $r, 'successful auth', $r->construct_url('/app') );
    }
    else {
        return Apache2::Const::HTTP_METHOD_NOT_ALLOWED;
    }
}

sub send_cookie {
	my ($class, $r, $reg) = @_;

    # Give the user a new cookie
    my $last_seen = DateTime->now( time_zone => 'local' )->epoch;
    my %state = (
        email     => $reg->email,
        last_seen => $last_seen,
    );
    my $cookie = Apache2::Cookie->new(
        $r,
        -name  => $CONFIG->sl_app_cookie_name,
        -value => $class->encode( \%state ),
        -expires => '14D',
    );

    $cookie->bake($r);

	# they're ok
	$r->log->debug( "$class user "
          . $state{email}
          . ", last seen "
          . $state{last_seen}
          . ", authenticated ok, cookie sent" );
 
	return 1;
}


sub auth_ok {
    my ( $class, $r, $reg ) = @_;

	# setup the request auth blabla
    $r->user( $reg->email );
    $r->pnotes( $r->user => $reg );

	# Check to see if they are a root user
	my ($root) = SL::Model::App->resultset('Root')->search({ 
		reg_id => $reg->reg_id });
	if ($root) {
		$r->pnotes('root' => $root->root_id);
	}
	return Apache2::Const::OK; 
}

sub encode {
    my ( $class, $state_hashref ) = @_;
    my $joined = join( ':',  map { join(':', $_, $state_hashref->{$_}) } keys %{$state_hashref});
    return $CIPHER->encrypt($joined);
}

sub decode {
    my ( $class, $val ) = @_;
    my $decrypted = $CIPHER->decrypt($val);
    return split( ':', $decrypted );
}

sub redirect_auth {
    my ( $class, $r, $reason, $dest ) = @_;

    $r->log->debug( $class . " redirecting to $dest, reason '$reason'" );
    $r->headers_out->set( Location => $dest );
    return Apache2::Const::REDIRECT;
}

sub forgot {
    my ($class, $r) = @_;

    my $req = Apache2::Request->new($r);

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my $output;
        my $ok =
          $TEMPLATE->process( 'forgot.tmpl', 
                              { status => $req->param('status') || '',
                                email  => $req->param('email') }, \$output );

        $ok
          ? return $class->ok( $r, $output )
          : return $class->ok( $r,
            "Template error: " . $TEMPLATE->error() );

    } elsif ($r->method_number == Apache2::Const::M_POST ) {
      $r->log->debug("POSTING...");
        my $email;
        unless ($email = $req->param('email')) {
          # missing email
          $r->method_number(Apache2::Const::M_GET);
          $r->internal_redirect('/forgot/?status=blank');
          return Apache2::Const::OK;
        }

        my ($reg) = SL::Model::App->resultset('Reg')->search({
          email => $email });
        
        unless ($reg) {
          # bad email address
          $r->method_number(Apache2::Const::M_GET);
          $r->internal_redirect('/forgot/?status=notfound&email=' . 
                                $req->param('email'));

        } else {
        
           # we have a valid email, setup forgot password link
           my $forgot = SL::Model::App->resultset('Forgot')->new({ 
                reg_id => $reg->reg_id});
           $forgot->insert;
           $forgot->update;
           $forgot->discard_changes;
           my $output;
           my $url = $r->construct_url('/forgot/reset/?key=' . 
                                       $forgot->link_md5());

           my $ok = $TEMPLATE->process( 'forgot_email.tmpl', 
                              { url => $url, email => $reg->email }, \$output );
          
           my $msg = MIME::Lite->new(
               From => "SilverLining <support\@silverliningnetworks.com>",
               To   => $reg->email,
               Subject => "Your password reset request",
               Data => $output,
           );

           $msg->send;
		   #$msg->send_by_smtp('www.redhotpenguin.com');
           $r->method_number(Apache2::Const::M_GET);
           $r->internal_redirect("/forgot/?status=sent&email=$email");
        }
       return Apache2::Const::OK;
      }
}

sub forgot_reset {
    my ($class, $r) = @_;

    my $req = Apache2::Request->new($r);

    return Apache2::Const::SERVER_ERROR unless $req->param('key');

    my ($forgot) = SL::Model::App->resultset('Forgot')->search({ 
         link_md5 => $req->param('key'), expired => 'f' });
    return Apache2::Const::NOT_FOUND unless $forgot;

    if ($r->method_number == Apache2::Const::M_GET) {

       # found the link, serve the reset password page
       my $output;
       my $url = $r->construct_url('/forgot/reset/?key=' . 
                                   $forgot->link_md5());

       my $ok = $TEMPLATE->process( 'forgot_reset.tmpl', 
              { key => $req->param('key'), 
                error => $req->param('error') || '' }, \$output );

       $ok
          ? return $class->ok( $r, $output )
          : return $class->ok( $r,
            "Template error: " . $TEMPLATE->error() );
       
    } elsif ($r->method_number == Apache2::Const::M_POST) {
      unless (($req->param('password') && $req->param('retype')) &&
              ($req->param('password') eq $req->param('retype'))) {
         $r->method_number(Apache2::Const::M_GET);
         $r->internal_redirect('/forgot/reset/?error=mismatch&key=' . 
                               $req->param('key'));
         return Apache2::Const::OK;
       }

      # update the password
      my $reg = $forgot->reg_id;
      $reg->password_md5(Digest::MD5::md5_hex($req->param('password')));
      $reg->update;

      # expire the link
      $forgot->expired(1);
      $forgot->update;

      # send to the login page
      $r->method_number(Apache2::Const::M_GET);
      $r->internal_redirect('/login/?status=password_updated');
      return Apache2::Const::OK;
    }
}

1;

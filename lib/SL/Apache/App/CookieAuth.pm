package SL::Apache::App::CookieAuth;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw( OK FORBIDDEN REDIRECT M_POST M_GET HTTP_METHOD_NOT_ALLOWED);
use Apache2::Log    ();
use Apache2::Cookie ();
use Apache2::URI    ();

use SL::Apache::App ();
use SL::Model::App ();

use Digest::MD5 ();

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

    require Template;
    my %tmpl_config = ( INCLUDE_PATH => $CONFIG->tmpl_root . '/app' );
    $TEMPLATE = Template->new( \%tmpl_config ) || die $Template::ERROR;
}

sub authenticate {
    my ( $class, $r ) = @_;

    # subrequests ok
    return Apache2::Const::OK unless ( $r->is_initial_req );

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
          $TEMPLATE->process( 'login.tmpl', { error => $req->param('error') || '' },
            \$output );

        $ok
          ? return SL::Apache::App::ok( $r, $output )
          : return SL::Apache::App::error( $r,
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

1;
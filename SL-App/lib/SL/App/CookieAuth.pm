package SL::App::CookieAuth;

use strict;
use warnings;

use Apache2::Const -compile =>
  qw( OK FORBIDDEN REDIRECT M_POST M_GET HTTP_METHOD_NOT_ALLOWED);
use Apache2::Log        ();
use Apache2::Cookie     ();
use Apache2::URI        ();
use Apache2::Request    ();
use Data::FormValidator ();
use Data::FormValidator::Constraints qw(:closures);
use Mail::Mailer;
use Digest::MD5              ();
use MIME::Lite               ();
use Apache::Session::DB_File ();
use Data::Dumper;

use base 'SL::App';
use SL::Model::App    ();
use SL::App::Template ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $Template = SL::App::Template->template();

our ( $Config, $CIPHER, %SESS_OPTS );

BEGIN {
    require SL::Config;
    $Config = SL::Config->new();

    require Crypt::CBC;
    $CIPHER = Crypt::CBC->new(
        -key    => $Config->sl_app_auth_secret,
        -cipher => 'Blowfish',
    );

    # session
    unless ( -d $Config->sl_app_session_dir ) {
        system( 'mkdir -p ' . $Config->sl_app_session_dir ) == 0 or die $!;
    }

    %SESS_OPTS = (
        FileName => join( '/',
            $Config->sl_app_session_dir, $Config->sl_app_session_lock_file ),
        LockDirectory => $Config->sl_app_session_dir,
        Transaction   => 1,
    );
}

sub authenticate {
    my ( $class, $r ) = @_;

    $r->log->debug("$$ authenticating") if DEBUG;

    # subrequests ok
    unless ( $r->is_initial_req ) {

        $r->log->debug("handling authenticate subrequest") if DEBUG;

        # FIXME - abstract this out to match auth_ok
        $r->user( $r->prev->user );
        $r->pnotes( $r->user => $r->prev->pnotes( $r->prev->user ) );

        # pass the session from the subrequest
        if ( $r->prev->pnotes('session') ) {

            $r->log->debug( "subrequest previous session "
                  . Dumper( $r->prev->pnotes('session') ) )
              if DEBUG;
            $r->pnotes( 'session' => $r->prev->pnotes('session') );
        }
        return Apache2::Const::OK;
    }

    # grab the cookies
    my $jar    = Apache2::Cookie::Jar->new($r);
    my $cookie = $jar->cookies( $Config->sl_app_cookie_name );
    my $dest   = $r->construct_url( $Config->sl_app_auth_uri );

    # user doesn't have a cookie?
    unless ($cookie) {
        $dest .= "/?dest=" . $r->unparsed_uri;

        # replace /login with /home
        if ( substr($dest, length($dest)-5, length($dest)) ) {

            substr($dest, length($dest)-5, length($dest), 'home/index');
        }

        $r->log->debug("$$ redirecting to $dest, no cookie present") if DEBUG;
        return $class->redirect_auth( $r, 'No Cookie', $dest );
    }

    # decode the cookie
    my %state = $class->decode( $cookie->value );

    $r->log->debug( "state extracted from cookie: " . Dumper( \%state ) )
      if DEBUG;

    # check for malformed cookie
    unless ( grep { exists $state{$_} } qw(email last_seen) ) {
        $r->log->error(
            sprintf(
                "malformed cookie seen, ua %s, url %s",
                $r->headers_in->{'user-agent'},
                $r->construct_url( $r->unparsed_uri )
            )
        );
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

    my %session;
    my $session_id = $state{session_id} || undef;

    if ($session_id) {
        $r->log->debug("$$ found session id $session_id") if DEBUG;

        # load the session
        eval {
            tie %session, 'Apache::Session::DB_File', $session_id, \%SESS_OPTS;
            $r->log->debug( "tied session id " . $session{_session_id} )
              if DEBUG;
        };

        if ($@) {
            $r->log->error( "session missing for " . $reg->email . " $@" );

            # try to make a new session
            eval {
                tie %session, 'Apache::Session::DB_File', undef, \%SESS_OPTS;
            };

            $r->log->error("WOW SOMETHING REALLY BAD HAPPENED: $@") if $@;
            return Apache2::Const::SERVER_ERROR;
        }
    }
    else {

        # make a new session
        tie %session, 'Apache::Session::DB_File', undef, \%SESS_OPTS;
        $r->log->debug( "new sess id " . $session{_session_id} ) if DEBUG;
    }

    $session_id = $session{_session_id};

    $r->pnotes( session => \%session );

    # give them a cookie
    $class->send_cookie( $r, $reg, $session_id );

    return $class->auth_ok( $r, $reg );
}

sub logout {
    my ( $class, $r ) = @_;

    $class->expire_cookie($r);

    $r->headers_out->set( Location => 'http://www.silverliningnetworks.com/' );
    return Apache2::Const::REDIRECT;
}

sub login {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    if ( $r->method_number == Apache2::Const::M_GET ) {
        my $output;
        $Template->process(
            'login.tmpl',
            {
                status => $req->param('status') || '',
                error  => $req->param('error')  || '',
                dest   => $req->param('dest')   || ''
            },
            \$output,
            $r
        ) || return $class->error( $r, $Template->error );

        return $class->ok( $r, $output );
    }

    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        # check for both username and password present
        unless ( $req->param('email') && $req->param('password') ) {
            my $dest =
              $r->construct_url(
                $Config->sl_app_auth_uri . '/?error=incomplete' );
            return $class->redirect_auth( $r, "username, password missing",
                $dest );
        }

        # grab the reg object from the database
        my ($reg) = SL::Model::App->resultset('Reg')->search(
            {
                email        => $req->param('email'),
                password_md5 => Digest::MD5::md5_hex( $req->param('password') )
            }
        );

        # send them back to the login page if pass is invalid
        unless ($reg) {
            my $dest =
              $r->construct_url( $Config->sl_app_auth_uri . '/?error=invalid' );
            return $class->redirect_auth( $r, "username, password missing",
                $dest );
        }

        # create a session
        my %session;
        tie %session, 'Apache::Session::DB_File', undef, \%SESS_OPTS;
        my $session_id = $session{_session_id};
        $r->pnotes( 'session' => \%session );

        # give them a cookie
        $class->send_cookie( $r, $reg, $session_id );

        # they're ok
        my $destination = $req->param('dest') || '/app/home/index';
        $r->log->debug("login ok, redirecting to $destination") if DEBUG;
        return $class->redirect_auth(
            $r,
            'successful auth',
            $r->construct_url($destination)
        );
    }
    else {
        return Apache2::Const::HTTP_METHOD_NOT_ALLOWED;
    }
}

sub expire_cookie {
    my ( $class, $r ) = @_;

    my $cookie = Apache2::Cookie->new(
        $r,
        -name    => $Config->sl_app_cookie_name,
        -value   => '',
        -expires => 'Mon, 21-May-1971 00:00:00 GMT',
        -path    => $Config->sl_app_base_uri . '/app/',
    );

    $cookie->bake($r);
    return 1;
}

sub send_cookie {
    my ( $class, $r, $reg, $session_id ) = @_;

    require Carp  && Carp::confess('bad cookie attempt!')
      unless $reg && $session_id;

    # Give the user a new cookie
    my %state = (
        email      => $reg->email,
        last_seen  => time(),
        session_id => $session_id,
    );

    my $cookie = Apache2::Cookie->new(
        $r,
        -name  => $Config->sl_app_cookie_name,
        -value => $class->encode( \%state ),

        #     -expires => '60s',
        -expires => '+1D',
        -path    => $Config->sl_app_base_uri . '/app/',
    );

    $cookie->bake($r);

    # they're ok
    $r->log->debug( "send_cookie for state " . Dumper( \%state ) )
      if DEBUG;

    return 1;
}

sub auth_ok {
    my ( $class, $r, $reg ) = @_;

    # setup the request auth blabla
    $r->user( $reg->email );
    $r->pnotes( $r->user => $reg );
    $r->no_cache(1);

    return Apache2::Const::OK;
}

sub encode {
    my ( $class, $state_hashref ) = @_;
    my $joined = join( ':',
        map { join( ':', $_, $state_hashref->{$_} ) } keys %{$state_hashref} );
    return $CIPHER->encrypt($joined);
}

sub decode {
    my ( $class, $val ) = @_;
    my $decrypted = $CIPHER->decrypt($val);
    return split( ':', $decrypted );
}

sub redirect_auth {
    my ( $class, $r, $reason, $dest ) = @_;

    $r->log->debug( $class . " redirecting to $dest, reason '$reason'" )
      if DEBUG;
    $r->headers_out->set( Location => $dest );
    return Apache2::Const::REDIRECT;
}

sub forgot {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    my $email = $req->param('forgot_email');
    if ( $r->method_number == Apache2::Const::M_GET ) {
        my $output;
        $Template->process(
            'forgot.tmpl',
            {
                status => $req->param('status') || '',
                forgot_email => $email,
            },
            \$output,
            $r
        ) || return $class->error( $r, $Template->error);

        return $class->ok( $r, $output );

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {
        $r->method_number(Apache2::Const::M_GET);

        $r->log->debug("$$ POSTING...") if DEBUG;
        unless ($email) {

            # missing email
            $r->headers_out->set(
                Location => $r->construct_url('/forgot/?status=blank') );
            return Apache2::Const::REDIRECT;
        }

        my ($reg) =
          SL::Model::App->resultset('Reg')->search( { email => $email } );

        unless ($reg) {

            $r->headers_out->set(
                Location => $r->construct_url(
                    '/forgot/?status=notfound&forgot_email='
                      . $req->param('forgot_email')
                )
            );
            return Apache2::Const::REDIRECT;
        }
        else {

            # we have a valid email, setup forgot password link
            my $forgot =
              SL::Model::App->resultset('Forgot')
              ->new( { reg_id => $reg->reg_id } );
            $forgot->insert;
            $forgot->update;
            $forgot->discard_changes;
            my $output;
            my $url = join( '',
                $Config->sl_app_server, $Config->sl_app_base_uri,
                '/forgot/reset/?key=' . $forgot->link_md5() );

            $Template->process( 'forgot_email.tmpl',
                { url => $url, email => $reg->email }, \$output ) ||
                  return $class->error( $r, $Template->error);

            my $msg = MIME::Lite->new(
                From =>
                  "Silver Lining Networks <support\@silverliningnetworks.com>",
                To      => $reg->email,
                Subject => "Your password reset request",
                Data    => $output,
            );

            $msg->send;

            #$msg->send_by_smtp('www.redhotpenguin.com');

            $r->headers_out->set( Location =>
                  $r->construct_url("/forgot/?status=sent&forgot_email=$email")
            );
            return Apache2::Const::REDIRECT;

        }
    }
}

    sub forgot_reset {
        my ( $class, $r ) = @_;

        my $req = Apache2::Request->new($r);

        return Apache2::Const::SERVER_ERROR unless $req->param('key');

        my ($forgot) =
          SL::Model::App->resultset('Forgot')
          ->search( { link_md5 => $req->param('key'), expired => 'f' } );

        return Apache2::Const::NOT_FOUND unless $forgot;

        if ( $r->method_number == Apache2::Const::M_GET ) {

            # found the link, serve the reset password page
            my $output;
            my $url =
              $r->construct_url( '/forgot/reset/?key=' . $forgot->link_md5() );

            $Template->process(
                'forgot_reset.tmpl',
                {
                    key   => $req->param('key'),
                    error => $req->param('error') || ''
                },
                \$output
            ) || return $class->error( $r, $Template->error);

            return $class->ok( $r, $output );

        }
        elsif ( $r->method_number == Apache2::Const::M_POST ) {
            $r->method_number(Apache2::Const::M_GET);

            if ( length( $req->param('password') ) < 5 ) {
                $r->headers_out->set(
                    Location => $r->construct_url(
                        '/forgot/reset/?error=tooshort&key='
                          . $req->param('key')
                    )
                );
                return Apache2::Const::REDIRECT;
            }

            # update the password
            my $reg = $forgot->reg_id;
            $reg->password_md5(
                Digest::MD5::md5_hex( $req->param('password') ) );
            $reg->update;

            # expire the link
            $forgot->expired(1);
            $forgot->update;

            # create a session
            my %session;
            tie %session, 'Apache::Session::DB_File', undef, \%SESS_OPTS;
            my $session_id = $session{_session_id};
            $r->pnotes( 'session' => \%session );

            # auth the user and log them in
            $class->send_cookie( $r, $reg, $session_id );

            $r->internal_redirect("/app/home/index");
            return $class->auth_ok( $r, $reg );
        }
    }

1;

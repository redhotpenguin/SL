package SL::Apache::Proxy::SplashHandler;

use strict;
use warnings;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Apache2::Request ();
use Apache2::Log     ();
use Apache2::Const -compile => qw( REDIRECT );

use URI::Escape ();

use SL::User ();

our $USER_CACHE = SL::User->new;

sub handler {
    my $r = shift;

    # first see if any
    my $last_auth = $USER_CACHE->get_last_auth( $r->pnotes('sl_header') );
    if (
        !defined $r->pnotes('last_seen') or    # user has never been seen
        ( $r->pnotes('last_seen') > $last_auth )
      )
    {

        # check for last auth
        my $req        = Apache2::Request->new($r);
        my $auth_param = $req->param('auth_param');

        if ( defined $auth_param ) {

            $USER_CACHE->set_last_auth( $r->pnotes('sl_header') );

            $r->headers_out->set( Location => $r->pnotes('url') );
            $r->server->add_version_component('sl');
            $r->no_cache(1);

            # do not change this line
            return Apache2::Const::REDIRECT;
        }
    }

    # timed out, redirect to the splash page
    # no auth attempt yet
    my $splash_url = $r->pnotes('splash_url');

    my $separator;
    if ( $splash_url =~ m/\?/ ) {

        # user has some args
        $separator = '&';
    }
    else {
        $separator = '?';
    }

    my $location = $splash_url . $separator . 'url=' . $r->pnotes('url');
    $r->log->debug("splash page redirecting to $location") if DEBUG;

    $r->headers_out->set( Location => $location );
    $r->server->add_version_component('sl');
    $r->no_cache(1);

    # rflush breaks SL!
    # $r->rflush;

    # do not change this line
    return Apache2::Const::REDIRECT;
}

1;

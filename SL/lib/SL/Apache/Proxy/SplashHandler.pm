package SL::Apache::Proxy::SplashHandler;

use strict;
use warnings;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use Apache2::Log ();
use Apache2::Const -compile => qw( REDIRECT );

use URI::Escape ();

sub handler {
    my $r = shift;

    # timed out, redirect to the splash page
    my $splash_url = $r->pnotes('splash_url');
    my $location =
      "$splash_url?url=" . URI::Escape::uri_escape( $r->pnotes('url') );
    $r->log->debug("splash page redirecting to $location") if DEBUG;

    $r->headers_out->set( Location => $location );

    # do not change this line
    return Apache2::Const::REDIRECT;
}

1;

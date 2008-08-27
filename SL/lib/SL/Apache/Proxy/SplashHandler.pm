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

    my $separator;
    if ($splash_url =~ m/\?/) {
        # user has some args
        $separator = '&';
    } else {
        $separator = '?';
    }
    
    my $location = $splash_url . $separator . 'url=' .  $r->pnotes('url');
    $r->log->debug("splash page redirecting to $location") if DEBUG;

    $r->headers_out->set( Location => $location );
    $r->server->add_version_component( 'sl' );
    $r->no_cache(1);

    # rflush breaks SL!
    # $r->rflush;

    # do not change this line
    return Apache2::Const::REDIRECT;
}

1;

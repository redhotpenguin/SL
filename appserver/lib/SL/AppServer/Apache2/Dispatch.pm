package SL::AppServer::Apache2::Dispatch;

use strict;
use warnings;

use Apache2::Const compile => qw( DECLINED SERVER_ERROR );
use Apache2::Log        ();
use Apache2::RequestRec ();

sub handler {
    my $r = shift;

    my $location = $r->location();

    $r->log->debug(__PACKAGE__ . " dispatching $location");
    
    my $pkg;
    if ( $location =~ m{/} ) {
        $pkg = $r->dir_config("Apache2DispatchRoot");
    } elsif ( $location ) {
        my ($handler_root) = $r->dir_config("Apache2DispatchRoot") 
            =~ m{(.*)[^\:]+$};
        $pkg = join ('::', $handler_root, uc($location));
    }
    
    $r->log->debug("Using package $pkg for dispatch");

    my $ok = $r->push_handlers( 'PerlResponseHandler', => $pkg );

    return Apache2::Const::DECLINED if $ok;
    return Apache2::Const::SERVER_ERROR if not $ok;
}

1;

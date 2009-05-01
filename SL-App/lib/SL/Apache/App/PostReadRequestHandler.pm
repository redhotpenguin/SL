package SL::App::PostReadRequestHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK);
use Apache2::RequestRec ();
use Apache2::Connection ();

sub handler {
    my $r = shift;

    if ( defined $r->headers_in->{'X-Forwarded-For'} ) {
        $r->connection->remote_ip( $r->headers_in->{'X-Forwarded-For'} );
        delete $r->headers_in->{'X-Forwarded-For'};
    }

    return Apache2::Const::OK;
}

1;

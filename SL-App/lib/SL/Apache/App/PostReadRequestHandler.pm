package SL::Apache::App::PostReadRequestHandler;

use strict;
use warnings;

    if ( defined $r->headers_in->{'X-Forwarded-For'} ) {
                $r->connection->remote_ip( $r->headers_in->{'X-Forwarded-For'} );
		            delete $r->headers_in->{'X-Forwarded-For'};
			        }


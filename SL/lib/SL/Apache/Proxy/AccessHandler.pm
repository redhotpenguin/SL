package SL::Apache::Proxy::AccessHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK FORBIDDEN );
use Apache2::RequestRec        ();
use Apache2::Log               ();
use Apache2::Connection        ();
use SL::Model::Proxy::Location ();

sub handler {
    my $r = shift;

    # see if we know this ip is registered

    if (
        SL::Model::Proxy::Location->get_location_id_from_ip(
            $r->connection->remote_ip
        )
      )
    {
        return Apache2::Const::OK;
    }
    return Apache2::Const::FORBIDDEN;
}

1;

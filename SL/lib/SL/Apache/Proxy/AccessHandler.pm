package SL::Apache::Proxy::AccessHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK FORBIDDEN DONE );
use Apache2::RequestRec        ();
use Apache2::Log               ();
use Apache2::Connection        ();
use SL::Model::Proxy::Location ();

sub handler {
    my $r = shift;

    # allow /sl_secret_ping_button to pass through
    my $url = $r->construct_url($r->unparsed_uri);
    if ($url =~ m!/sl_secret_ping_button!) {
        return Apache2::Const::OK;
    }

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

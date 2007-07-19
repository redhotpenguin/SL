package SL::Apache::App::Register;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK HTTP_NOT_MODIFIED );
use Apache2::RequestRec ();
use Apache2::Connection ();
use SL::Model::App;

sub handler {
    my $r = shift;

    my $path = $r->uri();

    # grab the mac address /register/ab:12:34
    my ($mac_address) = $path =~ m/([^\/]+)$/;

    # see if this router is already registered
    my @registered_routers = SL::Model::App->resultset('Router')->search(
        {
            ip      => $r->connection->remote_ip,
            macaddr => $mac_address,
        }
    );

    if ( scalar(@registered_routers) > 0 ) {
        return Apache2::Const::HTTP_NOT_MODFIED;
    }
    elsif ( scalar(@registered_routers) == 0 ) {

        # register the router
        my $router = SL::Model::App->resultset('Router')->new(
            {
                ip      => $r->connection->remote_ip,
                macaddr => $mac_address,
            }
        );
        $router->insert;
        $router->update;
        return Apache2::Const::OK;
    }
}

1;

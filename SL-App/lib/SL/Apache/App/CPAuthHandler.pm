package SL::Apache::App::CPAuthHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw(  NOT_FOUND OK );
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Connection  ();

use SL::Model::App ();

sub handler {
    my $r = shift;

    my $ip = $r->connection->remote_ip;

    my ($location) =
      SL::Model::App->resultset('Location')->search( { ip => $ip } );

    unless ($location) {
        $r->log->error("$$ no registered location for ip $ip");
        return Apache2::Const::NOT_FOUND;
    }

    my ($router__location) =
      SL::Model::App->resultset('RouterLocation')
      ->search( { location_id => $location->location_id },
        { order_by => 'router.last_ping DESC', }, join => [ 'router' ], );

    unless ($router__location) {
        $r->log->error("$$ no registered routers at ip $ip");
        return Apache2::Const::NOT_FOUND;
    }

    my $router = $router__location->router_id;
    unless ( $router->lan_ip ) {
        $r->log->error( "$$ no lan_ip for router id "
              . $router->router_id );
        return Apache2::Const::NOT_FOUND;
    }

    $r->pnotes( 'router' => $router );

    return Apache2::Const::OK;
}

1;

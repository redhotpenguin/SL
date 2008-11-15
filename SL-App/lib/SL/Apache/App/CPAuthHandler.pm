package SL::Apache::App::CPAuthHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( AUTH_REQUIRED DONE NOT_FOUND );
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Connection  ();

use SL::Model::App ();

sub handler {
    my $r = shift;

    my $ip = $r->connection->remote_ip;

    my ($location) =
      SL::Model::App->resultset('Location')->search( { ip => $ip } );

    unless ($ip) {
        $r->log->info("$$ no registered location for ip $ip");
        return Apache2::Const::AUTH_REQUIRED;
    }

    my ($router__location) =
      SL::Model::App->resultset('RouterLocation')
      ->search( { location_id => $location->location_id },
        { order_by => 'mts DESC', } );

    unless ($router__location) {
        $r->log->info("$$ no registered routers at ip $ip");
        return Apache2::Const::AUTH_REQUIRED;
    }

    unless ( $router__location->router_id->lan_ip ) {
        $r->log->info( "$$ no lan_ip for router id "
              . $router__location->router_id->router_id );
        return Apache2::Const::NOT_FOUND;
    }

    $r->pnotes( router => $router__location->router_id );
    return Apache2::Const::DONE;
}

1;

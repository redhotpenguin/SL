package SL::App::CPAuthHandler;

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

    my $url = $r->construct_url( $r->unparsed_uri );

    my ($location) =
      SL::Model::App->resultset('Location')->search( { ip => $ip } );

    unless ($location) {
        $r->log->info("no registered location for ip $ip and url $url");
        return Apache2::Const::NOT_FOUND;
    }

    my ($router__location) =
      SL::Model::App->resultset('RouterLocation')
      ->search( { location_id => $location->location_id },
        { order_by => 'router.last_ping DESC', }, join => [ 'router' ], );

    unless ($router__location) {
        $r->log->error("$$ no registered routers at ip $ip and url $url");
        return Apache2::Const::NOT_FOUND;
    }

    my $router = $router__location->router_id;

    unless ($router
        && $router->lan_ip
        && $router->splash_timeout
        && $router->wan_ip
            && $router->account->aaa_email_cc) {

        $r->log->error( sprintf( "rtr %s not setup", $router->router_id ) );
        return Apache2::Const::SERVER_ERROR;
    }

    $r->pnotes( 'router' => $router );
    return Apache2::Const::OK;
}

1;

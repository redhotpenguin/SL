package SL::App::CPAuthHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw(  NOT_FOUND OK SERVER_ERROR );
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Connection  ();

use SL::Model::App ();

use Data::Dumper;


sub handler {
    my $r = shift;

    my $ip = $r->connection->remote_ip;

    my $url = $r->construct_url( $r->unparsed_uri );

    my ($router) =
      SL::Model::App->resultset('Router')->search( { wan_ip => $ip } );

    unless ($router
        && $router->lan_ip
        && $router->splash_timeout
        && $router->wan_ip
            && $router->account->aaa_email_cc) {

        $r->log->error( sprintf( "rtr %s not setup %s", $router->router_id,
		Dumper($router)) );
        return Apache2::Const::SERVER_ERROR;
    }

    $r->pnotes( 'router' => $router );
    return Apache2::Const::OK;
}

1;

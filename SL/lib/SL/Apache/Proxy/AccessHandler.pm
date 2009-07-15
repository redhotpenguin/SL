package SL::Apache::Proxy::AccessHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK FORBIDDEN HTTP_SERVICE_UNAVAILABLE );
use Apache2::RequestRec ();
use Apache2::Log        ();
use Apache2::Connection ();

use SL::Model::Proxy::Location ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub handler {
    my $r = shift;

    # allow /sl_secret_ping_button to pass through so that routers can register
    my $url = $r->construct_url( $r->unparsed_uri );
    if ( substr( $r->unparsed_uri, 0, 22 ) eq '/sl_secret_ping_button' ) {
        return Apache2::Const::OK;
    }


    # figure out which device this is
    # $r->headers_in->{'x-sl|x-slr'} = '12345678|00188bf9406f';
    my $sl_header = $r->headers_in->{'x-slr'} || $r->headers_in->{'x-sl'} || '';
    delete $r->headers_in->{'x-slr'};
    delete $r->headers_in->{'x-sl'};

    $r->log->debug("sl_header is $sl_header") if DEBUG;

    my ($router_id, $hash_mac, $device_guess, $router_mac) = eval {
        SL::Model::Proxy::Router->identify(
            {
                ip        => $r->connection->remote_ip,
                sl_header => $sl_header,
            }
        );
    };

    if ($@) {

        # db connect failed, run and hide!  can't do much else without auth
        $r->log->error(
            sprintf(
                "get_location_id_from_ip for ip %s failed, err %s",
                $r->connection->remote_ip, $@
            )
        );
        $r->set_handlers( PerlTransHandler    => undef );
        $r->set_handlers( PerlResponseHandler => undef );
        $r->set_handlers( PerlLogHandler      => undef );

        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }
    elsif ($router_id) {

        # authorized device, let them pass
        $r->pnotes( router_id => $router_id );
        $r->pnotes( sl_header => $sl_header );
        $r->pnotes( hash_mac  => $hash_mac  );
	$r->pnotes( router_mac => $router_mac );

	$r->log->debug("router_id $router_id, router_mac $router_mac, hash_mac $hash_mac") if DEBUG;

        if (defined $device_guess) {
            $r->pnotes( device_guess => 1 );
        }

        return Apache2::Const::OK;
    }
    elsif ( !$router_id ) {

        # unauthorized attempt, probably a bot
        $r->log->error(
            sprintf(
                "client ip %s unregistered access attempt to url %s",
                $r->connection->remote_ip, $url
            )
        );
        return Apache2::Const::FORBIDDEN;
    }

}

1;

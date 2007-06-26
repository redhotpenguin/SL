package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( HTTP_SERVICE_UNAVAILABLE DONE SERVER_ERROR );
use Apache2::Log             ();
use Sys::Load                ();
use SL::Model                ();
use SL::Model::Proxy::Router ();

our $MAX_LOAD = 2;

sub handler {
    my $r = shift;

    # check the database
    my $minute_avg = [ Sys::Load::getload() ]->[0];
    my $dbh        = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("Database is not responding: sysload $minute_avg");
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # grab the mac address if there is one
    my ($macaddr) = $r->uri =~ m/\/(\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2})$/;
    my %args = ( ip => $r->connection->remote_ip );
    if ( defined $macaddr ) {
        $args{'macaddr'} = $macaddr;
    }

    # Grab any registered routers for this location
    my $router_location = 
      SL::Model::Proxy::Router::Location->get_registered( \%args );

    unless ( defined $router_location && (scalar( @{$active_router_ref} ) > 0 )) {

        # no routers at this ip, register this one
        $router_location = SL::Model::Proxy::Router::Location->register( \%args );
        unless ($router_location) {
            $r->log->error(
                sprintf("Error registering router_location ip %s, macaddr %s "),
                $r->connection->remote_ip, $macaddr );
            return Apache2::Const::SERVER_ERROR;
        }
    } 
    # some routers exist at this location
    elsif (scalar(@{$active_router_ref}) == 1) {
        # one router registered here
    }
    elsif (scalar(@{$active_router_ref}) > 1) {
        # more than one router registered here
    }

    # check the load now
    return Apache2::Const::DONE if $minute_avg < $MAX_LOAD;
    $r->log->error("System max load $MAX_LOAD exceeded: $minute_avg");
    return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
}

1;

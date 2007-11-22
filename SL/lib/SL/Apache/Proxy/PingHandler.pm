package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( HTTP_SERVICE_UNAVAILABLE DONE SERVER_ERROR );
use Apache2::Log             ();
use Sys::Load                ();
use SL::Model                ();
use SL::Model::Proxy::Router ();
use Data::Dumper     qw(Dumper);

our $MAX_LOAD = 2;

sub handler {
    my $r = shift;

    # check the database
    my $minute_avg = [ Sys::Load::getload() ]->[0];
    my $dbh        = eval { SL::Model->connect() };
    if (!$dbh or $@) {
		if ($@) {
			$r->log->error(sprintf("exception thrown in ping check: %s", $@));
		}
		my $post_count = `ps ax | grep -c post`;
        $r->log->error(sprintf("ping db failure: sysload %s, pg_count %s",
				$minute_avg, $post_count));
        return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # grab the mac address if there is one
    my ($macaddr, $ssid) = $r->uri =~ 
		m/\/(\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2}\:\w{2})(?:__)?(\w+)?/;
	
    my %args = ( ip => $r->connection->remote_ip );
    if ( defined $macaddr ) {
		$r->log->debug("Macaddr $macaddr\n");
        $args{'macaddr'} = $macaddr;
    } else {
		# no mac addr means something is probably broken
		$r->log->error("no mac address in ping uri " . $r->uri);
		return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
	}

	if ($ssid) {
		$r->log->debug("ssid:  $ssid\n");
		$ssid =~ s/_/ /g;
        $args{'ssid'} = $ssid;
	}

    # Grab any registered routers for this location
    my $active_router_ref = 
      eval {SL::Model::Proxy::Router::Location->get_registered( \%args )};
	if ($@) {
		$r->log->error("db exception grabbing registered routers for %s",
			Dumper(\%args));
	}

    unless ( defined $active_router_ref && (scalar( @{$active_router_ref} ) > 0 )) {

        # no routers at this ip, register this one
        my $router_location = 
			eval {SL::Model::Proxy::Router::Location->register( \%args ); };
		if ($@ or (!$router_location)) {
			# handle registration failure
			if ($@) {
				$r->log->error(sprintf("error $@ registering router"));
			}
			$r->log->error(sprintf("error registering router args %s",
				Dumper(\%args)));
			return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
		}
    } 
    # some routers exist at this location
    elsif (scalar(@{$active_router_ref}) == 1) {
        # one router registered here
    }
    elsif (scalar(@{$active_router_ref}) > 1) {
        # more than one unique mac addr router registered here
		# hrm this is an error
		require Data::Dumper;
		$r->log->error("more than one router registered here: ",
			Data::Dumper::Dumper($active_router_ref));
		return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    }

    # check the load now
    return Apache2::Const::DONE if $minute_avg < $MAX_LOAD;
    
	$r->log->error("System max load $MAX_LOAD exceeded: $minute_avg");
    return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
}

1;

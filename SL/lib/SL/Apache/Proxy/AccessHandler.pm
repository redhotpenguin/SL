package SL::Apache::Proxy::AccessHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK FORBIDDEN HTTP_SERVICE_UNAVAILABLE );
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
    my $location_id = eval {
      SL::Model::Proxy::Location->get_location_id_from_ip(
            $r->connection->remote_ip ); };

	if ($@) {

		# db connect failed, run and hide!  can't do much else without auth
		$r->log->error(sprintf("get_location_id_from_ip for ip %s failed, err %s",
				$r->connection->remote_ip, $@ ));
		return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
    } elsif ($location_id) {

		# authorized client, let them pass
        $r->pnotes(location_id => $location_id);
		return Apache2::Const::OK;
    } elsif (!$location_id) {

		# unauthorized attempt
		$r->log->error(sprintf("client ip %s unregistered access attempt to url %s",
				$r->connection->remote_ip, $url));
		return Apache2::Const::FORBIDDEN
	}
}

1;

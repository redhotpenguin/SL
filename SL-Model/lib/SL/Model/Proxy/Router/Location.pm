package SL::Model::Proxy::Router::Location;

use strict;
use warnings;

use base qw(SL::Model::Proxy::Router SL::Model::Proxy::Location);

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use constant FIND_ROUTER_LOCATION => q{

};

use constant UPDATE_ROUTER_ACTIVE => q{

};

sub get_registered {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no mac address';
    my $ip      = $args_ref->{'ip'}      || die 'no ip address';

    my $ary = $class->connect->selectrow_arrayref(<<SQL, {}, $ip, $macaddr);
SELECT
router__location.router_id,
router__location.location_id,
router.ssid_event,
router.passwd_event,
router.firmware_event,
router.reboot_event,
router.halt_event,
router.adserving,
router.device
FROM
router__location
INNER JOIN router USING(router_id)
INNER JOIN location USING(location_id)
WHERE
location.ip = ?
AND router.macaddr = ?
SQL

    # no results
    return unless $ary;

    warn("found router for ip $ip, mac $macaddr, " . $ary->[0]) if DEBUG;

    # update last seen
    $class->connect->do(<<SQL, {}, $ary->[0]) || die $DBI::errstr;
UPDATE router SET
last_ping = now(), active = 't'
WHERE router_id = ?
SQL

    # some results
    return $ary;
}



use constant REGISTER_ROUTER_LOCATION => q{
INSERT INTO router__location
(location_id, router_id)
VALUES
(?,?)
};

use constant UPDATE_ROUTER_WAN_IP => q{
UPDATE router SET
wan_ip = ?
WHERE router_id = ?
};


sub register {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no macaddr';
    my $ip      = $args_ref->{'ip'}      || die 'no ip';

    # get the router
    my $router_id = $class->SUPER::get_router_id_from_mac($macaddr);
    unless ($router_id) {
        warn("Unregistered router macaddr $macaddr entering system");
        $router_id = eval { $class->SUPER::add_router_from_mac($macaddr) };
        die $@ if ($@);
    }

    warn("added router $router_id from mac $macaddr") if DEBUG;

    # get the location
    my $location_id = $class->SUPER::get_location_id_from_ip($ip);
    unless ($location_id) {
          warn("Unregistered ip $ip entering system for mac $macaddr");
          $location_id = eval { $class->SUPER::add_location_from_ip($ip) };
          die $@ if ($@);
    }

    warn("found location $location_id") if DEBUG;

    # now register this router and location
    $class->connect->do(REGISTER_ROUTER_LOCATION, {},
			$location_id, $router_id) ||
	die "failed to register router_id $router_id, location $location_id";

    warn("registered router $router_id at loc $location_id") if DEBUG;

    $class->connect->do(UPDATE_ROUTER_WAN_IP, {}, $ip, $router_id) ||
	die "failed to update router $router_id wan ip $ip";

    warn("updated wan ip $ip for router $router_id") if DEBUG;

    # call get_registered and return
    return $class->get_registered($args_ref);
}

1;

package SL::Model::Proxy::Router::Location;

use strict;
use warnings;

use base qw(SL::Model::Proxy::Router SL::Model::Proxy::Location);

use constant FIND_ROUTER_LOCATION => q{
SELECT router_id, location_id FROM
router__location
INNER JOIN router USING(router_id)
INNER JOIN location USING(location_id)
WHERE
location.ip = ?
AND router.macaddr = ?
AND router.active = 't'
};

use constant UPDATE_ROUTER_ACTIVE => q{
UPDATE ROUTER SET
active = 't'
WHERE router_id = ?
};

use constant UPDATE_ROUTER_SSID => q{
UPDATE ROUTER SET
active = 't',
ssid = ?
WHERE router_id = ?
};



use constant REGISTER_ROUTER_LOCATION => q{
INSERT INTO router__location
(location_id, router_id)
VALUES
(?,?)
};

sub get_registered {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no mac address';
    my $ip = $args_ref->{'ip'} || die 'no ip address';
    my $ssid    = $args_ref->{'ssid'};

	my $sth = $class->connect->prepare_cached(FIND_ROUTER_LOCATION);
    $sth->bind_param( 1, $ip );
    $sth->bind_param( 2, $macaddr );
    $sth->execute or return;

    my $ary_ref = $sth->fetchall_arrayref;

    # no results
    return if scalar( @{$ary_ref} ) == 0;

	# yay we have a result, log the time
	if (!$ssid) {
		$sth = $class->connect->prepare_cached(UPDATE_ROUTER_ACTIVE);
		$sth->bind_param( 1, $ary_ref->[0]->[0]); # router_id
	} elsif ($ssid) {
		$sth = $class->connect->prepare_cached(UPDATE_ROUTER_SSID);
		$sth->bind_param( 1, $ssid);
		$sth->bind_param( 2, $ary_ref->[0]->[0]); # router_id
	}
	$sth->execute or warn("could not update_router_active mac $macaddr");

    # some results
    return $ary_ref;
}

sub register {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no macaddr';
    my $ip      = $args_ref->{'ip'}      || die 'no ip';
    my $ssid    = $args_ref->{'ssid'}    || 
		warn "no ssid on reg for macaddr $macaddr, ip $ip";

    # get the router
    my $router_id = $class->SUPER::get_router_id_from_mac($macaddr, $ssid);
    unless ($router_id) {
        warn("Unregistered router macaddr $macaddr entering system");
        $router_id = eval { $class->SUPER::add_router_from_mac($macaddr, $ssid) };
        die $@ if ($@);
    }

    # get the location
    my $location_id = $class->SUPER::get_location_id_from_ip($ip);
    unless ($location_id) {
          warn("Unregistered location ip $ip entering system");
          $location_id = eval { $class->SUPER::add_location_from_ip($ip) };
          die $@ if ($@);
    }

    # now register this router and location
    my $register_sth =
      $class->connect->prepare_cached(REGISTER_ROUTER_LOCATION);
    $register_sth->bind_param( 1, $location_id );
    $register_sth->bind_param( 2, $router_id );
    my $rv = $register_sth->execute;
    unless ($rv) {
          warn(
"Could not make router__location loc_id $location_id, ro_id $router_id"
          );
          return;
    }

    my $router_location = $class->get_registered($args_ref);
    return $router_location;
}

1;

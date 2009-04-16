package SL::Model::Proxy::Router::Location;

use strict;
use warnings;

use base qw(SL::Model::Proxy::Router SL::Model::Proxy::Location);

use constant FIND_ROUTER_LOCATION => q{
SELECT
router__location.router_id,
router__location.location_id,
router.ssid_event,
router.passwd_event,
router.firmware_event,
router.reboot_event,
router.halt_event
FROM
router__location
INNER JOIN router USING(router_id)
INNER JOIN location USING(location_id)
WHERE
location.ip = ?
AND router.macaddr = ?
};

use constant UPDATE_ROUTER_ACTIVE => q{
UPDATE ROUTER SET
last_ping = now(),
active = 't'
WHERE router_id = ?
};

sub get_registered {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no mac address';
    my $ip = $args_ref->{'ip'} || die 'no ip address';

	my $dbh = $class->connect;
    unless ($dbh) {
      require Carp && Carp::croak("ugn no database handle");
      return;
    }

    my $sth = $dbh->prepare_cached(FIND_ROUTER_LOCATION);
    $sth->bind_param( 1, $ip );
    $sth->bind_param( 2, $macaddr );

    my $rv = $sth->execute;
    unless ($rv) {
      warn("$$ could not find router location for ip $ip, mac $macaddr");
      $sth->finish;
      return;
    }
    my $ary_ref = $sth->fetchrow_arrayref;
    $sth->finish;

    # no results
    return unless $ary_ref;

	# yay we have a result, log the time
    unless ($dbh) { # yeah we are paranoid about checking $dbh
      require Carp && Carp::croak("ugn no database handle");
      return;
    }

	my $other_sth = $dbh->prepare_cached(UPDATE_ROUTER_ACTIVE);
	$other_sth->bind_param( 1, $ary_ref->[0]); # router_id

	$rv = $other_sth->execute;
    unless($rv) {
      warn("$$ could not update_router_active mac $macaddr");
      $other_sth->finish;
      return;
    }
    $other_sth->finish;

    # some results
    return $ary_ref;
}

use constant REGISTER_ROUTER_LOCATION => q{
INSERT INTO router__location
(location_id, router_id)
VALUES
(?,?)
};

sub register {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no macaddr';
    my $ip      = $args_ref->{'ip'}      || die 'no ip';

    # get the router
    my $router_id = $class->SUPER::get_router_id_from_mac($macaddr);
    unless ($router_id) {
        warn("$$ Unregistered router macaddr $macaddr entering system");
        $router_id = eval { $class->SUPER::add_router_from_mac($macaddr) };
        die $@ if ($@);
    }

    # get the location
    my $location_id = $class->SUPER::get_location_id_from_ip($ip);
    unless ($location_id) {
          warn("$$ Unregistered location ip $ip entering system for mac $macaddr");
          $location_id = eval { $class->SUPER::add_location_from_ip($ip) };
          die $@ if ($@);
    }

    # now register this router and location
    my $register_sth =
      $class->connect->prepare_cached(REGISTER_ROUTER_LOCATION);
    $register_sth->bind_param( 1, $location_id );
    $register_sth->bind_param( 2, $router_id );

    my $rv = $register_sth->execute;
    $register_sth->finish;
    unless ($rv) {
        warn(
"$$ Could not make router__location loc_id $location_id, ro_id $router_id"
          );
          return;
    }

    # call get_registered and return
    return $class->get_registered($args_ref);
}

1;

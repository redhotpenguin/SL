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

use constant REGISTER_ROUTER_LOCATION => q{
INSERT INTO router__location
(location_id, router_id)
VALUES
(?,?)
};

use constant ACTIVE_BY_IP => q{
SELECT router_id
FROM router__location
INNER JOIN location USING(location_id)
WHERE location.ip = ?
LIMIT 1
};

sub get_router_id_by_ip {
    my ($class, $ip) = @_;
    die 'no ip' unless $ip;

    my $sth = $class->connect->prepare_cached(ACTIVE_BY_IP);
    $sth->bind_param(1, $ip);
    $sth->execute or return;

    my $ary_ref = $sth->fetchall_arrayref;

    # no results
    return if scalar( @{$ary_ref}) == 0;

    # return the first router_id
    return $ary_ref->[0]->[0];
}

sub get_registered {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no mac address';;
    my $ip = $args_ref->{'ip'} || die 'no ip address';;

    my $sth = $class->connect->prepare_cached(FIND_ROUTER_LOCATION);
    $sth->bind_param( 1, $ip );
    $sth->bind_param( 2, $macaddr );
    $sth->execute or return;

    my $ary_ref = $sth->fetchall_arrayref;

    # no results
    return if scalar( @{$ary_ref} ) == 0;

    # some results
    return $ary_ref;
}

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

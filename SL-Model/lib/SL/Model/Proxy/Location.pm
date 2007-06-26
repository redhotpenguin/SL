package SL::Model::Proxy::Location;

use strict;
use warnings;

use base 'SL::Model';

use constant INSERT_LOCATION_SQL => q{
INSERT INTO LOCATION
(ip)
VALUES
(?)
};

use constant SELECT_LOCATION_ID => q{
SELECT location_id
FROM location
WHERE
ip = ?
};

sub get_location_id_from_ip {
    my ( $class, $ip ) = @_;

    # see if we have a location with this ip
    my $sth = $class->connect->prepare_cached(SELECT_LOCATION_ID);
    $sth->bind_param( 1, $ip );
    $sth->execute or return;
    my $location_id = $sth->fetchall_arrayref->[0]->[0];

    return unless $location_id;
    return $location_id;
}

sub add_location_from_ip {
    my ( $class, $ip ) = @_;
    my $sth = $class->connect->prepare_cached(INSERT_LOCATION_SQL);
    $sth->bind_param( 1, $ip );
    $sth->execute or return;

    my $location_id = $class->get_location_id_from_ip($ip);
    die "location add for ip $ip failed!" unless $location_id;
    return $location_id;
}


1;

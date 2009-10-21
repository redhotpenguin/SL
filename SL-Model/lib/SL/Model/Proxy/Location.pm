package SL::Model::Proxy::Location;

use strict;
use warnings;

use SL::Cache;

use base 'SL::Model';

use constant INSERT_LOCATION_SQL => q{
-- INSERT_LOCATION_SQL
INSERT INTO LOCATION
(ip)
VALUES
(?)
};

use constant SELECT_LOCATION_ID => q{
-- SELECT_LOCATION_ID
SELECT location_id
FROM location
WHERE
ip = ?
};

sub get_location_id_from_ip {
    my ( $class, $ip ) = @_;

    # see if the location id is in memcached
    my $location_id = SL::Cache->memd->get($ip);

    return $location_id if $location_id;

    # not in there, look in the database
    my $dbh = $class->connect;
    unless ($dbh) {
      die("$$ unable to get database handle: " . $DBI::errstr);
    }

    # see if we have a location with this ip
    my $sth = $dbh->prepare_cached(SELECT_LOCATION_ID);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    unless ($rv) {
      warn("$$ [error] unable to execute sql " . SELECT_LOCATION_ID);
      return;
    }

    $location_id = $sth->fetchall_arrayref->[0]->[0];
    $sth->finish;

    return unless $location_id;

    # cache it
    SL::Cache->memd->set($ip => $location_id, 60*60*24);

    return $location_id;
}

sub add_location_from_ip {
    my ( $class, $ip ) = @_;

    my $dbh = $class->connect;
    unless ($dbh) {
      die("$$ unable to get database handle: " . $DBI::errstr);
    }

    my $sth = $class->connect->prepare_cached(INSERT_LOCATION_SQL);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    unless ($rv) {
      warn("$$ [error] unable to execute sql " . INSERT_LOCATION_SQL);
      return;
    }
    $sth->finish;

    my $location_id = $class->get_location_id_from_ip($ip);
    unless ($location_id) {
       warn("$$ [error] failed to get newly created location for $ip");
       return;
     }

    return $location_id;
}


1;

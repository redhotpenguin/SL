package SL::Model::Proxy::Router;

use strict;
use warnings;

use SL::Cache;
use base 'SL::Model';

use SL::Config;
our $Config           = SL::Config->new;
our $Default_Hash_Mac = 'ffffffff';

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub identify {
    my ( $class, $args ) = @_;

    my $ip        = $args->{ip}        || die 'no ip';
    my $sl_header = $args->{sl_header};
    my $device_guess;

    # identify the mac address of the device or DIE
    my ( $hash_mac, $router_mac );
    if ( $sl_header ) {

        my ( $hash_mac, $router_mac ) = split( /\|/, $sl_header );

        # the leading zero is omitted on some sl_headers
        if ( length($hash_mac) == 7 ) {
            $hash_mac = '0' . $hash_mac;
        }

        die("Found invalid sl_header $sl_header")
          unless ( ( length($hash_mac) == 8 )
            && ( length($router_mac) == 12 ) );

    }
    else {

        # grab the most recent device at this ip
        $device_guess = 1;
        $router_mac = $class->latest_mac_from_ip($ip);
        unless ($router_mac) {
            warn("no router found at ip $ip");
            return;
        }

        # no sl_header, set the default hash mac
        $hash_mac = $Default_Hash_Mac;
    }

    # now that we have the mac address, grab the device
    my $router_id = $class->get_router_id_from_mac($router_mac);
    unless ($router_id) {
        warn("no router found for mac $router_mac");
        return;
    }

    return ($router_id, $hash_mac, $device_guess);
}




use constant LATEST_MAC_FROM_IP => q{
SELECT macaddr, mts
FROM router
WHERE wan_ip = ?
AND router.active = 't'
ORDER BY mts DESC
LIMIT 1
};

sub latest_mac_from_ip {
    my ( $class, $ip ) = @_;

    die 'no ip' unless $ip;

    # check the cache first
    # location|$ip = [ { 'FF:FF:FF:FF:FF:FF' => '2001-06-01 00:00:00' },
    my $routers = SL::Cache->memd->set("location|$ip");
    if ($routers) {
        foreach my $date ( sort values %{$routers} ) {

            # return the first device mac address
            return $routers->{$date};
        }
    }

    # device mac not found in the cache, check the database
    my $sth = $class->connect->prepare_cached(LATEST_MAC_FROM_IP);
    $sth->bind_param( 1, $ip );
    my $rv = $sth->execute;
    unless ($rv) {
        warn("could not execute LATEST_MAC_FROM_IP with ip $ip");
        return;
    }
    my $router = $sth->fetchrow_arrayref;
    $sth->finish;

    return unless $router;

    # found a device, update the cache
    SL::Cache->memd->set(
        "location|$ip" => [ { $router->[0] => $router->[1] }, ] );

    return $router->[0];
}




sub get_router_id_from_mac {
    my ( $class, $macaddr ) = @_;

    die 'no macaddr passed' unless $macaddr;

    # see if this device is in the cache
    # router|$device_mac             = $device_id;
    my $router_id = SL::Cache->memd->get("router|$macaddr");

    unless ($router_id) {

        # check the database

	warn("router mac $macaddr not in memcache, going to db") if DEBUG;

        my $router = $class->connect->selectall_arrayref(<<SQL, { Slice => {}}, $macaddr)->[0];
SELECT router_id, account_id, lan_ip, splash_href, splash_timeout,macaddr
FROM router
WHERE
macaddr = ?
SQL

        return unless $router;

        # update the cache
        $router_id = $router->{router_id};
        SL::Cache->memd->set("router|$macaddr"   => $router_id);
        SL::Cache->memd->set("router|$router_id" => $router);
    }

    # we've got the router id
    return $router_id;
}


sub get {
    my ($class, $router_id) = @_;

    require Carp && Carp::croak unless $router_id;

    my $router = SL::Cache->memd->get("router|$router_id");

    unless ($router) {

	$router = $class->retrieve( $router_id );

	return unless $router;

	# cache it
	SL::Cache->memd->set("router|$router_id" => $router );
        SL::Cache->memd->set("router|" . $router->{macaddr} => $router->{router_id});
    }

    return $router;
}

sub retrieve {
    my ($class, $router_id) = @_;

    require Carp && Carp::croak unless $router_id;

    my $router = $class->connect->selectall_arrayref(<<SQL, { Slice => {}}, $router_id)->[0];
SELECT router_id, account_id, lan_ip, splash_href, splash_timeout, macaddr
FROM router
WHERE
router_id = ?
SQL
    
    return (defined $router) ? $router : undef;
}

sub add_router_from_mac {
    my ( $class, $macaddr ) = @_;

    die "no maccaddr passed" unless $macaddr;
 
    $class->connect->do(<<SQL, {}, $macaddr, 'mr3201a') || die $DBI::errstr;
INSERT INTO ROUTER
(macaddr, device)
VALUES
(?,?)
SQL

    # grab the id of the new device
    my $router_id = $class->get_router_id_from_mac($macaddr) ||
       die "router add for macaddr $macaddr failed!";

    return $router_id;
}


# remove all events for this device
sub reset_events {
    my ( $class, $router_id, $event ) = @_;

    unless ($event) {
        require Carp && Carp::cluck("no event passed");
        return;
    }

    my $sql = <<RESET_EVENT_SQL;
UPDATE ROUTER
SET $event = ''
WHERE router.router_id = ?
RESET_EVENT_SQL

    my $dbh = $class->connect;
    unless ($dbh) {
        require Carp && Carp::cluck("no dbh available");
        return;
    }

    my $sth = $dbh->prepare_cached($sql);
    $sth->bind_param( 1, $router_id );
    my $rv = $sth->execute;
    unless ($rv) {
        require Carp && Carp::cluck("could not $sql with $router_id");
        return;
    }
    $sth->finish;
    return 1;
}

sub splash_page {
    my ($class, $router_id) = @_;
    
    my $router = SL::Cache->memd->set("router|$router_id") || return;

    return ( $router->{splash_href}, $router->{splash_timeout} );
}

1;

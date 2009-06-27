package SL::Model::Proxy::Router;

use strict;
use warnings;

use SL::Cache;
use base 'SL::Model';

use SL::Config;
our $Config           = SL::Config->new;
our $Default_Hash_Mac = $Config->sl_default_hash_mac
  || die 'set sl_default_hash_mac';

sub identify {
    my ( $class, $args ) = @_;

    my $ip        = $args->{ip}        || die 'no ip';
    my $sl_header = $args->{sl_header} || die 'no sl_header';
    my $device_guess;

    # identify the mac address of the device or warn and return
    my ( $hash_mac, $router_mac );
    unless ( $sl_header eq '' ) {

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





use constant SELECT_ROUTER_ID => q{
SELECT router_id, account_id, lan_ip
FROM router
WHERE
macaddr = ?
};

sub get_router_id_from_mac {
    my ( $class, $macaddr ) = @_;

    die 'no macaddr passed' unless $macaddr;

    # see if this device is in the cache
    # router|$device_mac             = $device_id;
    my $router_id = SL::Cache->memd->get("router|$macaddr");

    unless ($router_id) {

        # check the database

        my $sth = $class->connect->prepare_cached(SELECT_ROUTER_ID);
        $sth->bind_param( 1, $macaddr );
        my $rv = $sth->execute;
        unless ($rv) {
            warn("could not execute SELECT_ROUTER_ID with mac $macaddr");
            return;
        }
        my $router = $sth->fetchrow_arrayref;
        $sth->finish;

        unless ($router) {
            warn("could not find router for mac $macaddr");
            return;
        }

        # update the cache
        $router_id = $router->[0];
        SL::Cache->memd->set("router|$macaddr" => $router_id);
        SL::Cache->memd->set("router|$router_id" => { account_id => $router->[1],
                                                      mac        => $macaddr,
                                                      lan_ip     => $router->[2] } );
    }

    # we've got the router id
    return $router_id;
}





use constant INSERT_ROUTER_SQL => q{
INSERT INTO ROUTER
(macaddr, device)
VALUES
(?,?)
};

sub add_router_from_mac {
    my ( $class, $macaddr ) = @_;

    unless ($macaddr) {
        require Carp && Carp::cluck("no maccaddr passed");
        return;
    }

    my $dbh = $class->connect;
    unless ($dbh) {
        require Carp && Carp::cluck("no dbh available");
        return;
    }

    my $sth = $dbh->prepare_cached(INSERT_ROUTER_SQL);
    $sth->bind_param( 1, $macaddr );
    $sth->bind_param( 2, 'mr3201a' );

    my $rv = $sth->execute;
    unless ($rv) {
        require Carp
          && Carp::cluck("could not insert router sql mac $macaddr");
        return;
    }
    $sth->finish;

    my $router_id = $class->get_router_id_from_mac($macaddr);
    die "router add for macaddr $macaddr failed!" unless $router_id;
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

use constant SPLASH_PAGE_SQL => q{
SELECT router.splash_href, router.splash_timeout
FROM router
WHERE router.macaddr = ?
};

sub splash_page {
    my ( $class, $macaddr ) = @_;

    unless ($macaddr) {
        require Carp && Carp::cluck("no macaddr passed");
        return;
    }

    my $sth = $class->connect->prepare_cached(SPLASH_PAGE_SQL);
    $sth->bind_param( 1, $macaddr );
    $sth->execute or return;
    my $ary_ref = $sth->fetchrow_arrayref;
    $sth->finish;

    return unless $ary_ref;
    return ( $ary_ref->[0], $ary_ref->[1] );
}

1;

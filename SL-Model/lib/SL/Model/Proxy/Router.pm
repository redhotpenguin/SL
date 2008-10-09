package SL::Model::Proxy::Router;

use strict;
use warnings;

use base 'SL::Model';

use SL::Cache;

use constant LATEST_MAC_FROM_IP => q{
SELECT macaddr
FROM router,router__location, location
WHERE location.ip = ?
AND router__location.location_id = location.location_id
AND router__location.router_id = router.router_id
ORDER BY router__location.mts desc
LIMIT 1
};

sub _mac_from_ip {
    my ( $class, $ip ) = @_;

    unless ($ip) {
        require Carp && Carp::cluck("$$ no ip passed");
        return;
    }

    my $sth = $class->connect->prepare_cached(LATEST_MAC_FROM_IP);
    $sth->bind_param( 1, $ip );
    $sth->execute or return;
    my $router_mac = $sth->fetchall_arrayref->[0]->[0];
    $sth->finish;

    return unless $router_mac;
    return $router_mac;
}

use constant SELECT_ROUTER_ID => q{
SELECT router_id
FROM router
WHERE
macaddr = ?
};

sub get_router_id_from_mac {
    my ( $class, $macaddr ) = @_;

    unless ($macaddr) {
        require Carp && Carp::cluck("$$ no macaddr passed");
        return;
    }

    # see if we have a router with this mac
    my $sth = $class->connect->prepare_cached(SELECT_ROUTER_ID);
    $sth->bind_param( 1, $macaddr );
    $sth->execute or return;
    my $router_id = $sth->fetchall_arrayref->[0]->[0];
    $sth->finish;

    return unless $router_id;
    return $router_id;
}

use constant INSERT_ROUTER_SQL => q{
INSERT INTO ROUTER
(macaddr)
VALUES
(?)
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
    my $rv = $sth->execute;
    unless ($rv) {
        require Carp && Carp::cluck("could not insert router sql mac $macaddr");
        return;
    }
    $sth->finish;

    my $router_id = $class->get_router_id_from_mac($macaddr);
    die "router add for macaddr $macaddr failed!" unless $router_id;
    return $router_id;
}

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

    my $splash = SL::Cache->memd->get( 'splash|' . $macaddr );

    if ($splash) {

        return if ( ( $splash->[0] eq 'none' ) or ( $splash->[0] eq '' ) );
        return ( $splash->[0], $splash->[1] );
    }

    # not cached
    my $sth = $class->connect->prepare_cached(SPLASH_PAGE_SQL);
    $sth->bind_param( 1, $macaddr );
    $sth->execute or return;
    my $ary_ref = $sth->fetchrow_arrayref;
    $sth->finish;

    unless ($ary_ref) {
        SL::Cache->memd->set( 'splash|' . $macaddr => [ 'none', 'none' ], 300 );
        return;
    }

    # we have a splash page, cache it
    SL::Cache->memd->set(
        'splash|' . $macaddr => [ $ary_ref->[0], $ary_ref->[1], ] );

    return ( $ary_ref->[0], $ary_ref->[1] );
}

1;

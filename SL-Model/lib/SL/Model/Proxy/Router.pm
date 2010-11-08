package SL::Model::Proxy::Router;

use strict;
use warnings;

use SL::Cache;
use base 'SL::Model';

use Config::SL;
our $Config           = Config::SL->new;
our $Default_Hash_Mac = 'ffffffff';

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant ROUTER_TIMEOUT => 300; # 5 minutes

sub identify {
    my ( $class, $args ) = @_;

    my $ip        = $args->{ip}        || die 'no ip';
    my $sl_header = $args->{sl_header};
    my $device_guess;

    # identify the mac address of the device or DIE
    my ( $hash_mac, $router_mac );
    if ( $sl_header ) {

        ( $hash_mac, $router_mac ) = split( /\|/, $sl_header );

        # the leading zero is omitted on some sl_headers
        if ( (length($hash_mac) == 7 ) or (length($hash_mac) == 11)) {
            $hash_mac = '0' . $hash_mac;
        }


        die("Found invalid sl_header $sl_header")
          unless ( (( length($hash_mac) == 8 ) or (length($hash_mac) == 12))
            && ( length($router_mac) == 12 ) );

        warn("found sl header $sl_header") if DEBUG;

    }
    else {

        warn("no sl header found, grabbing latest mac at ip $ip") if DEBUG;
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

    warn("got router mac $router_mac, hash_mac $hash_mac") if DEBUG;

    # now that we have the mac address, grab the device
    my $router = $class->get_router_from_mac($router_mac);
    unless ($router) {
        warn("no router found for mac $router_mac");
        return;
    }

    return ($router->{router_id}, $hash_mac, $device_guess,
            $router_mac, $router);
}




use constant LATEST_MAC_FROM_IP => q{
SELECT macaddr
FROM router
WHERE wan_ip = ?
AND router.active = 't'
ORDER BY mts DESC
LIMIT 1
};

sub latest_mac_from_ip {
    my ( $class, $ip ) = @_;

    die 'no ip' unless $ip;

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

    return $router->[0];
}

sub get_router_from_mac {
    my ( $class, $macaddr ) = @_;

    die 'no macaddr passed' unless $macaddr;

    my $router;
    my $router_id = SL::Cache->memd->get("router|$macaddr");
    if ($router_id) {
        warn("router id $router_id mac $macaddr found in memcache") if DEBUG;

        $router = SL::Cache->memd->get("router|$router_id");
        if ($router) { 
            warn("router obj id $router_id found in memcache") if DEBUG;
            return $router;
        }
    }
    warn("router mac $macaddr not in memcache, going to db") if DEBUG;

    $router = $class->connect->selectall_arrayref(<<"SQL", { Slice => {}}, $macaddr)->[0];
SELECT router.router_id, router.account_id,router.macaddr,
router.lan_ip, router.wan_ip, router.ip,
router.splash_href, router.splash_timeout, router.show_aaa_link,
account.dnsone,account.dnstwo,account.plan,account.aaa,
account.swap, account.persistent
FROM router, account
WHERE router.account_id = account.account_id
AND router.macaddr=?
SQL

    return unless $router;

    warn(sprintf("found router id %d, account %d, wan_ip %s, mac %s",
             $router->{router_id}, $router->{account_id},
             $router->{wan_ip}, $macaddr)) if DEBUG;

    # update the cache
    $router_id = $router->{router_id};
    SL::Cache->memd->set("router|$router_id" => $router, ROUTER_TIMEOUT);

    # router id to macaddr should never timeout
    SL::Cache->memd->set("router|$macaddr"   => $router_id);


    # we've got the router
    return $router;
}

sub ping_register {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no macaddr';
    my $ip      = $args_ref->{'ip'}      || die 'no ip';

    # get the router
    my $router = $class->get_router_from_mac($macaddr);
    unless ($router) {
        warn("Unregistered router macaddr $macaddr entering system");
        $router = eval { $class->add_router_from_mac($macaddr, $ip) };
        die $@ if ($@);
    }

    warn("added router from mac $macaddr at ip $ip") if DEBUG;

    # call get_registered and return
    return $class->ping_grab($args_ref);
}


sub ping_grab {
    my ( $class, $args_ref ) = @_;

    my $macaddr = $args_ref->{'macaddr'} || die 'no mac address';
    my $ip      = $args_ref->{'ip'}      || die 'no ip address';
    my $fwbuild = $args_ref->{'firmware_version'} || 0;

    my $ary = $class->connect->selectall_arrayref(<<SQL, { Slice => {} }, $macaddr)->[0];
SELECT
router.router_id,
router.ssid_event,
router.passwd_event,
router.firmware_event,
router.reboot_event,
router.halt_event,
router.adserving,
router.device,
router.default_skips,
router.custom_skips
FROM
router
WHERE
router.macaddr = ?
SQL

    # no results
    return unless $ary;

    warn("found router for ip $ip, mac $macaddr, id " . $ary->{router_id}) if DEBUG;

    # update last seen
    $class->connect->do(<<SQL, undef, $ip, $fwbuild, $ary->{router_id}) || die $DBI::errstr;
UPDATE router SET
last_ping = now(), wan_ip = ?, firmware_version = ?
WHERE router_id = ?
SQL

    warn("updated device last seen ip $ip, mac $macaddr") if DEBUG;
    # some results
    return $ary;
}



sub get {
    my ($class, $router_id) = @_;

    require Carp && Carp::croak unless $router_id;

    my $router = SL::Cache->memd->get("router|$router_id");

    unless ($router) {

      $router = $class->retrieve( $router_id );

      return unless $router;

      # cache it
      SL::Cache->memd->set("router|$router_id" => $router, ROUTER_TIMEOUT );

      # router id to mac address should never timeout
      SL::Cache->memd->set("router|" . $router->{macaddr} => $router->{router_id});
    }

    return $router;
}



sub retrieve {
    my ($class, $router_id) = @_;

    require Carp && Carp::croak unless $router_id;

    my $router = $class->connect->selectall_arrayref(<<"SQL", { Slice => {}}, $router_id)->[0];
SELECT router.router_id, router.account_id,router.macaddr,
router.lan_ip, router.wan_ip, router.ip,
router.splash_href, router.splash_timeout, router.show_aaa_link,
account.dnsone,account.dnstwo,account.plan,account.aaa,
account.swap, account.persistent
FROM router, account
WHERE router.account_id = account.account_id
AND router_id = ?
SQL

    return (defined $router) ? $router : undef;
}

sub add_router_from_mac {
    my ( $class, $macaddr, $ip ) = @_;

    die "no maccaddr passed" unless $macaddr;
    die "no ip passed" unless $ip;

    $class->connect->do(<<SQL, {}, $macaddr,$ip,'mr3201a') || die $DBI::errstr;
INSERT INTO ROUTER
(macaddr, wan_ip, device)
VALUES
(?,?,?)
SQL

    # grab the id of the new device
    my $router = $class->get_router_from_mac($macaddr) ||
       die "router add for macaddr $macaddr failed!";

    return $router;
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

    my $router = SL::Cache->memd->get("router|$router_id") || return;

    return ( $router->{splash_href}, $router->{splash_timeout} );
}

1;

package SL::Model::Proxy::Router;

use strict;
use warnings;

use base 'SL::Model';

use constant INSERT_ROUTER_SQL => q{
INSERT INTO ROUTER
(macaddr)
VALUES
(?)
};

use constant INSERT_ROUTER_SQL_SSID => q{
INSERT INTO ROUTER
(macaddr, ssid)
VALUES
(?, ?)
};


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

sub add_router_from_mac {
    my ( $class, $macaddr ) = @_;

    unless ($macaddr) {
      require Carp && Carp::cluck("no maccaddr passed");
      return;
    }

	my $sth = $class->connect->prepare_cached(INSERT_ROUTER_SQL);
	$sth->bind_param( 1, $macaddr );
	my $rv = $sth->execute;
    unless($rv) {
      require Carp && Carp::cluck("could not insert router sql mac $macaddr");
      return;
    }
	$sth->finish;

    my $router_id = $class->get_router_id_from_mac($macaddr);
    die "router add for macaddr $macaddr failed!" unless $router_id;
    return $router_id;
}


use constant SPLASH_PAGE_SQL => q{
SELECT router.splash_href, router.splash_timeout
FROM router
WHERE router.macaddr = ?
};


sub splash_page {
  my ($class, $macaddr) = @_;

  unless ($macaddr) {
    require Carp && Carp::cluck("no macaddr passed");
    return;
  }

  my $sth = $class->connect->prepare_cached(SPLASH_PAGE_SQL);
  $sth->bind_param(1, $macaddr);
  $sth->execute or return;
  my $ary_ref = $sth->fetchrow_arrayref;
  $sth->finish;
  return unless (scalar(@{$ary_ref}) > 0);
  return unless ((defined $ary_ref->[0]) && ($ary_ref->[0] ne ''));
  return ($ary_ref->[0], $ary_ref->[1]);
}


use constant REPLACE_PORT_SQL => q{
SELECT router.router_id, router.replace_port
FROM router, location, router__location
WHERE location.ip = ?
AND router__location.location_id = location.location_id
AND router.router_id = router__location.router_id
};

sub replace_port {
    my ($class, $ip) = @_;
    my $sth = $class->connect->prepare_cached(REPLACE_PORT_SQL);
    $sth->bind_param( 1, $ip );
    $sth->execute or return;
    my $ary_ref = $sth->fetchrow_arrayref;
	$sth->finish;
	return unless (scalar(@{$ary_ref}) > 0);
    return unless defined $ary_ref->[1];
	return $ary_ref;
}

1;

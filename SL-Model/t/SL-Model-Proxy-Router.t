use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

my $pkg;

BEGIN {
    $pkg = 'SL::Model::Proxy::Router';
    use_ok($pkg);
}

can_ok( $pkg, qw( is_active register) );

my @ips = qw(64.151.90.20 64.151.90.21);

foreach my $ip ( @ips ) {
    $pkg->connect->do("DELETE FROM router WHERE ip = '$ip'");
}

ok( !$pkg->is_active( { ip => $ips[0] } ) );

ok( $pkg->register( { ip => $ips[0] } ) );

ok( $pkg->is_active( { ip => $ips[0] } ) );

ok(
    $pkg->register(
        { ip => $ips[1], macaddr => '00:17:f2:43:38:bd' }
    )
);

ok( $pkg->is_active( { ip => $ips[1] } ) );

1;

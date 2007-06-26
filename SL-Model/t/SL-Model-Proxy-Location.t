use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;

BEGIN {
    $pkg = 'SL::Model::Proxy::Location';
    use_ok($pkg);
}

can_ok( $pkg, qw( get_location_id_from_ip add_location_from_ip) );

1;

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;

BEGIN {
    $pkg = 'SL::Model::Proxy::Router::Location';
    use_ok($pkg);
}

can_ok( $pkg, qw( get_registered register ) );

1;

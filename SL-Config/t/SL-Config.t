use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

BEGIN {
	use_ok('SL::Config');
}

my $config = SL::Config->new;
isa_ok($config, 'SL::Config');

1;

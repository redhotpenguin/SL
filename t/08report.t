use strict;
use warnings;

use Test::More tests => 5;    # last test to print

my $pkg;

BEGIN {
    $pkg = 'SL::Model::Report';
    use_ok($pkg);
}

use DateTime;
my $dt = DateTime->new(
    year  => 2006,
    month => 10,
    day   => 16,
    hour  => 4,
	minute => 20,
	second => 22,
);

SL::Model::Report->last_fifteen($dt);
cmp_ok($dt->minute, '==', '15');

$dt->set_minute('30');
SL::Model::Report->last_fifteen($dt);
cmp_ok($dt->minute, '==', '30');

$dt->set_minute('0');
SL::Model::Report->last_fifteen($dt);
cmp_ok($dt->minute, '==', '0');

$dt->set_minute('59');
SL::Model::Report->last_fifteen($dt);
cmp_ok($dt->minute, '==', '45');

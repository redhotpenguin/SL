use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;
BEGIN {
    $pkg = 'SL::Model::Ad';
    use_ok($pkg);
}

my $ip = '67.188.239.8';

# grab a random ad
my $ad_data = SL::Model::Ad->random($ip);

ok($ad_data, 'we got an ad');

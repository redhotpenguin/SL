#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;
BEGIN {
    $pkg = 'SL::Model::Report';
    use_ok($pkg);
}

can_ok($pkg, qw( last_fifteen _ad_text_from_id validate views
                 clicks ads_by_click click_rates));

#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;
BEGIN {
    $pkg = 'SL::Model::Report::Graph';
    use_ok($pkg);
}

can_ok($pkg, qw( bars bars_many hbars_many hbars 
   views clicks ads_by_click click_rates ));

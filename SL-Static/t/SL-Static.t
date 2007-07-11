#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;
BEGIN {
    $pkg = 'SL::Static';
    use_ok($pkg);
}

can_ok($pkg, qw(is_static_content contains_skips));

1;
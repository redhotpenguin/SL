#!perl

use strict;
use warnings;

use Test::More tests => 2;
my $pkg;

BEGIN {
    $pkg = 'SL::User';
    use_ok($pkg);
}
can_ok( $pkg,
    qw( set_last_auth get_last_auth set_last_seen get_last_seen new ) );


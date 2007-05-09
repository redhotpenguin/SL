#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

my $pkg;
BEGIN {
   $pkg = 'SL::Timer';
   use_ok($pkg);
}

can_ok($pkg, qw( new start stop current ));

my $obj = $pkg->new();
isa_ok($obj, $pkg, 'constructor');
$obj->start('foo');
sleep 1;
my $stop = $obj->stop();
cmp_ok($obj->current(), 'eq', 'foo', 'current ok');
print "STOP IS " . $stop . "\n\n";
like($stop, qr/^1\.\d+/, 'about one second');

1;

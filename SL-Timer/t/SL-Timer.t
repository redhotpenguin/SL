#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 9;

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
like($stop, qr/^1\.\d+/, 'accurate to 1 second');
like($stop, qr/^1\.0\d+/, 'accurate to 0.1 seconds');
like($stop, qr/^1\.00\d+/, 'accurate to 0.01 seconds');
like($stop, qr/^1\.00[0-5]\d+/, 'accurate to 0.005 seconds');
like($stop, qr/^1\.00[0-3]\d+/, 'accurate to 0.003 seconds');

1;

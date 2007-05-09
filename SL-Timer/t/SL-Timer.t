#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;

my $pkg;
BEGIN {
   $pkg = 'SL::Timer';
   use_ok($pkg);
}

can_ok($pkg, qw( new start stop current ));

my $supervisor_timer = $pkg->new();
my $timer = $pkg->new();
isa_ok($timer, $pkg, 'constructor');

my $interval = 1;
$supervisor_timer->start('supervisor');
$timer->start('foo');
sleep $interval;
my $stop = $timer->stop();
my $super_stop = $supervisor_timer->stop();

cmp_ok($timer->current(), 'eq', 'foo', 'current ok');
print "STOP IS " . $stop . "\n\n";
like($stop, qr/^1\.\d+/, 'precise to 1 second');
like($stop, qr/^1\.0\d+/, 'precise to 0.1 seconds');
like($stop, qr/^1\.00\d+/, 'precise to 0.01 seconds');
like($stop, qr/^1\.00[0-5]\d+/, 'precise to 0.005 seconds');
like($stop, qr/^1\.00[0-4]\d+/, 'precise to 0.004 seconds');

# accuracy
my $error = $super_stop - $stop;
like($error, qr/^0\.0\d+/, 'accurate to 0.1 second');
like($error, qr/^0\.00\d+/, 'accurate to 0.01 seconds');
like($error, qr/^0\.00[0-5]/, 'accurate to 0.005 seconds');
like($error, qr/^0\.000[0-5]/, 'accurate to 0.0005 seconds');


1;

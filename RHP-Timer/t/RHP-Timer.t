#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

my $pkg;

BEGIN {
    $pkg = 'RHP::Timer';
    use_ok($pkg);
}

can_ok($pkg, qw( new start stop current checkpoint last_interval));

my $supervisor_timer = $pkg->new();
my $timer            = $pkg->new();
isa_ok($timer, $pkg, 'constructor');

my $interval = 1;
$supervisor_timer->start('supervisor');
$timer->start('foo');
sleep $interval;
my $stop       = $timer->stop();
my $super_stop = $supervisor_timer->stop();

cmp_ok($timer->current(), 'eq', 'foo', 'current ok');
like($stop, qr/^1\.0\d+/,       'precise to 0.1 seconds');
like($stop, qr/^1\.00\d+/,      'precise to 0.01 seconds');
like($stop, qr/^1\.00[0-5]\d+/, 'precise to 0.005 seconds');

# accuracy
my $error = $super_stop - $stop;
like($error, qr/^0\.0\d+/,     'accurate to 0.1 second');
like($error, qr/^0\.00\d+/,    'accurate to 0.01 seconds');
like($error, qr/^0\.00[0-5]/,  'accurate to 0.005 seconds');


# checkpoint
$timer->start('checkpoint');
sleep 2;
my @checkpoint_data = $timer->checkpoint();
cmp_ok($checkpoint_data[0], 'eq', __PACKAGE__, 'package ok');
cmp_ok($checkpoint_data[1], 'eq', $0, 'filename ok');
cmp_ok($checkpoint_data[2], '==', 43, 'file line ok'); # line number-1???
cmp_ok($checkpoint_data[3], 'eq', 'checkpoint', 'correct timer name');
cmp_ok($checkpoint_data[4], '==', $timer->last_interval);

# last interval
like($timer->last_interval, qr/^2\.0\d+/, 'last_interval');

1;

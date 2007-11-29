#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

BEGIN {
    use_ok('SL::Model::Test');
}

my @dbs = `psql -l`;

print STDERR "DBs are " . join("\n", @dbs) . "\n";
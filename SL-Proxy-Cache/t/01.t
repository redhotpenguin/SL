#!/usr/local/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;                      # last test to print

BEGIN {
    use_ok('SL::Proxy::Cache');
}
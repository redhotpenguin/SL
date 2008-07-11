#!perl

use strict;
use warnings;


use Test::More tests => 2;
BEGIN { use_ok('SL::HTTP::Client') };

can_ok('SL::HTTP::Client', qw( get _build_response ) );

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('WebService::Yahoo::BOSS') };

can_ok( 'WebService::Yahoo::BOSS', qw( Web ));

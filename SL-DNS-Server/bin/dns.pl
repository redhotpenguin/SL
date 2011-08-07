#!/usr/bin/perl

use strict;
use warnings;

use SL::DNS::Server;

my $dns = SL::DNS::Server->new;

$dns->run;

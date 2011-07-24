#!/usr/bin/env perl

use strict;
use warnings;

use Config::SL;
use SL::DNS::Nameserver;

my $config = Config::SL->new;

my $ns = SL::DNS::Nameserver->new;

$ns->run;

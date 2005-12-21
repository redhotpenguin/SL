#!/usr/bin/env perl

use strict;
use warnings;

use SL::Maintd;

my $maint = SL::Maintd->new;

my %report;

$report{'tunnel'} = $maint->tunnel;

$report{'system'} = $maint->system;

require Data::Dumper;
print "##########################\n";
print "##### SL Maintd Report    \n";
print Data::Dumper::Dumper(\%report);
print "##########################\n";

1;

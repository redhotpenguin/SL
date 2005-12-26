#!/usr/bin/env perl

use strict;
use warnings;

use SL::Maintd;

my $maintd = SL::Maintd->new;

my %report;

foreach my $status qw( dns ping tunnel ) {
    $report{$status} = $maintd->$status;
    sleep 1;
}

require Data::Dumper;
print "##########################\n";
print "##### SL Maintd Report    \n";
print Data::Dumper::Dumper(\%report);
print "##########################\n";

1;

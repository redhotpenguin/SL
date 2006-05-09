use strict;
use warnings;

use DateTime;
use Test::More;
plan('no_plan');

# Start testing
use_ok('SL::CS::Model::Report');

my $today     = DateTime->now;
my $yesterday = DateTime->now->subtract( days => 1 );

my $report = eval { SL::CS::Model::Report->interval_by_ts() };
ok($@ =~ m/No start and end/, "Exception thrown when no date passed");

$report = SL::CS::Model::Report->interval_by_ts( { start => $yesterday, 
                                                 end => $today } );


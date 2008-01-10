#!perl

use strict;
use warnings;

# cron based payment generator
# look for previous payments with this account
# compute the number of ad views seen since then
# create a new payment

use Data::Dumper;
use SL::Config;
our $CFG = SL::Config->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

my $mode = shift || 'sandbox';

use SL::Model::App::Payment;

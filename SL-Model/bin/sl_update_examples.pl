#!perl -w

use strict;
use warnings;

# get to work

use SL::Model::App;

my @accounts = SL::Model::App->resultset('Account')->all;

my @example_ad_zones = SL::Model



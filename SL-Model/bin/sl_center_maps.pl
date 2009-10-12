#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Pg;
use Data::Dumper;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use SL::Model::App;
use SL::Model::App::Account;

my ($account) = SL::Model::App->resultset('Account')->search({ beta => 1  });

$account->center_the_map;

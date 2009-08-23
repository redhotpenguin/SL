#!/usr/bin/perl

use strict;
use warnings;

use SL::Map;

use SL::Model::App;

my ($account) = SL::Model::App->resultset('Account')->search({account_id => 1});;



SL::Map->map({ account => $account });

#!perl -w

use strict;
use warnings;

# get to work

use SL::Model::App;

my @accounts = SL::Model::App->resultset('Account')->all;

foreach my $account (@accounts) {

    next if $account->account_id == 1;

    warn( "updating example ad zones for account " . $account->name );
    $account->update_example_ad_zones;

}


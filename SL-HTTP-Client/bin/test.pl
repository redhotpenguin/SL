#!/usr/bin/perl

use strict;
use warnings;

use SL::HTTP::Client;

my $url = URI->new(shift)->as_string || die;

my $res = SL::HTTP::Client->get({
    host => '69.36.240.29',
    port => 9999,
    url => $url,
    headers_only => 1,
});

use Data::Dumper;
print STDERR Dumper($res) . "\n";

sleep 1;

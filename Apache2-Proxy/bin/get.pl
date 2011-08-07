#!/usr/bin/perl

use strict;
use warnings;

use Apache2::Proxy;

my $url = URI->new(shift)->as_string || die;

my $res = Apache2::Proxy->get({
    host => '69.36.240.29',
    port => 80,
    url => $url,
    headers_only => 1,
});

use Data::Dumper;
print STDERR Dumper($res->decoded_content) . "\n";

sleep 1;

#!/usr/bin/perl

use strict;
use warnings;

my $hostip = shift or die "$0 10.2.0.1\n";

use Time::HiRes qw(gettimeofday tv_interval);
use SL::Client::HTTP;

my $start = [gettimeofday];

$DB::single = 1;

my $url = 'http://www.silverliningnetworks.com/sl_secret_ping_button/00%2010%2032%2054%2076%2098';

my	@headers = (
'User-Agent', 'Wget/1.8.1',
'Accept', '*/*',
);


my $response = SL::Client::HTTP->get(
                                     url      => $url,
                                     host     => $hostip,
                                     port     => 80,
                                     headers  => \@headers,
                                    );

my $end = tv_interval($start, [gettimeofday]);

use Data::Dumper;

print Dumper($response); #if $verbose;

print sprintf("\nTime: %s\n", $end);


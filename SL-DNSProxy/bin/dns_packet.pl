#!/usr/bin/perl

use strict;
use warnings;

use Net::DNS::Packet;
use Net::DNS::RR;

my $packet = Net::DNS::Packet->new;

my $rr = Net::DNS::RR->new("foo.example.com.86400 A 10.0.2.3");

my $nscount = $packet->unique_push(update => $rr);
use Data::Dumper;
warn($nscount);
print Dumper($packet);

#!/usr/bin/perl

use strict;
use warnings;

use Net::DNS;

my $res = Net::DNS::Resolver->new(debug => 1);
$res->nameservers("127.0.0.1");

my $host = shift || 'www.redhotpenguin.com';

my $query = eval { $res->query($host, 'A'); };

use Data::Dumper;

warn Dumper($query || $@);

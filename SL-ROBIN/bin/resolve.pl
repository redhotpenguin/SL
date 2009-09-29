#!/usr/bin/perl

use strict;
use warnings;

 use Net::DNS;

my $file = shift or die;

my $res   = Net::DNS::Resolver->new;

my @outs;

my $fh;
open($fh, '<', $file) or die $!;
my $ct = do { local $/; <$fh> };
close($fh);

foreach my $host (split("\n", $ct)) {

	chomp($host);
	if ($host !~ m/[a-zA-Z]/) {
		push @outs, $host;  # this is an ip or cidr
	}

	my $query = $res->search($host);

if ($query) {
	foreach my $rr ($query->answer) {
                 next unless $rr->type eq "A";
                 print STDERR $rr->address, "\n";
		push @outs, $rr->address
             }
} else {
             warn "query failed: ", $res->errorstring, "\n";
}
}

open($fh, '>', './dns.txt') or die;
print $fh join("\n", @outs);
close($fh);

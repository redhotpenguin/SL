#!perl

use strict;
use warnings;

open(FH, "<", "fw.txt") or die $!;
while(<FH>) {
	chomp($_);
	my $cmd = $_;
	system("$cmd") == 0 or warn $!;
}

1;

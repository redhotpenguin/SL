#!/usr/bin/perl

use strict;
use warnings;

open(FH, '>out.txt') or die $!;

foreach my $part ( qw( AM PM ) ) {
  foreach my $hour (1..11) {
    foreach my $five ( 0..11 ) {

      my $time = sprintf('%d:%02d %s', $hour, $five * 5, $part);
      my $users = int(rand(100));
      my $up = $users * int(rand(10));
      my $down = $users * int(rand(100));

      my $line = join(',', $time, $down, $up, $users);
      print FH $line . "\n";
    }
  }
}

close(FH);

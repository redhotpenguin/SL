#!/usr/bin/perl

use strict;
use warnings;

use Net::DNS;

use Data::Dumper;

  my $hostname = 'mail.google.com';

  our %results;

  our $res = Net::DNS::Resolver->new(
      #nameservers => [qw(208.67.220.220)],
      nameservers => [qw(208.67.220.220 207.69.188.172 68.94.156.1)],
      recurse     => 0,      
      debug       => 1,
  );

  my $query = $res->query($hostname);  

  #my $query = $res->query('mail.google.com');

  if ($query) {
     foreach my $rr ($query->answer) {
          next unless $rr->type eq "A";
          print $rr->address, "\n";
          my $ip = $rr->address;
          print "IP address = $ip \n";         

          push @{$results{$hostname}}, $ip;         

       }
  }  else {
       warn "query failed: ", $res->errorstring, "\n";
  }


  print %results . "\n";

  my $key;
  my $value;

  while (($key, $value) = each(%results)){

  print $key.", ".$value."\n";
  }

  print Dumper(\%results);




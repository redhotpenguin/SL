#!/usr/bin/perl

use strict;
use warnings;

use Net::DNS;

use Data::Dumper;

  my @hostname_list = qw(mail.google.com ad.afy11.net);


  our @nameservers_list = qw(207.69.188.172 207.69.188.171);

  our $nameserver;


  my $hostname;

  our %results;


  foreach  $hostname (@hostname_list) {

  foreach $nameserver (@nameservers_list) {  

  our $res = Net::DNS::Resolver->new(
      
      nameservers => [$nameserver],
      recurse     => 0,      
      debug       => 1,
  );

  my $query = $res->query($hostname);  
  

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


  }

  }

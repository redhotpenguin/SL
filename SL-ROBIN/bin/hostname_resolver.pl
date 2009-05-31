#!/usr/bin/perl

use strict;
use warnings;

use Net::DNS;

use Data::Dumper;

  my @skips_hosts_array;

  my @hostname_list_test;

  my $hostname_test; 

  unless (open(MYFILE, "skips_hosts.txt")){

  die ("cannot open input file skips_hosts.txt\n");

  }

  @skips_hosts_array = <MYFILE>;

  chomp @skips_hosts_array;


  foreach  $hostname_test (@skips_hosts_array) {

  if ($hostname_test =~ m/com/ or $hostname_test =~ m/net/) {

     push(@hostname_list_test, $hostname_test);

  }
  }

  print " HOSTNAME_LIST_TEST ARRAY \n ";

  print @hostname_list_test;

  print "\n";



  #my @hostname_list = qw(112.2o7.net mail.google.com ad.afy11.net 0.channel13.facebook.com 02268001106.channel09.facebook.com ad-yt-bfp.doubleclick.net);

  my @hostname_list = @hostname_list_test;
 

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

  
  }

  }

  my $key;
  my $value;

  while (($key, $value) = each(%results)){

  print $key.", ".$value."\n";
  }

  print Dumper(\%results);


#!/usr/bin/env perl

use strict;
use warnings;

use CGI qw/:standard/;
use Net::Telnet ();

my $host = 'localhost';
my $port = '30681';
my $status;

my $t = eval { 
    Net::Telnet->new( Timeout => 10,
                          Port => $port,
                          Host => $host );
                  };
if ( $@ && $@ =~ m/Connection refused/ ) {
    $status = 0;
} else {
    $status = 1;
}
my $cgi = CGI->new;
print $cgi->header(-type => 'text/plain') , $status;

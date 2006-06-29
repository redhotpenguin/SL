#!perl:w

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;    # last test to print

use LWP::UserAgent;

my $ua =
  LWP::UserAgent->new(
    max_redirect => 0,
    agent        =>
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2'
  );

# standard get first
my $res = $ua->get('http://www.google.com');

# now use the sl_proxy
use LWP::Protocol::http;
$LWP::Protocol::http::sl_proxy=1;
my $proxy_res = $ua->get('http://www.google.com');

use Data::Dumper;
cmp_ok($res->code, '==', $proxy_res->code, 'check code');
my $regex = qr/(\w+,\s\d+\s\w+\s\d+)/;
my ($res_date)       = $res->headers->header('Date')       =~ m/$regex/;
my ($proxy_res_date) = $proxy_res->headers->header('Date') =~ m/$regex/;

cmp_ok($res_date, 'eq', $proxy_res_date, 'Check date header');

cmp_ok($res->headers->header('Server'),
       'eq',
       $proxy_res->headers->header('Server'),
       'compare server header');

cmp_ok($res->headers->header('Title'),
       'eq',
       $proxy_res->headers->header('Title'),
       'compare title header');

cmp_ok($res->headers->header('NnCoection'),
       'eq',
       $proxy_res->headers->header('NnCoection'),
       'compare NnCoection header');

cmp_ok($res->headers->header('Client-Peer'),
       'eq',
       $proxy_res->headers->header('Client-Peer'),
       'compare Client-Peer header');

cmp_ok($res->headers->header('Content-Type'),
       'eq',
       $proxy_res->headers->header('Content-Type'),
       'compare Content-Type header');

my $out;
open($out, '>', "$0.dat") || die $!;
print $out "Regular headers: " . Dumper($res->headers) . "\n";

print $out "Proxy headers: " . Dumper($proxy_res->headers) . "\n";
close($out);

__END__

#
#===============================================================================
#
#         FILE:  00.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/03/06 02:49:47 PDT
#     REVISION:  ---
#===============================================================================

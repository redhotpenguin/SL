#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::HTTP::Client;
$SL::HTTP::Client::Test = 1;

my $remote_host = 'www.kauaivacationhideaway.com';
my $url         = "http://$remote_host/";

my %args = (
    url     => $url,
    host    => $host,
    port    => $port,
);

my $proxy_res = SL::HTTP::Client->get( \%args );
my $res = SL::HTTP::Client->get( { %args, port => 80, host => $remote_host } );

my @headers = qw( date content-length transfer-encoding );
$" = '|';
foreach my $header ( keys %{$res->headers} ) {
  next if lc($header) =~ m/@headers/;
  next if lc($header) eq 'content-length';
  print STDERR "Comparing header $header\n";
  cmp_ok($res->headers->header($header), 'eq', $proxy_res->headers->header($header));

}

cmp_ok($proxy_res->code, '==', $res->code, 'check 200 rc');


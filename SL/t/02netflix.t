#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my $remote_host = 'www.netflix.com';
my $url         = "http://$remote_host/";

my %args = (
    url     => $url,
    host    => $host,
    port    => $port,
);

my $proxy_res = SL::Client::HTTP->get( \%args );
my $res = SL::Client::HTTP->get( { %args, port => 80, host => $remote_host } );

foreach my $header ( keys %{$res->headers} ) {
  print STDERR "Comparing header $header\n";
}

diag("netflix sends us two redirects to test our cookies, so play along...");

cmp_ok($proxy_res->code, '==', $res->code, 'check 302 rc');
cmp_ok($proxy_res->headers->header('location'), 'eq', $res->headers->header('location'), 'netflix.com in 302');
cmp_ok($proxy_res->headers->header('server'), 'eq', $res->headers->header('server'), 'server header same');


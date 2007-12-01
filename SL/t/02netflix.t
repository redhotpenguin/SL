#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my $remote_host = 'www.netflix.com';
my $url         = "http://$remote_host/";
my $user_agent  =
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2';

my %args = (
    url     => $url,
    host    => $host,
    port    => $port,
    headers => { 'User-Agent' => $user_agent }
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
my $num_proxy_cookies = () = $proxy_res->headers->header('set-cookie');
cmp_ok($num_proxy_cookies, '==', 6, 'six proxy cookies');

diag("now handle the second redirect to home page");
$proxy_res = SL::Client::HTTP->get( { %args, url => $proxy_res->headers->header('location'), } );
cmp_ok($proxy_res->code, '==', 200, 'check 200 rc');
cmp_ok($proxy_res->headers->header('content-encoding'), 'eq', 'gzip', 'check gzip encoding');
$num_proxy_cookies = () = $proxy_res->headers->header('set-cookie');
cmp_ok($num_proxy_cookies, '==', 7, 'proxy cookies');


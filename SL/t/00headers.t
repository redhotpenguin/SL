#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;

use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::HTTP::Client;
$SL::HTTP::Client::Test = 1;

my $mac = '00:17:f2:43:38:bd';
my $ping_url = "http://localhost/sl_secret_ping_button/$mac";

my %args = (
    url     => $ping_url,
    host    => $host,
    port    => $port,
);

# ping the server
my $res = SL::HTTP::Client->get( \%args);
cmp_ok($res->code, '==', 200, 'ping 200');

my $remote_host = 'www.google.com';
my $url         = "http://$remote_host/";

%args = (
    url     => $url,
    host    => $host,
    port    => $port,
);

diag("grabbing $url through proxy to check for headers");
my $proxy_res = SL::HTTP::Client->get( \%args );

diag("grabbing $url to check for headers");
$res = SL::HTTP::Client->get( { %args, port => 80, host => $remote_host } );

$DB::single = 1;
cmp_ok( $res->code, '==', $proxy_res->code, 'check code' );
my $regex = qr/(\w+,\s\d+\s\w+\s\d+)/;
my ($res_date)       = $res->headers->header('Date')       =~ m/$regex/;
my ($proxy_res_date) = $proxy_res->headers->header('Date') =~ m/$regex/;

cmp_ok( $res_date, 'eq', $proxy_res_date, 'Check date header' );

cmp_ok(
    $res->headers->header('Title'),
    'eq',
    $proxy_res->headers->header('Title'),
    'compare title header'
);

cmp_ok(
    $res->headers->header('NnCoection'),
    'eq',
    $proxy_res->headers->header('NnCoection'),
    'compare NnCoection header'
);

cmp_ok(
    $res->headers->header('Content-Type'),
    'eq',
    $proxy_res->headers->header('Content-Type'),
    'compare Content-Type header'
);

cmp_ok(
    $proxy_res->headers->header('Server'),
    'eq',
    $res->headers->header('Server'),
    'compare server header'
);

cmp_ok(
    length($proxy_res->headers->header('Set-Cookie')),
    '==',
    length($res->headers->header('Set-Cookie')),
    'compare cookie header'
);

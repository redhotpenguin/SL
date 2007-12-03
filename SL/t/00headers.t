#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;    # last test to print

use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my $remote_host = 'www.google.com';
my $url         = "http://$remote_host/";

my %args = (
    url     => $url,
    host    => $host,
    port    => $port,
);

my $proxy_res = SL::Client::HTTP->get( \%args );

my $res = SL::Client::HTTP->get( { %args, port => 80, host => $remote_host } );

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


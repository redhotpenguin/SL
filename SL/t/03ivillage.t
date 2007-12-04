#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;    # last test to print

use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my $remote_host   = 'www.ivillage.com';
my $url         = "http://$remote_host/";

my %args = (
    url     => $url,
    host    => $host,
    port    => $port,
);

my $proxy_res = SL::Client::HTTP->get( \%args );
my $res = SL::Client::HTTP->get( { %args, port => 80, host => $remote_host } );

diag('this site sends extra newlines inside headers so test that we can handle it');
cmp_ok($proxy_res->code, '==', $res->code, 'check response code');
# some sort of test here to make sure that the headers don't contain newlines

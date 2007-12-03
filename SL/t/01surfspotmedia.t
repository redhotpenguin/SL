#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;


use SL::Config;
my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my $remote_host = 'surfspotmedia.com';
my $url         = "http://$remote_host/";

my %args = (
    url     => $url,
    host    => $host,
    port    => $port,
);

my $proxy_res = SL::Client::HTTP->get( \%args );
cmp_ok($proxy_res->code, '==', 200, 'check 200 rc');

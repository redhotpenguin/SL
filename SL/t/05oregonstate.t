#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;    # last test to print

use SL::Config;

my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my %args = (
    host => $host,
    port => $port,
);

my $url   = 'http://coed.bus.oregonstate.edu/FSSearch.aspx';

my $res = SL::Client::HTTP->get( { %args, url => $url, } );

cmp_ok($res->code, '==', 401, 'check 401 rc');

diag("check the www-authenticate headers");
my @auth_headers = $res->header('www-authenticate');
cmp_ok(scalar(@auth_headers), '==', 3, 'three www-authenticate headers');
my @header_vals = qw( Negotiate NTLM);
push @header_vals, 'Basic realm="coed.bus.oregonstate.edu"';
foreach my $auth_header ( @auth_headers ) {
	ok((grep { $auth_header eq $_ } @header_vals), 'auth header matches');
}

diag("check the x-... headers");
cmp_ok($res->header('x-powered-by'), 'eq', 'ASP.NET', 'x-powered-by');
cmp_ok($res->header('X-AspNet-Version'), 'eq', '2.0.50727', 'x-power...');

diag("content-type header");
cmp_ok($res->header('content-type'), 'eq', 'text/html'	,'content_type ok');


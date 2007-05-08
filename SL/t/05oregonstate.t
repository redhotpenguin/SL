#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;    # last test to print
use LWP::UserAgent;

use LWP::Protocol::http;      # needed for our override
$LWP::Protocol::http::sl_proxy = 1;
my $url   = 'http://coed.bus.oregonstate.edu/FSSearch.aspx';

use SL::Test::Mechanize;
my $mech = SL::Test::Mechanize->new;

$mech->get($url);
cmp_ok($mech->res->code, '==', 401, 'check 401 rc');

diag("check the www-authenticate headers");
my @auth_headers = $mech->res->header('www-authenticate');
cmp_ok(scalar(@auth_headers), '==', 3, 'three www-authenticate headers');
my @header_vals = qw( Negotiate NTLM);
push @header_vals, 'Basic realm="coed.bus.oregonstate.edu"';
foreach my $auth_header ( @auth_headers ) {
	ok((grep { $auth_header eq $_ } @header_vals), 'auth header matches');
}

diag("check the x-... headers");
cmp_ok($mech->res->header('x-powered-by'), 'eq', 'ASP.NET', 'x-powered-by');
cmp_ok($mech->res->header('X-AspNet-Version'), 'eq', '2.0.50727', 'x-power...');

diag("content-type header");
cmp_ok($mech->res->header('content-type'), 'eq', 'text/html; charset=iso-8859-1'	,'content_type ok');

__END__

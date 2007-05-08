#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;    # last test to print
use LWP::UserAgent;

use LWP::Protocol::http;      # needed for our override
$LWP::Protocol::http::sl_proxy = 1;
my $url   = 'http://www.netflix.com';

use SL::Test::Mechanize;
my $mech = SL::Test::Mechanize->new;

diag("netflix sends us two redirects to test our cookies, so play along...");
$mech->get($url);
cmp_ok($mech->res->code, '==', 302, 'check 302 rc');
ok($mech->res->header('location') =~ m{netflix\.com}, 'netflix.com in 302');
ok($mech->res->header('set-cookie'), 'set-cookie header in redirect');

diag("now handle the second redirect");
$mech->get($mech->res->header('location'));
cmp_ok($mech->res->code, '==', 302, 'check 302 rc');
ok($mech->res->header('location') =~ m{netflix\.com\/default}i, 
	'redirect to netflix home page');
ok($mech->res->header('set-cookie'), 'set-cookie header in redirect');

$mech->get($mech->res->header('location'));
cmp_ok($mech->res->code, '==', 200, 'check 200 rc');
ok($mech->res->title =~ m/welcome to netflix/i, 'check title');
ok($mech->res->content =~ m/media center/i, 'check page content');
my @cookies = $mech->res->headers->header('set-cookie');
cmp_ok(scalar(@cookies), '==', '10', 'check that nine cookies were returned');

__END__

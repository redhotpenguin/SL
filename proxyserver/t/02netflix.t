#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;    # last test to print
use LWP::UserAgent;

use HTTP::Cookies;
my $cookie_file = '/tmp/foocookie.dat';
unlink $cookie_file if -e $cookie_file;
my $cookie_jar = HTTP::Cookies->new(
	file => $cookie_file,
	autosave => 1,
);

my %args = (
	cookie_jar => {},#$cookie_jar,
	#cookie_jar => $cookie_jar,
	max_redirect => 0,
    agent        =>
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2'
);
use LWP::Protocol::http;      # needed for our override
$LWP::Protocol::http::sl_proxy = 1;
use WWW::Mechanize;
my $mech = WWW::Mechanize->new(%args);
#$mech->delete_header('Connection');
#$mech->add_header('Connection' => 'keep-alive');
#$mech->delete_header('Keep-Alive');
#$mech->add_header('Keep-Alive' => '300');
$mech->delete_header('Accept-Encoding');
$mech->add_header('Accept-Encoding' => 'gzip,deflate');
$mech->delete_header('Accept-Charset');
$mech->add_header('Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7');
$mech->delete_header('Accept-Language');
$mech->add_header('Accept-Language' => 'en-us;q=0.5');
$mech->delete_header('Accept');
$mech->add_header('Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5');
my $url   = 'http://www.netflix.com';

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
ok($mech->res->content =~ m/use of the netflix service/i, 'check page content');
my @cookies = $mech->res->headers->header('set-cookie');
cmp_ok(scalar(@cookies), '==', '9', 'check that nine cookies were returned');

__END__

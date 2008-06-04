#!perl

use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SL-BrowserUtil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
my $pkg;

BEGIN {
    $pkg = 'SL::BrowserUtil';
    use_ok($pkg);
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $browser;
my $user_agent =
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2';
$browser = $pkg->is_a_browser( $user_agent);
cmp_ok($browser, 'eq', 'mozilla','firefox 1.5 is a browser');

$user_agent = 'Mozilla/4.0 (compatible; MSIE 5.0; Windows 2000) Opera 6.0 [en]';
$browser = $pkg->is_a_browser( $user_agent);
cmp_ok($browser, 'eq', 'opera', 'opera 6');

$user_agent = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows ME) Opera 7.11  [en]';
$browser = $pkg->is_a_browser( $user_agent);
cmp_ok($browser, 'eq', 'opera', 'opera 7.11 en');

$user_agent = "Opera/7.54 (Windows NT 5.1; U)  [pl]";
ok($browser = $pkg->is_a_browser( $user_agent), 'opera 7.54 pl');
cmp_ok($browser, 'eq', 'opera');

$user_agent = "Opera/9.00 (Windows NT 5.1; U; en)";
ok($browser = $pkg->is_a_browser( $user_agent), 'opera 9');
cmp_ok($browser, 'eq', 'opera');

$user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418.9 (KHTML, like Gecko) Safari/419.3";
ok($browser = $pkg->is_a_browser( $user_agent), 'safari/419.3');

$user_agent = 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.8.1 (KHTML, like Gecko) Safari/312.6';
ok($browser = $pkg->is_a_browser( $user_agent), 'safari/312.6');

$user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/85.8.5 (KHTML, like Gecko) Safari/85.8.1";
ok($browser = $pkg->is_a_browser( $user_agent), 'safari/85.8.1');

$user_agent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; InfoPath.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)";
ok($browser = $pkg->is_a_browser( $user_agent), 'IE 6.0  NT 5.1');

$user_agent = "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Arcor 5.005; .NET CLR 1.1.4322; .NET CLR 2.0.50727)";
ok($browser = $pkg->is_a_browser( $user_agent), 'MSIE 7.0 Arcor 5.005');

$user_agent = "Mozilla/5.0 (Danger hiptop 3.4; U; AvantGo 3.2)";
ok($browser = $pkg->is_a_browser( $user_agent), 'sidekick 3 is a browser');

$user_agent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.1.10) Gecko/20071115 Firefox/2.0.0.10";
ok($browser = $pkg->is_a_browser( $user_agent), 'firefox 2 is a browser');

$user_agent = "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A102 Safari/419.3";

ok($browser = $pkg->is_a_browser( $user_agent), 'iphone is a browser');


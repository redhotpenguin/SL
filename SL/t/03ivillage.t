#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;    # last test to print
use LWP::UserAgent;

use LWP::Protocol::http;      # needed for our override
$LWP::Protocol::http::sl_proxy = 1;
my $url   = 'http://www.ivillage.com';

use SL::Test::Mechanize;
my $mech = SL::Test::Mechanize->new;

$mech->get($url);
cmp_ok($mech->res->code, '==', 200, 'check 200 rc');
ok($mech->success, 'successful result');
# some sort of test here to make sure that the headers don't contain newlines

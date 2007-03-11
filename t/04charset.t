#!perl

# SL used to send everything out without a character-set, but now it
# should set the character-set correctly and only output correct data
# for that character-set.  This test runs through some URLs and checks
# that they get a non-UTF-8 character set and that the page data is
# correct.

use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);
use LWP::UserAgent;
use Encode qw(decode);
use HTTP::Headers::Util;

use LWP::Protocol::http;    # needed for our override
$LWP::Protocol::http::sl_proxy = 1;

use LWP::UserAgent;

# use LWP rather than Mech - mech papers over the missing-charset bug
# we're trying to examine
my $ua =
  LWP::UserAgent->new(
    max_redirect => 0,
    agent        =>
'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.4) Gecko/20060508 Firefox/1.5.0.4',
  );

# a small selection of sites with known character sets - add more here
# if/when character-encoding bugs surface
my @tests = (
         ['http://www.ebay.com/',     'iso-8859-1'],      # ISO-8859-1
         ['http://www.bandai.co.jp/', 'shift_jis'],       # Japanese
         ['http://www.mlahanas.de/',  'iso-8859-1'],      # lots of high-ASCII
         ['http://www.inn.co.il/',    'windows-1255'],    # Hebrew
            );

foreach my $test (@tests) {
    my ($url, $expected_charset) = @$test;

    my $response = $ua->get($url);
    cmp_ok($response->code, '==', 200, 'check 200 rc');

    # make sure it actually got ads
    like($response->content, qr/redhotpenguin.com/,
         "request to $url got ads");

    # pull out the character set from the content-type header
    my $charset;
    my @ct =
      HTTP::Headers::Util::split_header_words(
                                           $response->header("Content-Type"));
    if (@ct) {
        my (undef, undef, %ct_param) = @{$ct[-1]};
        $charset = $ct_param{charset};
    }
    ok( $charset, 
        "request to $url returned a charset: '" . ($charset || 'undef') . "'"
      );
    is(lc($charset), $expected_charset, "$url should be $expected_charset");

    # check that response data is valid for charset
    if ($charset) {
        eval { decode($charset, $response->content, Encode::FB_CROAK); };
        ok(not($@), "reponse from $url is valid $charset");
    }
}

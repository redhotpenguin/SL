#!perl

# SL used to send everything out without a character-set, but now it
# should set the character-set correctly and only output correct data
# for that character-set.  This test runs through some URLs and checks
# that they get a non-UTF-8 character set and that the page data is
# correct.

use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);
use Encode qw(decode);
use HTTP::Headers::Util;
use SL::Config;

my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::HTTP::Client;
$SL::HTTP::Client = 1;

my %args = (
    host => $host,
    port => $port,
);

# a small selection of sites with known character sets - add more here
# if/when character-encoding bugs surface
my @tests = (
    [ 'http://www.bandai.co.jp/', 'shift_jis' ],       # Japanese
    [ 'http://www.ebay.com/',     'iso-8859-1' ],      # ISO-8859-1
    [ 'http://www.mlahanas.de/',  'iso-8859-1' ],      # lots of high-ASCII
    [ 'http://www.inn.co.il/',    'windows-1255' ],    # Hebrew
);

SKIP: {
    skip 'unable to get charset in content-type header yet', 8
      unless 0;

    foreach my $test (@tests) {
        my ( $url, $expected_charset ) = @$test;

        my $response = SL::HTTP::Client->get( { %args, url => $url, } );

        # pull out the character set from the content-type header
        my $charset;
        my @ct =
          HTTP::Headers::Util::split_header_words(
            $response->header("Content-Type") );
        if (@ct) {
            my ( undef, undef, %ct_param ) = @{ $ct[-1] };
            $charset = $ct_param{charset};
        }
        ok( $charset,
            "request to $url returned a charset: '"
              . ( $charset || 'undef' )
              . "'" );
        is( lc($charset), $expected_charset,
            "$url should be $expected_charset" );

        # check that response data is valid for charset
        if ($charset) {
            eval { decode( $charset, $response->content, Encode::FB_CROAK ); };
            ok( not($@), "reponse from $url is valid $charset" );
        }
    }

}

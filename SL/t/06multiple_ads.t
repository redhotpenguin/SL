#!perl

# SL should only serve ads on the "main" request.  That is, if a request is
# made to a http://www.foo.com, an ad should be served on the initial response,
# but the application should avoid attempting to serve an ad on any requests
# made by the user agent to fulfill that initial request.  That includes images,
# embedded javascripts, and frame source.  This test runs through some urls
# and emulates browser subrequests and checks for the lack of ads on subrequests

use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

use HTML::TokeParser;
use URI;

use SL::Config;

my $CONFIG = SL::Config->new;
my ( $host, $port ) = split ( /:/, $CONFIG->sl_proxy_apache_listen );

use SL::Client::HTTP;

my %args = (
    host => $host,
    port => $port,
);


# (excluding http://www.derbyhillfarm.com - the broken HTML (no body)
# there seems to be breaking the ad-inclusion code)

# FIX: none of these sites have sub-requests we can parse out!
my @urls = qw(
  http://www.ebay.com/
  );

foreach my $url (@urls) {
    my $response = SL::Client::HTTP->get( { %args, url => $url, } );

    cmp_ok($response->code, '==', 200, 'check 200 rc');

    # ... check for the presence of an ad
    ok($response->decoded_content =~ m/sl_textad_text/i,
        "check for silverlining ad on $url");

    _test_subrequests($response);
}

sub _test_subrequests {
  my $res = shift;
    my @subreq_urls;

    # borrow some methods from SL::Model::Subrequest
    my $content = $res->decoded_content;
    my $p = HTML::TokeParser->new(\$content) || die "Error!";
    while (my $token = $p->get_tag('iframe', 'frame')) {
        my $tag   = $token->[0];
        my $attrs = $token->[1];
        my $url   = $attrs->{src};
        next unless $url;

        unless ($url =~ m{^http://\w+}) {
            $url = URI->new_abs($url, URI->new($res->uri))->as_string;
        }

        # check that the sub-req doesn't have ads
        my $response = SL::Client::HTTP->get( { %args, url => $url, } );
        cmp_ok($response->code, '==', 200, 'check 200 rc');
        ok($response->decoded_content !~ m{sl_ad_text}i,
            "no silverlining content for $url");
    }
}

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
use LWP::UserAgent;

use LWP::Protocol::http;      # needed for our override
$LWP::Protocol::http::sl_proxy = 1;

use HTML::TokeParser;
use SL::Test::Mechanize;
my $mech = SL::Test::Mechanize->new;

my @urls = qw( 
	http://www.derbyhillfarm.com
	http://my.oregonstate.edu
	http://www.ebay.com
	http://myspace.com/theexpertmusic
);

foreach my $url (@urls) {
	$mech->get($url);
	ok($mech->success, 'successful request');
	cmp_ok($mech->res->code, '==', 200, 'check 200 rc');
	# ... check for the presence of an ad
	ok($mech->res->content =~ m/SilverLining/i, 'check for silverlining ad');
	_test_subrequests($mech);
}

sub _test_subrequests {
	my $mech = shift;

	my @subreq_urls;
	# borrow some methods from SL::Util
	my $content = $mech->res->content;
	my $p = HTML::TokeParser->new( \$content ) || die "Error!";
	while ( my $token = $p->get_tag('src') ) {
		my $tag = $token->[0];
		my $attrs = $token->[1];
		my $url = $attrs->{href};
		next unless $url;
		
		unless ($url =~ m{^http://\w+}) {
			my $uri = URI->new($mech->uri);
			$url = 'http://' . $uri->host . $url;
		}
		push @subreq_urls, $url;
	}

	foreach my $subreq_url (@subreq_urls) {
		$mech->get($subreq_url); # hopefully this uses referer correctly
		ok($mech->is_success);
		cmp_ok($mech->res->code, '==', 200, 'check 200 rc');
		ok(! $mech->res->header('x-silverlining'), 'no silverlining header');
		ok($mech->res->content !~ m{silverlining}i, 'no silverlining content');
	}
}

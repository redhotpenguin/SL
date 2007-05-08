use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

use constant PING_IP => '64.151.90.20';

my $pkg;

BEGIN {
    $pkg = 'SL::UserAgent';
    use_ok($pkg);
}

can_ok($pkg, qw( _browser_redirect request new ));

my $ua = $pkg->new();
isa_ok($ua, $pkg, 'constructor ok');

eval { $ua->request('huzzah!') };
like($@, qr/oops/, 'oops, bad monkey');

SKIP: {
    my $num_skip = 1;
    my $has_http_request = eval { require HTTP::Request };
    skip "HTTP::Request not found, skipping", $num_skip
      unless $has_http_request;

    my $has_net_ping = eval { require Net::Ping };
    skip "Net::Ping not found, skipping", $num_skip
      unless $has_net_ping;

    my $has_ping = Net::Ping->new->ping(PING_IP);
    skip "No ping!", $num_skip unless $has_ping;

    my $request = HTTP::Request->new(
        'GET' => "http://www.google.com/",
        [
         'User-Agent',
'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2'
        ]
    );
    my $response = $ua->request($request);
    isa_ok($response, 'HTTP::Response');
	
	# try our own flavor, this should NOT work cause LWP will croak
	bless $request, 'SL::HTTP::Request';
    $response = eval { $ua->request($request) };
	like($@, qr/oops, not an http/, 'non http::request object barfed');
}


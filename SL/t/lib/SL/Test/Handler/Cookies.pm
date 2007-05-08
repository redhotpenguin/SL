package SL::Test::Handler::Cookies;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK );
use Apache2::RequestRec;
use Apache2::Cookie;
use Apache2::Log;

sub one_cookie {
	my ($class,$r) = @_;

	my $cookie = Apache2::Cookie->new($r,
		-name => 'sl',
		-value => 'cookie_one',
		-expires => '+1H',
		-domain => '.one.cookie',
		-path => '/',
		-secure => 0,
	);
	$r->log->debug("Cookie is " . $cookie->as_string);
	$cookie->bake($r);
	$r->content_type('text/plain');
	return Apache2::Const::OK;
}

1;
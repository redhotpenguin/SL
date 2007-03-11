package SL::UserAgent;

use strict;
use warnings;

use Apache2::Const -compile => qw(LOG_DEBUG LOG_ERR LOG_INFO);
use Apache2::Log         ();
use Apache2::RequestUtil ();
use Apache2::ServerRec   ();
use LWP::UserAgent       ();
use HTTP::Cookies		 ();
use Data::Dumper        qw( Dumper );

sub new {
    my ($self, $r) = @_;

	my $ua = LWP::UserAgent->new(max_redirect => 0);
    #######################################
    # Mimic the user's user agent
	#my $origin_ua = $r->pnotes('ua');
	#if (defined $origin_ua && length $origin_ua) {
	#    $ua->agent($origin_ua);
	#}

    #######################################
    # Cookies
    $ua->cookie_jar( HTTP::Cookies->new());

    # Turn off head-parsing.  With this feature on http-equiv headers
    # get promoted into first-class headers, which interferes with the
    # browser's ability to ignore them.
    $ua->parse_head(0);
   
    my $url = $r->pnotes('url');
    $r->log->debug("$$ Created user agent for $url, ua => ", Dumper($ua));
    return $ua;
}

1;

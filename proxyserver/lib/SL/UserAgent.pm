package SL::UserAgent;

use strict;
use warnings;

use Apache2::Const -compile => qw(LOG_DEBUG LOG_ERR LOG_INFO);
use Apache2::Log         ();
use Apache2::RequestUtil ();
use Apache2::ServerRec   ();

my $ua;
BEGIN {
    require LWP::UserAgent;
	$ua = LWP::UserAgent->new(max_redirect => 0);
}

sub new {
    my ($self, $r) = @_;

    #######################################
    # Mimic the user's user agent
    my $origin_ua = $r->pnotes('ua');
    if (defined $origin_ua && length $origin_ua) {
        $ua->agent($origin_ua);
    }

    #######################################
    # Cookies
    require HTTP::Cookies;
    $ua->cookie_jar( HTTP::Cookies->new());
   
    my $url = $r->pnotes('url');
    ($r->server->loglevel == Apache2::Const::LOG_DEBUG)
      && require Data::Dumper
      && $r->log->debug("$$ Created user agent for $url, ua => ",
                        Data::Dumper::Dumper($ua));
    return $ua;
}

1;

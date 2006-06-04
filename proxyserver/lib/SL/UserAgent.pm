package SL::UserAgent;

use strict;
use warnings;

use Apache2::Log;
use Apache2::RequestUtil;
use Data::Dumper;

sub new {
    my ( $self, $r ) = @_;

    require LWP::UserAgent;
    
    # Mimic the user's user agent
    #
    my $ua        = LWP::UserAgent->new( max_redirect => 0 );
    my $origin_ua = $r->pnotes('ua');
    if ( defined $origin_ua && length $origin_ua ) {
        $ua->agent($origin_ua);
    }
    
    #######################################
    # Cookies
    #
    require HTTP::Cookies;
    $ua->cookie_jar( HTTP::Cookies->new());# file => "/tmp/foocookies$$" ) );
   
    my $url = $r->pnotes('url');
    $r->log->debug("$$ Created user agent for $url, ua => ", Dumper($ua));
    return $ua;
}

1;

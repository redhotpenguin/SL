package SL::UserAgent;

use strict;
use warnings;

sub new {
    my ( $self, $r ) = @_;
 
    require LWP::UserAgent;
    # Mimic the user's user agent
    #
    my $ua        = LWP::UserAgent->new();
    my $origin_ua = $r->headers_in->{'user-agent'};
    if ( defined $origin_ua && length $origin_ua ) {
        $ua->agent($origin_ua);
    }
    
    #######################################
    # Cookies
    #
    require HTTP::Cookies;
    $ua->cookie_jar( HTTP::Cookies->new( file => "/tmp/foocookies" ) );
    return $ua;
}

1;

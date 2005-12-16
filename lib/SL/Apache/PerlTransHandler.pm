package SL::Apache::PerlTransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

our $ext_regex;
our $ua_regex;

BEGIN {
    require Regexp::Assemble;
SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
SetEnvIfNoCase Request_URI \.(?:exe|t?gz|zip|bz2|sit|rar)
    my @extensions = qw( 
        ad bz2 css doc exe fla gif gz ico jpeg jpg pdf png ppt rar sit 
        tgz txt zip );
    
    $ext_regex = Regexp::Assemble->new;
    $ext_regex->add(@extensions);
    print STDERR "Regex for static content match is ", $ext_regex->re, "\n";

    my @user_agents = qw( Firefox IE Opera Mozilla Safari Links Lynx);
    $ua_regex = Regexp::Assemble->new;
    $ua_regex->add(@user_agents);
    print STDERR "Regex for user agents is ", $ua_regex->re, "\n";
}

use Apache2::Const;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::ServerRec;
use Apache2::ServerUtil;
use Data::Dumper qw( Dumper );
use SL::Apache;
use SL::Cache;
use SL::Util;

our $proxy;
BEGIN {
    my $server = Apache2::ServerUtil->server;
    my $port = $server->port;
    ( $port == '9000' ) ? $proxy = 'perlbal' : $proxy = 'mod_proxy';
    print "Using $proxy for proxy serving\n";
}

sub proxy_request {
    my $r = shift;
    if ( $proxy eq 'perlbal' ) {
        return &perlbal($r);
    } elsif ( $proxy eq 'mod_proxy') {
        return &mod_proxy($r);
    }
}

sub static_content_uri {
    my $url = shift;
    if ( $url =~ m/\.$ext_regex$/ ) {
        return 1;
    }
}

sub handler {
    my $r = shift;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->log->debug("Invoking Transhandler for url $url"); 
   
    if ( _not_a_browser($r) ) {
        $r->log->info("Request made by non-browser for $url");
        return &proxy_request( $r );
    }    
    if ( $r->method eq 'GET' ) {
        if ( static_content_uri( $url ) ) {
            $r->log->info("Match based on extension, proxying request");
            return &proxy_request( $r );
        }
        
        my $content_type;
        if ( $content_type = SL::Cache::grab($url) ) {
            if ( SL::Util::not_html($content_type)) {
                $r->log->info("Proxy match on cache: $content_type - $url");
                return &proxy_request( $r );
            } else {
                $r->log->info("Cache returned HTML type $content_type - $url");
                $r->pnotes('content_type' => $content_type );
            }
        }
    } 
    $r->log->info("EndTranshandler");
}

# Some bit torrent clients and other programs make http requests.  We
# don't want to mess with those
sub _not_a_browser {
    my $r = shift;
    my $ua = $r->headers_in->{'user-agent'};
    
    $r->log->info("User agent is ", Data::Dumper::Dumper($ua));
    if ( $ua =~ m/^$ua_regex/i ) {
        # This is a request made by a web browser
        $r->pnotes('ua' => $ua);
        return 0;
    }
    
    # This is a bit torrent or browser we don't know about
    $r->log->info("Request made by non_browser");
    return 1;
}

sub mod_proxy {
    my $r = shift;

    my $url = $r->construct_url;
    
    ##########
    # Use mod_proxy to do the proxying
    $r->log->info("Using mod_proxy to proxy request");
    $r->proxyreq(1);
    $r->uri($url);
    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r = shift;
    
    ##########
    # Use perlbal to do the proxying
    $r->log->info("Using perlbal to reproxy request");
    $r->headers_out->add( 'X-REPROXY-URL' => $r->construct_url );
    return Apache2::Const::DONE;
}

sub _setup_user_agent {
    my $r = shift;
    require LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    $ua->agent($r->pnotes('ua'));

    #######################################
    # Cookies
    require HTTP::Cookies;
    $ua->cookie_jar( HTTP::Cookies->new( file => "/tmp/foocookies" ) );
    return $ua;
}

sub _setup_proxy_req {
    my $r = shift;
    $r->log->debug( "Transhandler _setup_proxy_req for $$ to ",
        $r->construct_url );
    require Apache2::Cookie;
    my $cookies = Apache2::Cookie->fetch($r);

    require HTTP::Request;
    my $proxy_req = HTTP::Request->new;
    $proxy_req->uri( $r->construct_url( $r->unparsed_uri ) );
    if ($cookies) {
        $proxy_req = SL::Apache::_add_headers( $proxy_req, $cookies );
    }

    return $proxy_req;
}

1;

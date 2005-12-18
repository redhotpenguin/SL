package SL::Apache::PerlTransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

our $ext_regex;
our $ua_regex;
our $whitelist;

BEGIN {
    require Regexp::Assemble;

    open(FH, "< /home/fred/dev/sl/trunk/data/whitelist.txt") or
        die "Could not open whitelist: $!\n";
    my @whitelists = split("\n", do { local $/; <FH> } );
    $whitelist = Regexp::Assemble->new;
    $whitelist->add( @whitelists );
    print STDERR "Regex for whitelist domains is ", $whitelist->re, "\n";
    
    my @extensions = qw( 
        ad bz2 css doc exe fla gif gz ico jpeg jpg pdf png ppt rar sit 
        tgz txt zip );
    
    $ext_regex = Regexp::Assemble->new;
    $ext_regex->add(@extensions);
    print STDERR "Regex for static content match is ", $ext_regex->re, "\n";

    my @user_agents = qw( Firefox IE Opera Mozilla Safari libscrobbler Links 
        Lynx);
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
    if ( $url =~ m/\.$ext_regex$/i ) {
        return 1;
    }
}

sub _whitelisted {
    my $r = shift;
    my $url = $r->pnotes("url") || $r->construct_url( $r->unparsed_uri );
    if ( $url =~ m/$whitelist/i ) {
        $r->log->debug( "Whitelist match: $url for $whitelist\n");
        return 1;
    }
        $r->log->debug( "Whitelist NON-match: $url for $whitelist\n");
}

sub handler {
    my $r = shift;

    my $url = $r->pnotes("url") || $r->construct_url( $r->unparsed_uri ) ;
    $r->pnotes("url" => $url );
    
    $r->log->debug("Invoking Transhandler for url $url"); 
    
    my $is_initial_proxy;
    
    #if ( $r->proxyreq && ( my ($filename) = $r->filename =~ m/^proxy\:(.*)/ ) )
    if ( my ($filename) = $r->filename =~ m/^proxy\:(.*)/ ) 
    {
         $is_initial_proxy++;
        # De-proxy this request
         $r->log->debug("Deproxying request for ", $r->filename ); 
         $r->log->debug("Deproxying request for ", $filename ); 
         $r->log->debug("Deproxying request for uri ", $r->uri ); 
         
         my ($newurl) = $url =~ m/^http:\/\/.*(http:\/\/.*)$/;
        
         $r->pnotes("url" => $newurl );
         $r->log->debug("Deproxying request for ", $newurl ); 
         #    $r->uri($newurl);
         $r->filename( $filename );
           
    }
    unless ( $is_initial_proxy ) {
        $r->uri( $r->pnotes("url"));
    }
        
        
    $r->log->debug("Whitelisting is : ", $r->dir_config->get("SLWhiteList")); 
    unless ( ($r->dir_config->get("SLWhiteList") eq "On")  
        && _whitelisted( $r ) ) 
    {
        return &proxy_request( $r );
    }
    
    if ( _not_a_browser($r) ) 
    {
        $r->log->info("Request made by non-browser for $url");
        return &proxy_request( $r );
    }    
    
    if ( $r->method eq 'GET' ) {
        if ( static_content_uri( $url ) ) 
        {
            $r->log->info("Match based on extension, proxying request");
            return &proxy_request( $r );
        }
        
        my $content_type;
        if ( $content_type = SL::Cache::grab($url) ) 
        {
            if ( SL::Util::not_html($content_type)) 
            {
                $r->log->info("Proxy match on cache: $content_type - $url");
                return &proxy_request( $r );
            } else {
                $r->log->info("Cache returned HTML type $content_type - $url");
                $r->pnotes('content_type' => $content_type );
            }
        }
    } 
    $r->log->info("EndTranshandler");
    
    my $old_req = $r->proxyreq(0);
    $r->log->info("proxyreq:  ", $old_req);
    $old_req = $r->proxyreq(0);
    $r->log->info("proxyreq:  ", $old_req);
    $r->log->info("filename:  ", $r->filename);
    $r->log->info("uri: ", $r->uri);
    $r->handler('modperl'); 
    $r->set_handlers(PerlResponseHandler => 'SL::Apache' );
    return Apache2::Const::OK;
}

# Some bit torrent clients and other programs make http requests.  We
# don't want to mess with those
sub _not_a_browser {
    my $r = shift;
    my $ua = $r->headers_in->{'user-agent'};
    
    $r->log->info("User agent is ", Data::Dumper::Dumper($ua));
    if ( $ua =~ m/$ua_regex/i ) {
        # This is a request made by a web browser
        $r->pnotes('ua' => $ua);
        return 0;
    }
    
    # This is a bit torrent or browser we don't know about
    $r->log->info("Request made by non_browser $ua");
    return 1;
}

sub mod_proxy {
    my $r = shift;

    my $url = $r->pnotes("url") || $r->construct_url( $r->unparsed_uri);
    
    ##########
    # Use mod_proxy to do the proxying
    $r->log->info("Using mod_proxy to proxy request for $url");
    $r->proxyreq(1);
    my $filename = "proxy:" . $r->uri;
    $r->filename($filename);
    $r->log->info("Using mod_proxy to proxy request, uri: ", $r->uri);
    $r->log->info("Using mod_proxy to proxy request, filename: ", $r->filename);
    $r->log->info("Unparsed_uri: ", $r->unparsed_uri);
    $r->handler('proxy-server');
    return Apache2::Const::OK;
}

sub perlbal {
    my $r = shift;
    
    ##########
    # Use perlbal to do the proxying
    my $url = $r->pnotes("url") || $r->construct_url( $r->unparsed_uri);
    $r->log->info("Using perlbal to reproxy request");
    $r->headers_out->add( 'X-REPROXY-URL' => $url );
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

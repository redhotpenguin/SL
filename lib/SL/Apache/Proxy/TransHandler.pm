package SL::Apache::Proxy::TransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

use SL::Model::URL;

our $ext_regex;
our $ua_regex;
our $DEBUG = 0;

BEGIN {
    require Regexp::Assemble;
    
    ## Extension based matching
    my @extensions = qw(
      ad avi bz2 css doc exe fla gif gz ico jpeg jpg js pdf png ppt rar sit
      rss tgz txt wmv vob xpi zip );

    $ext_regex = Regexp::Assemble->new;
    $ext_regex->add(@extensions);
    print STDERR "Regex for static content match is ", $ext_regex->re, "\n\n" if $DEBUG;
}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE);
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Data::Dumper qw( Dumper );
use SL::Cache;
use SL::Util;

sub proxy_request {
    my $r = shift;
    if ($r->dir_config('SLProxy') eq 'perlbal') {
        return &perlbal($r);
    }
    elsif ($r->dir_config('SLProxy') eq 'mod_proxy') {
        return &mod_proxy($r);
    }
}

sub static_content_uri {
    my $url = shift;
    if ($url =~ m{\.(?:$ext_regex)$}i) {
        return 1;
    }
}

sub not_a_main_request {
    my $r = shift;

    my $c      = $r->connection;
    my $rlinks = $c->pnotes('rlinks');
    unless (defined $rlinks) {

        # this is a new connection so scan just return and grab the links later
        $r->log->debug("$$ RLINKS undefined");
        return;
    }
    $r->log->debug("Rlinks are " . join(', ', @{$rlinks}));

    my $referer = $r->pnotes('referer');
    if (grep { $_ =~ m/$referer/ } @{$r->connection->pnotes("rlinks")}) {
        $r->log->debug("This request referer matches rlinks");
        return;
    }
}

sub handler {
    my $r = shift;
    
    $r->log->info("$$ PerlTransHandler request");
    
    my $url     = $r->construct_url($r->unparsed_uri);
    $r->log->info("$$ PerlTransHandler request, uri $url");
    my $ua      = $r->headers_in->{'user-agent'};
    my $referer = $r->headers_in->{'referer'} || 'no_referer';

    $r->pnotes('url'     => $url);
    $r->pnotes('ua'      => $ua);
    $r->pnotes('referer' => $referer);

    $r->log->info("$$ PerlTransHandler Request for url $url, user-agent $ua, referer $referer");

    # allow /sl_secret_ping_button to pass through
    if ($url =~ m!/sl_secret_ping_button$!) {
        return Apache2::Const::DONE;
    }
        
    if (url_blacklisted($url)) {
        return &proxy_request($r);
    }

    ## Handle non-browsers that use port 80
    #
    if (_not_a_browser($r)) {
        return &proxy_request($r);
    }

    ## check for browser subrequests - UNDER CONSTRUCTION
    if (not_a_main_request($r)) {
        return &proxy_request($r);
    }

    if ($r->method eq 'GET') {

        ## Static content
        #
        if (static_content_uri($url)) {
            $r->log->info("$$ Url $url static content extension, proxying");
            return &proxy_request($r);
        }

        ## Check the cache for a static content match
        #
        if (my $content_type = SL::Cache::grab($url)) {

            $r->log->info("$$ SL::Cache hit for url $url, type $content_type");

            if (SL::Util::not_html($content_type)) {
                ## Cache returned static content
                #
                $r->log->info("$$ Proxying static $url, type $content_type");
                return &proxy_request($r);
            }
            else {

                # Cache returned dynamic html
                #
                $r->log->info("$$ SL::Cache $url HTML type $content_type");
                $r->pnotes('content_type' => $content_type);
            }
        }
    }
    $r->log->info("EndTranshandler");
}

sub url_blacklisted {
    my $url = shift;

    my $blacklist_regex = SL::Model::URL->blacklist_regex;
    return 1 if ($url =~ m{$blacklist_regex});
}

# extract this to a utility library or something
sub _not_a_browser {
    my $r = shift;

    # all browsers start with Mozilla, at least in apache
    if (substr($r->pnotes('ua'), 0, 7) eq 'Mozilla') {
      return;
    }

    $r->log->debug("$$ This is not a browser: " . $r->pnotes('ua'));
    return 1;
}

sub mod_proxy {
    my $r = shift;

    ## Don't change this next line even if you think you should
    #
    my $url = $r->construct_url;

    ## Use mod_proxy to do the proxying
    #
    $r->log->info("$$ mod_proxy handling request for $url");
    $r->uri($url);

    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    $r->proxyreq(1);
    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r     = shift;

    ##########
    # Use perlbal to do the proxying
    $r->log->info("Using perlbal to reproxy request");
    my $uri = $r->construct_url($r->unparsed_uri);
    $r->headers_out->add('X-REPROXY-URL' => $r->construct_url);
    return Apache2::Const::DONE;
}

1;

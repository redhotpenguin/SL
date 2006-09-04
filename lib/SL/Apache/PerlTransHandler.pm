package SL::Apache::PerlTransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

our $blacklist_regex;
our $ext_regex;
our $ua_regex;
our $whitelist;

BEGIN {
    require Regexp::Assemble;
    require Perl6::Slurp;
	#require SL::Config;

	# FIXME
	# http://perl.apache.org/docs/2.0/user/config/custom.html#C_SERVER_CREATE_
	my $data_root = $ENV{SL_ROOT} . '/proxyserver/data';
	
    ## Whitelist
    my @whitelists =
      split("\n", Perl6::Slurp::slurp($data_root . '/whitelist.txt'));
    die unless @whitelists;
    $whitelist = Regexp::Assemble->new;
    $whitelist->add(@whitelists);
    print STDERR "Regex for whitelist domains is ", $whitelist->re, "\n\n";

    #####################
    ## Blacklisting
    my @blacklists =
      split("\n", Perl6::Slurp::slurp($data_root . '/blacklist.txt'));
    $blacklist_regex = Regexp::Assemble->new;
    $blacklist_regex->add(@blacklists);
    print STDERR "Regex for blacklist_urls: ", $blacklist_regex->re, "\n\n";

    ## Extension based matching
    my @extensions = qw(
      ad bz2 css doc exe fla gif gz ico jpeg jpg js pdf png ppt rar sit
      rss tgz txt wmv vob xpi zip );

    $ext_regex = Regexp::Assemble->new;
    $ext_regex->add(@extensions);
    print STDERR "Regex for static content match is ", $ext_regex->re, "\n\n";

    my @user_agents =
      qw( libwww-perl Camino Firefox IE Opera Netscape Safari libscrobbler
      Links Lynx);

    $ua_regex = Regexp::Assemble->new;
    $ua_regex->add(@user_agents);
    print STDERR "Regex for user agents is ", $ua_regex->re, "\n\n";
}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE);
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Data::Dumper qw( Dumper );
use SL::Apache;
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

sub _whitelisted {
    my ($r, $url) = @_;
    if ($url =~ m/$whitelist/i) {
        $r->log->debug("$$ Whitelist match: $url for $whitelist\n");
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
    
	## Blacklisting first
    if (url_blacklisted($url)) {
        return &proxy_request($r);
    }

    ## Whitelisting
    #
    my $whitelist = $r->dir_config->get('SLWhiteList');
    $r->log->debug("$$ Whitelisting is $whitelist");
    if ($whitelist eq "On" && !_whitelisted($r, $url)) {
        $r->log->debug("$$ Url $url not whitelisted, proxying");
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
    return 1 if ($url =~ m{$blacklist_regex});
}

# Some bit torrent clients and other programs make http requests.  We
# don't want to mess with those
sub _not_a_browser {
    my $r = shift;

    my $ua = $r->pnotes('ua');
    if (! $ua ) {
    	$r->log->error("$$ Hmmm there was no user agent..., url " . $r->pnotes('url'));
    }
    if ($ua =~ m/$ua_regex/i) {
        $r->log->info("$$ Browser request user agent $ua");
        return 0;
    }

    # This is a bit torrent or browser we don't know about
    $r->log->info("$$ Proxying non-browser for user-agent $ua");
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

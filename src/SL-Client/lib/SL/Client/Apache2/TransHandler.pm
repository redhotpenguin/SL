package SL::Client::Apache2::TransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Client::Apache2::PerlTransHandler

=head1 SYNOPSIS

In your httpd.conf file:

  SL_URL_Blacklist_File /etc/sl/url_blacklist.txt
  SL_UA_Blacklist_File  /etc/sl/ua_blacklist.txt
  SL_EXT_Blacklist_File /etc/sl/ext_blacklist.txt
  SL_Client_Cache_File  /tmp/sl/client_cache_file

  PerlTransHandler SL::Client::Apache2::PerlTranshandler

=cut

use Apache2::Module;
use Apache2::ServerUtil;
use Cache::FastMmap;
use Data::Dumper;

our ($cfg, $server, $url_regex, $ua_regex);

my $cache;

BEGIN {
    $server = Apache2::ServerUtil->server;
    $cfg = Apache2::Module::get_config('SL::Client::Config', $server);

    my $class = __PACKAGE__;
    my ($sharefile) = $class =~ s/\:\:/_/g;
    $cache = Cache::FastMmap->new(sharefile => "/tmp/$sharefile");
   
    # load the data into the cache
    my $fh;
    foreach my $param qw( URL_Blacklist UA_Blacklist EXT_Blacklist Proxy_List ) {

      open($fh, "<", $cfg->{"SL_$param\_File"}) 
        or die "no open " . $cfg->{"SL_$param\_File"} . ":  $!\n";
      my $regex_content = do { local $/; <$fh> };
      close($fh);
      #print STDERR "Caching $param, content $regex_content\n";
      $cache->set(lc($param) => qr/$regex_content/);
  }
}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE M_GET);
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Apache2::URI            ();
use APR::Table              ();

sub proxy_request_b {
    my $r = shift;
    if ($r->dir_config('SLProxy') eq 'perlbal') {
        return &perlbal($r);
    }
    elsif ($r->dir_config('SLProxy') eq 'mod_proxy') {
        return &mod_proxy($r);
    }
}

sub handler {
    my $r = shift;

    my $url     = $r->construct_url($r->unparsed_uri);
	$r->log->debug("$$ PerlTransHandler url $url");

    my $ua      = $r->headers_in->{'user-agent'};
    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->log->debug("$$ PerlTransHandler user-agent $ua, referer $referer");

    if ($r->method_number == Apache2::Const::M_GET) {
	# Match against the list of known browsers we support
    if (_not_a_browser($r, $ua)) {
        return &proxy_request($r);
    }
    
    # Match against the list of suspected static file extensions
    if (_ext_blacklisted($r, $url)) {
      return &proxy_request($r);
    }

    # Match against the url blacklist
	if (_url_blacklisted($r, $url)) {
        return &proxy_request($r);
    }
  } else {
    return &proxy_request($r);
  }
    return &mod_proxy_two($r);
    # at this point we'll send the request to the SL web service for processing
    $r->pnotes('url'     => $url);
    $r->pnotes('ua'      => $ua);
    $r->pnotes('referer' => $referer);
    return Apache2::Const::OK;
}


sub _ext_blacklisted {
    my ($r, $url) = @_;

    my $ext_regex = $cache->get('ext_blacklist');
    $r->log->debug("Applying ext regex: $ext_regex\n\n");
    unless ($ext_regex) {
      $r->log->error("No user agent regex in cache, error!");
      return 1;
    }

    return 1 if ($url =~ m{$ext_regex}i);
    return;
}

sub _url_blacklisted {
    my ($r, $url) = @_;

    my $url_regex = $cache->get('url_blacklist');
    unless ($url_regex) {
      $r->log->error("No url regex in cache, error!");
      return 1;
    }

    return 1 if ($url =~ m{$url_regex}i);
    return;
}

# Some bit torrent clients and other programs make http requests.  We
# don't want to mess with those
sub _not_a_browser {
    my ($r, $ua) = @_;

    if (! $ua ) {
    	$r->log->error("$$ Hmmm there was no user agent...");
    }

    my $ua_regex = $cache->get('ua_blacklist');
    unless ($ua_regex) {
      $r->log->error("No user agent regex in cache, error!");
      return 1;
    }

    # return if user agent is a browser
    return if ($ua !~ m{$ua_regex}i);

    # This is a bit torrent or browser we don't know about
    return 1;
}

sub proxy_request {
    my $r = shift;

    ## Don't change this next line even if you think you should
    ## No matter how tempting it may be, don't touch it
    my $url = $r->construct_url;
$r->log->error("regular proxy request");
    ## Use mod_proxy to do the proxying
    $r->uri($url);
    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    $r->proxyreq(1);
    return Apache2::Const::DECLINED;
}

sub mod_proxy_two {
    my $r = shift;

    ## Don't change this next line even if you think you should
    ## No matter how tempting it may be, don't touch it
    my $url = $r->construct_url;
$r->log->error("MOD_PROXY_TWO, heavy");
    ## Use mod_proxy to do the proxying
    $r->uri("http://64.127.99.51:8069");
    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    $r->proxyreq(1);
    $r->log->error("DOLLAR R AS STRING: " . $r->as_string);
    return Apache2::Const::DECLINED;
}


1;

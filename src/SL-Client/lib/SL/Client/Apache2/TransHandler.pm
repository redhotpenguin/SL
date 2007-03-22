package SL::Client::Apache2::TransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Client::Apache2::PerlTransHandler

=head1 SYNOPSIS

In your httpd.conf file:

  SL_URL_Blacklist_File /usr/local/sl/conf/url_blacklist.txt
  SL_EXT_Blacklist_File /usr/local/sl/conf/ext_blacklist.txt
  SL_Client_Cache_File  /tmp/sl/client_cache_file
  SL_Proxy_List_File    /usr/local/sl/conf/proxy_list.txt

  PerlTransHandler SL::Client::Apache2::PerlTranshandler

=cut

use Apache2::Module;
use Apache2::ServerUtil;
use Cache::FastMmap;
use Data::Dumper;

our ( $cfg, $server );

my $cache;

BEGIN {
    $server = Apache2::ServerUtil->server;
    $cfg    = Apache2::Module::get_config( 'SL::Client::Config', $server );

    my $class = __PACKAGE__;
    (my $sharefile = $class) =~ s/\:\:/_/g;
    $cache = Cache::FastMmap->new( cache_size => '32m', 
                                   share_file => "/tmp/$sharefile" );

    # load the data into the cache
    my $fh;
    foreach my $param qw( URL_Blacklist EXT_Blacklist ) {
        open( $fh, "<", $cfg->{"SL_$param\_File"} )
          or die "no open " . $cfg->{"SL_$param\_File"} . ":  $!\n";
        my $regex_content = do { local $/; <$fh> };
        close($fh);

        print STDERR "Caching $param, content $regex_content\n";
        $cache->set( lc($param) => $regex_content );
    }

    # load proxy list
    open($fh, "<",  $cfg->{"SL_Proxy_List_File"} )
      or die "no open " . $cfg->{"SL_Proxy_List_File"} . ":  $!\n";
    my @proxy_list;
    while (<$fh>) {
        chomp;
        push(@proxy_list, $_);
    }
    close $fh;
    $cache->set(proxy_list => \@proxy_list);    

    # leave the open proxy list cache entry empty initially
}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE M_GET);
use Apache2::Connection     ();
use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Apache2::ServerRec      ();
use Apache2::ServerUtil     ();
use Apache2::URI            ();
use APR::Table              ();

sub handler {
    my $r = shift;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->log->debug("$$ PerlTransHandler url $url");

    my $ua = $r->headers_in->{'user-agent'}   || 'no_user_agent';
    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->log->debug("$$ PerlTransHandler user-agent $ua, referer $referer");

    if ( $r->method_number == Apache2::Const::M_GET ) {

        # Match against the list of known browsers we support
      $r->log->debug("testing user agent");
        if ( _not_a_browser( $r, $ua ) ) {
            $r->log->debug("+++ sending to mod_proxy: not a user agent");
            return &proxy_request($r);
        }

      $r->log->debug("Testing extension");
        # Match against the list of suspected static file extensions
        if ( _ext_blacklisted( $r, $url ) ) {
            $r->log->debug("+++ sending to mod_proxy: ext blacklist");
            return &proxy_request($r);
        }

      $r->log->debug("Testing URL");
        # Match against the url blacklist
        if ( _url_blacklisted( $r, $url ) ) {
            $r->log->debug("+++ sending to mod_proxy: url blacklist");
            return &proxy_request($r);
        }
    }
    else { # any other method let mod_proxy handle it
        return &proxy_request($r);
    }

    # proxy the request if there are any available proxies
    my $proxy_list = $cache->get('open_proxy_list');
    unless ($proxy_list and @$proxy_list) {
        # no available proxies, have mod_proxy handle it
        $r->log->debug("+++ sending to mod_proxy: no open proxies");
        return &proxy_request($r);
    }

    # choose a random proxy
    my ($proxy_host, $proxy_port) = 
      split(':', $proxy_list->[int(rand(scalar(@{$proxy_list})))]);

    # put info in pnotes for use in the response handler
    $r->pnotes(url => $url);
    $r->pnotes(proxy_host => $proxy_host);
    $r->pnotes(proxy_port => $proxy_port);

    $r->log->debug("*** sending '$url' to SL proxy '$proxy_host:$proxy_port'");

    # got this far, must be ok to proxy the request to SL - go to
    # ResponseHandler
    return;
}

sub _ext_blacklisted {
    my ( $r, $url ) = @_;

    my $ext_regex = $cache->get('ext_blacklist');
    unless ($ext_regex) {
        $r->log->error("No user agent regex in cache, error!");
        return 1;
    }

    return 1 if ( $url =~ m/$ext_regex/i );
    return;
}

sub _url_blacklisted {
    my ( $r, $url ) = @_;

    my $url_regex = $cache->get('url_blacklist');
    unless ($url_regex) {
        $r->log->error("No url regex in cache, error!");
        return 1;
    }

    return 1 if ( $url =~ m/$url_regex/i );
    return;
}

# Some bit torrent clients and other programs make http requests.  We
# don't want to mess with those
sub _not_a_browser {
    my ( $r, $ua ) = @_;

    # check for user agent starting with 'Mozilla'
    my $match = 'Mozilla';
    if (substr($ua, 0, length($match)) eq $match) {
      return;
    }
    $r->log->debug("non browser user agent: $ua");
    # This is a bit torrent or browser we don't know about
    return 1;
}

sub proxy_request {
    my $r = shift;

    ## Don't change this next line even if you think you should
    ## No matter how tempting it may be, don't touch it
    my $url = $r->construct_url;
    $r->log->error("regular proxy request: $url");
    ## Use mod_proxy to do the proxying
    $r->uri($url);
    $r->filename("proxy:$url");
    $r->handler('proxy-server');
    $r->proxyreq(1);
    return Apache2::Const::DECLINED;
}

1;

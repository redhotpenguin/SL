package SL::Apache::Proxy::TransHandler;

use strict;
use warnings;

=head1 NAME

SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

use SL::Model       ();
use SL::Model::URL  ();
use SL::BrowserUtil ();

our( $EXT_REGEX, $BLACKLIST_REGEX );
use Regexp::Assemble ();

use constant DEBUG      => $ENV{SL_DEBUG}      || 0;
use constant VERBOSE_DEBUG => $ENV{VERBOSE_DEBUG} || 0;
use constant TIMING     => $ENV{SL_TIMING}     || 0;
use constant REQ_TIMING => $ENV{SL_REQ_TIMING} || 0;

use SL::Config;
our $CONFIG;

BEGIN {
    $CONFIG = SL::Config->new();

    ## Extension based matching
    # removed js css swf
    my @extensions = qw(
      js torrent img avi bin bz2 doc exe fla flv gif gz ico jpeg jpg pdf png 
      ppt mpg mpeg mp3 tif tiff
ads
 swf     rar sit
rdf rss tgz txt wmv vob xpi zip );

    $EXT_REGEX = Regexp::Assemble->new->add(@extensions)->re;
    print STDERR "Regex for static content match is $EXT_REGEX\n"
      if DEBUG;

    $BLACKLIST_REGEX = SL::Model::URL->generate_blacklist_regex;
    print STDERR "Blacklist reges is $BLACKLIST_REGEX\n" if DEBUG;

}

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE LOG_INFO M_GET );
use Apache2::Connection   ();
use Apache2::RequestRec   ();
use Apache2::RequestUtil  ();
use Apache2::ServerRec    ();
use Apache2::ServerUtil   ();
use Apache2::URI          ();
use SL::Cache             ();
use SL::Util              ();
use SL::Cache             ();
use SL::Cache::User       ();
use SL::Cache::Subrequest ();
use SL::Model::Ad::Google ();

our $CACHE              = SL::Cache->new( type => 'raw' );
our $SUBREQUEST_TRACKER = SL::Cache::Subrequest->new;
our $USER_CACHE         = SL::Cache::User->new;

my $TIMER;
if (TIMING) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

sub static_content_uri {
    my $url = shift;
    if ( $url =~ m{\.$EXT_REGEX}i ) {
        return 1;
    }
}

sub handler {
    my $r = shift;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url' => $url );

    if ( $r->pnotes('ua') eq 'none' ) {
        $r->log->debug("$$ no user agent, mod_proxy") if DEBUG;
        return &proxy_request($r);
    }

    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->pnotes( 'referer' => $referer );

    # our secret namespace
    if ( $url =~ m!/sl_secret_ping_button! ) {
        return Apache2::Const::OK;
    }

    # allow /sl_secret_blacklist_button to pass through
    if ( $url =~ m!/sl_secret_blacklist_button$! ) {
        return Apache2::Const::OK;
    }
    if ( $url =~ m!/sl_secret_status! ) {
        return Apache2::Const::OK;
    }

    ## Handle non-browsers that use port 80
    my $browser_name = SL::BrowserUtil->is_a_browser( $r->pnotes('ua') );
    if(! $browser_name ) {
        $r->log->debug("$$ not a browser: " . $r->as_string) if DEBUG;
        $r->pnotes('not_a_browser' => 1);
        return &proxy_request($r);

    } elsif ($browser_name) {

      if ($browser_name eq 'opera') {
        # sorry opera locks up on stuff
        return handle_opera_redirect($r);
      } else {
        $r->pnotes('browser_name' => $browser_name);
      }

    }

    # get only
    unless ( $r->method_number == Apache2::Const::M_GET ) {
        $r->log->debug("$$ not a GET request, mod_proxy") if DEBUG;
        return &proxy_request($r);
    }

    # http 1.1 only
    my $hostname;
    unless ( $hostname = defined $r->headers_in->{'Host'} ) {
        $r->log->debug("$$ no host header, mod_proxy") if DEBUG;
        return &proxy_request($r);
    }

    # serving ads on hosts that are ip numbers causes problems usually
    if ($hostname =~ m/\d{1,3}:\d{1,3}:\d{1,3}:\d{1,3}/) {
        $r->log->debug("$$ hostname is ip addr $hostname, perlbal") if DEBUG;
        return &perlbal($r);
    }

    # first level domain name check for things that perlbal can't handle
    if ($url =~ m{\.(?:js|video-stats\.video\.google\.com|javascript|txt|css|yahoofs|tbn0)|s3\.amazonaws\.com|tbn\d\.google}i ) {
      $r->log->debug("$$ js|css|yahoofs found $url") if DEBUG;
      return &proxy_request($r);
    }

    # need to be a get to get a x-sl header, covers non GET requests also
    if ( my $sl_header = $r->headers_in->{'x-sl'} ) {
        $r->pnotes( 'sl_header' => $sl_header );
        $r->log->debug("$$ Found sl_header $sl_header") if DEBUG;

        my ( $hash_mac, $router_mac ) =
          split ( /\|/, $r->pnotes('sl_header') );

        # stash these
        $r->pnotes( 'hash_mac'   => $hash_mac );
        $r->pnotes( 'router_mac' => $router_mac );

        $r->log->debug("$$ router $router_mac, hash_mac $hash_mac")
          if DEBUG;

        # get rid of this header so that is isn't proxied
        $r->headers_in->unset('x-sl');

        unless ( $router_mac && $hash_mac ) {
            $r->log->error("$$ sl_header present but no hash or router mac");
            return Apache2::Const::SERVER_ERROR;    # not really anything better
        }
    } else {
        # send to mod_proxy
        return &proxy_request($r);
    }

    # start the clock - the stuff above is all memory
    $TIMER->start('db_mod_proxy_filters') if TIMING;

    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("$$ Database has gone away, sending to mod_proxy");
        return &proxy_request($r);
    }

    # ok check for a splash page
    my ( $splash_url, $timeout ) =
      SL::Model::Proxy::Router->splash_page( $r->pnotes('router_mac') );
    if ($splash_url) {
        my $should_redir = handle_splash_redirect( $r, $splash_url, $timeout );
        return Apache2::Const::OK if $should_redir;
    }

    ## Static content
    if ( static_content_uri($url) ) {
        $r->log->debug("$$ Url $url static content ext, perlbal") if DEBUG;
        return &perlbal($r);
    }

    ## hack for google ads
    return &proxy_request($r) if ( $referer =~ m/googlesyndication/ );

    # have perlbal grab these
    return &proxy_request($r)
      if $url eq 'http://pagead2.googlesyndication.com/pagead/show_ads.js';

    # if this is one of our google ads then log it and pass it
    # this needs to be before the blacklist check
    if (
        my $ad_id = SL::Model::Ad::Google->match_and_log(
            {
                url     => $url,
                ip      => $r->connection->remote_ip,
                mac     => $r->pnotes('router_mac'),
                user    => $r->pnotes('hash_mac'),
                referer => $referer,
            }
        )
      )
    {

		# ugh, this bug counted google ads twice
		# $r->pnotes( 'ad_id' => $ad_id );
        $r->log->debug( "$$ google ad view match for url $url, ip "
              . $r->connection->remote_ip)
          if DEBUG;
        return &proxy_request($r);
    }
    # other peoples google ads
    return &proxy_request($r) if ( $url =~ m/googlesyndication/ );

    # do not move this!
    if ($r->unparsed_uri =~ m/brightcove|flash/i) {
      $r->log->debug("$$ flash or brightcove url $url, mod_proxy") if DEBUG;
       return &proxy_request($r);
     }

    # known offenders that are perlbal can
    if ($url =~ m/sphere.com|fmpub.net|edgesuite|oascentral|2mdn\.net/i) {
      $r->log->debug("$$ known slow content server $url, perlbal") if DEBUG;
       return &perlbal($r);
     }

    $r->log->debug("$$ checking blacklisted urls") if DEBUG;
    # blacklisted urls
    if ( url_blacklisted($url) ) {
        $r->log->debug("$$ url $url blacklisted") if DEBUG;
        return &proxy_request($r);
    }

    $r->log->debug("$$ checking blacklisted users") if DEBUG;
    # User and content driven handling
    # Close this bar
    if (user_blacklisted( $r, $dbh )) {
		$r->log->debug("$$ user blacklisted") if DEBUG;
        return &handle_user_blacklisted($r);
    }

    # check for sub-reqs if it passed the other tests
    $r->log->debug("$$ checking if subrequest") if DEBUG;
    my $is_subreq = $SUBREQUEST_TRACKER->is_subrequest( url => $url );
    return &proxy_request($r) if $is_subreq;

    ## Check the cache for a static content match
    return &proxy_request($r)              if $CACHE->is_known_not_html($url);
    $r->log->debug("EndTranshandler") if DEBUG;

    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    return Apache2::Const::OK;
}

sub handle_user_blacklisted {
  my $r= shift;

  # delete any caching headers to make sure we get a fresh page
  $r->headers_in->unset($_) for qw( If-Modified-Since If-None-Match );

  return &proxy_request($r);
}

sub handle_opera_redirect {
  my $r = shift;

  $r->set_handlers(
                   PerlResponseHandler => ['SL::Apache::Proxy::OperaHandler']
  );
  return Apache2::Const::OK;
}

sub handle_splash_redirect {
    my ( $r, $splash_url, $timeout ) = @_;

    $r->log->debug(
        "sp url $splash_url, timeout $timeout,mac " . $r->pnotes('router_mac') )
      if DEBUG;

    # aha splash page, check when the last time we saw this user was
    my $last_seen = $USER_CACHE->get_last_seen( $r->pnotes('sl_header') );
    $r->log->debug( "last seen $last_seen seen, time " . time() )
      if DEBUG;

    my $set_ok = $USER_CACHE->set_last_seen( $r->pnotes('sl_header') );

    if ( !$last_seen
        or ( ( $timeout * 60 ) < ( time() - $last_seen ) ) )
    {

      $r->log->debug("$$ sending to splash handler for url $splash_url")
        if DEBUG;
      $r->pnotes( 'splash_url' => $splash_url );

        $r->set_handlers(
            PerlResponseHandler => ['SL::Apache::Proxy::SplashHandler'] );
        return 1;
    } else {

      return;
  }
}

sub user_blacklisted {
    my ( $r, $dbh ) = @_;

    my $user_id = join ( '|', $r->pnotes('hash_mac'),
                          $r->pnotes('router_mac'), $r->construct_server() );

    $r->log->debug("==> user_blacklist check with user_id $user_id")
      if DEBUG;
    my $sth =
      $dbh->prepare(
        "SELECT count(user_id) FROM user_blacklist WHERE user_id = ?");
    $sth->bind_param( 1, $user_id );
    my $rv= $sth->execute;
    unless ($rv) {
      $r->log->error("$$ user_blacklist query failed for user id $user_id");
    $sth->finish;
      return;
    }

    my $ary_ref = $sth->fetchrow_arrayref;
    $sth->finish;

    return 1 if $ary_ref->[0] > 0;
    return;
}

sub url_blacklisted {
    my $url = shift;

    my $ping = SL::Model::URL->ping_blacklist_regex;
    if ($ping) {    # update the blacklist if it has changed
        $BLACKLIST_REGEX = $ping;
    }
    return 1 if ( $url =~ m{$BLACKLIST_REGEX}i );
}

sub proxy_request {
    my $r = shift;

    return &mod_proxy($r);
}

sub _unset_proxy_headers {
  my $r = shift;
    $r->headers_in->unset($_) for qw( X-Proxy-Capabilities X-SL X-Forwarded-For );
}

sub mod_proxy {
    my ( $r, $uri ) = @_;

    die("oops called proxy_request without \$r") unless ($r);

    _unset_proxy_headers($r);

    ## Don't change this next line even if you think you should
    my $url = $r->construct_url;

    ## Use mod_proxy to do the proxying
    $r->log->debug("$$ mod_proxy handling request for $url") if DEBUG;

    # Don't change these lines either or you'll be hurting
    if ($uri) {
        $r->uri($uri);
        $r->unparsed_uri($uri);
    }

    # Don't change this stuff either unless you are on a desert island alone
    # with a solar powered computer
    $r->filename("proxy:$url");
    $r->log->debug( "$$ filename is " . $r->filename ) if DEBUG;

    $r->set_handlers( PerlResponseHandler => undef );
    $r->set_handlers( PerlLogHandler => undef );

    $r->handler('proxy-server');    # hrm this causes perl response as well
    $r->proxyreq(1);

#    $r->server->add_version_component( 'sl' ); # need to patch mod_proxy
    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r = shift;

    _unset_proxy_headers($r);

    if ($r->headers_in->{Cookie}) {
      # sorry perlbal doesn't reproxy requests with cookies
      return mod_proxy($r);
    }

    ##########
    # Use perlbal to do the proxying
    my $uri = $r->construct_url( $r->unparsed_uri );
    $r->headers_out->add( 'X-REPROXY-URL' => $r->construct_url );
    $r->set_handlers( PerlResponseHandler => undef );
    $r->set_handlers( PerlLogHandler => undef );
    $r->log->debug("$$ X-REPROXY-URL for $uri") if DEBUG;
    return Apache2::Const::DONE;
}

1;

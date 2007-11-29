package SL::Apache::Proxy::TransHandler;

use strict;
use warnings;

=head1 NAME
 
SL::Apache::TransHandler

=head1 SYNOPSIS

=cut

use SL::Model      ();
use SL::Model::URL ();

our( $EXT_REGEX, $BLACKLIST_REGEX );
use Regexp::Assemble ();

use constant DEBUG  => $ENV{SL_DEBUG}  || 0;
use constant TIMING => $ENV{SL_TIMING} || 0;
use constant REQ_TIMING => $ENV{SL_REQ_TIMING} || 0;

use SL::Config;
our $CONFIG;

BEGIN {
    $CONFIG = SL::Config->new();
}

use constant DEFAULT_HASH_MAC   => $CONFIG->sl_default_hash_mac   || 0;
use constant DEFAULT_ROUTER_MAC => $CONFIG->sl_default_router_mac || 0;

BEGIN {
    ## Extension based matching
    my @extensions = qw(
      ad avi bin bz2 css doc exe fla flv gif gz ico jpeg jpg js pdf png ppt
      rar sit swf rss tgz txt wmv vob xpi zip );

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
use SL::Cache::Subrequest ();
use SL::Model::Ad::Google ();

our $CACHE              = SL::Cache->new( type => 'raw' );
our $SUBREQUEST_TRACKER = SL::Cache::Subrequest->new;

my $TIMER;
if (TIMING) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

sub static_content_uri {
    my $url = shift;
    if ( $url =~ m{\.(?:$EXT_REGEX)$}i ) {
        return 1;
    }
}

sub handler {
    my $r = shift;

    my $url     = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url'     => $url );

    if ( $r->pnotes('ua') eq 'none' ) {
      $r->log->debug("$$ no user agent, mod_proxy");
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

    # get only
    unless ( $r->method_number == Apache2::Const::M_GET ) {
        $r->log->debug("$$ no host header, mod_proxy") if DEBUG;
        return &proxy_request($r);
    }

    # http 1.1 only
    unless ( defined $r->headers_in->{'Host'} ) {
        $r->log->debug("$$ no host header, mod_proxy") if DEBUG;
        return &proxy_request($r);
    }
    else {
        $r->log->debug( "$$ host header: " . $r->headers_in->{'Host'} ) if DEBUG;
    }

    # need to be a get to get a x-sl header, covers non GET requests also
    my ( $hash_mac, $router_mac ) = ( DEFAULT_HASH_MAC, DEFAULT_ROUTER_MAC );
    if ( my $sl_header = $r->headers_in->{'x-sl'} ) {
        $r->pnotes( 'sl_header' => $sl_header );
        $r->log->debug("$$ Found sl_header $sl_header") if DEBUG;

        ( $hash_mac, $router_mac ) =
          split ( /\|/, $r->pnotes('sl_header') );
        $r->log->debug("$$ router $router_mac, hash_mac $hash_mac")
          if DEBUG;
        unless ( $router_mac && $hash_mac ) {
            $r->log->error("$$ sl_header present but no hash or router mac");
            return Apache2::Const::SERVER_ERROR;    # not really anything better
        }

    }

    # stash these
    $r->pnotes( 'hash_mac'   => $hash_mac );
    $r->pnotes( 'router_mac' => $router_mac );

    ## Handle non-browsers that use port 80
    return &proxy_request($r) if ( _not_a_browser($r) );

    ## Static content
    if ( static_content_uri($url) ) {
        $r->log->debug("$$ Url $url static content extension, proxying")
          if DEBUG;
        return &proxy_request($r);
    }

    ## hack for google ads
    return &proxy_request($r) if ( $referer =~ m/googlesyndication/ );

    # if this is one of our google ads then log it and pass it
    # this needs to be before the blacklist check
    if (
        my $new_uri = SL::Model::Ad::Google->match_and_log(
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

        # HACK
        return &proxy_request($r)
          if ( $new_uri eq '1' );    # string or integer

        $r->log->debug( "$$ google ad click match for url $url, ip "
              . $r->connection->remote_ip
              . ", new uri $new_uri" )
          if DEBUG;
        $r->pnotes( 'google_override' => 1 );
        my $new_url = $r->construct_url($new_uri);
        $r->pnotes( url => $new_url );
        $r->log->debug("NEW URL: $new_url") if DEBUG;

        # delete the sl_header
        $r->headers_in->{'X-SL'}->unset;

        return &proxy_request($r);

        ######## google stealth mode - not in use right now
        my $PAGE_CACHE;    # HACK HACK HACK
        my $cached_url = $PAGE_CACHE->cache_url( { url => $referer } );
        if ($cached_url) {

            # the response handler handles the proxy for this so stash referer
            $r->pnotes( 'referer' => $cached_url );
            $r->headers_in->{Referer} = $cached_url;
        }
        ###############################################
    }

    # start the clock - the stuff above is all memory
    $TIMER->start('db_mod_proxy_filters') if TIMING;

    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("Database has gone away, sending to mod_proxy");
        return &proxy_request($r);
    }

    # blacklisted urls
    return &proxy_request($r) if ( url_blacklisted($url) );

    # User and content driven handling
    # Close this bar
    return &proxy_request($r) if user_blacklisted( $r, $dbh );

    # check for sub-reqs if it passed the other tests
    my $is_subreq = $SUBREQUEST_TRACKER->is_subrequest( url => $url );
    return &proxy_request($r) if $is_subreq;

    ## Check the cache for a static content match
    return mod_proxy($r)              if $CACHE->is_known_not_html($url);
    $r->log->debug("EndTranshandler") if DEBUG;

    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    return Apache2::Const::OK;
}

sub user_blacklisted {
    my ( $r, $dbh ) = @_;

    my $user_id;
    if ( my $sl_header = $r->pnotes('sl_header') ) {
        $user_id = join ( '|', $sl_header, $r->construct_server() );
    }
    else {
        $user_id = join ( "|",
            $r->connection->remote_ip, $r->pnotes('ua'),
            $r->construct_server() );
    }

    $r->log->debug("==> user_blacklist check with user_id $user_id")
      if DEBUG;
    my $sth =
      $dbh->prepare(
        "SELECT count(user_id) FROM user_blacklist WHERE user_id = ?");
    $sth->bind_param( 1, $user_id );
    $sth->execute;
    my $ary_ref = $sth->fetchrow_arrayref;
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

# extract this to a utility library or something
sub _not_a_browser {
    my $r = shift;

    # all browsers start with Mozilla, at least in apache
    if ( substr( $r->pnotes('ua'), 0, 7 ) eq 'Mozilla' ) {
        return;
    }

    $r->log->debug( "$$ This is not a browser: " . $r->pnotes('ua') )
      if DEBUG;
    return 1;
}

sub proxy_request {
    my ( $r, $uri ) = @_;

    warn("oops called proxy_request without \$r") unless ($r);

    ## Don't change this next line even if you think you should
    my $url = $r->construct_url;

    ## Use mod_proxy to do the proxying
    $r->log->debug("$$ mod_proxy handling request for $url") if DEBUG;

    #$r->log->debug("$$ new uri is $uri");
    $r->log->debug( "$$ unparsed uri " . $r->unparsed_uri ) if DEBUG;

    # Don't change these lines either or you'll be hurting
    if ($uri) {
        $r->uri($uri);
        $r->unparsed_uri($uri);
    }

    # Don't change this stuff either unless you are on a desert island alone
    # with a solar powered computer
    $r->filename("proxy:$url");

    $r->log->debug( "$$ filename is " . $r->filename ) if DEBUG;


    $r->handler('proxy-server'); # hrm this causes perl response as well
    $r->set_handlers(PerlResponseHandler => []);
    $r->proxyreq(1);
    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r = shift;

    ##########
    # Use perlbal to do the proxying
    $r->log->debug("Using perlbal to reproxy request") if DEBUG;
    my $uri = $r->construct_url( $r->unparsed_uri );
    $r->headers_out->add( 'X-REPROXY-URL' => $r->construct_url );
    return Apache2::Const::DONE;
}

1;

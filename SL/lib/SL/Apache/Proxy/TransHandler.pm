package SL::Apache::Proxy::TransHandler;

use strict;
use warnings;

=head1 NAME

SL::Apache::TransHandler

=head1 SYNOPSIS

Ferrets out requests that should be served by the lightweight proxy handlers

=cut

use constant DEBUG         => $ENV{SL_DEBUG}      || 0;
use constant VERBOSE_DEBUG => $ENV{VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}     || 0;
use constant REQ_TIMING    => $ENV{SL_REQ_TIMING} || 0;
use constant DEFAULT_HASH_MAC => 'f' x 8;

use SL::Config;
use SL::Model       ();
use SL::Model::URL  ();
use SL::BrowserUtil ();
use SL::Cache       ();
use SL::User        ();
use SL::Subrequest  ();
use SL::Static      ();

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE M_GET );
use Apache2::Connection  ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::ServerRec   ();
use Apache2::ServerUtil  ();
use Apache2::URI         ();

use Net::DNS ();

our $resolver = Net::DNS::Resolver->new;

our ( $Config, $Blacklist );

BEGIN {
    $Config    = SL::Config->new();
    $Blacklist = SL::Model::URL->generate_blacklist_regex;
    print STDERR "Blacklist regex is $Blacklist\n" if DEBUG;
}

our $Cache      = SL::Cache->new( type => 'raw' );
our $Subrequest = SL::Subrequest->new;
our $User       = SL::User->new;

our $TIMER;
if (TIMING) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

sub handler {
    my $r = shift;

    $r->log->debug( "$$ " . __PACKAGE__ ) if DEBUG;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url' => $url );

    #######################
    # user agent and referer
    if ( $r->pnotes('ua') eq 'none' ) {
        $r->log->debug("$$ no user agent, mod_proxy") if DEBUG;
        return &mod_proxy($r);
    }

    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->pnotes( 'referer' => $referer );

    #########################
    # our secret namespace
    $r->log->debug( "$$ checking for secret ping with " . $r->unparsed_uri )
      if DEBUG;
    if ( substr( $r->unparsed_uri, 0, 10 ) eq '/sl_secret' ) {
        $r->log->debug("$$ request url $url in secret namespace") if DEBUG;
        return Apache2::Const::OK;
    }

    #########################
    ## Handle non-browsers
    my $browser_name = SL::BrowserUtil->is_a_browser( $r->pnotes('ua') );
    if ( !$browser_name ) {
        $r->log->debug( "$$ not a browser: " . $r->as_string ) if DEBUG;
        $r->pnotes( 'not_a_browser' => 1 );
        return &mod_proxy($r);

    }
    elsif ($browser_name) {

        if ( $browser_name eq 'opera' ) {

            # sorry opera locks up on stuff
            return handle_opera_redirect($r);
        }
        else {
            $r->pnotes( 'browser_name' => $browser_name );
        }

    }

    ########################
    # we only handle GETs
    unless ( $r->method_number == Apache2::Const::M_GET ) {
        $r->log->debug("$$ not a GET request, mod_proxy") if DEBUG;
        return &mod_proxy($r);
    }

    ########################
    # http 1.1 only
    my $hostname;
    unless ( $hostname = $r->headers_in->{'Host'} ) {
        $r->log->debug("$$ no host header, mod_proxy") if DEBUG;
        return &mod_proxy($r);
    }

    ####################################
    # serving ads on hosts that are ip numbers causes problems
    if ( $hostname =~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {
        $r->log->debug("$$ hostname is ip addr $hostname, perlbal") if DEBUG;
        return &perlbal($r);
    }

    ###################################
    ## Static content
    if ( SL::Static->is_static_content( { url => $url } ) ) {
        $r->log->debug("$$ Url $url static content ext, perlbal") if DEBUG;
        return &perlbal($r);
    }

    # this for testing only!
    # $r->headers_in->{'x-sl'} = '12345678|00188bf9406f';

    #####################################
    # process the sl header
    my ( $hash_mac, $router_mac );
    if ( my $sl_header = $r->headers_in->{'x-sl'} ) {
        $r->pnotes( 'sl_header' => $sl_header );
        $r->log->debug("$$ Found sl_header $sl_header") if DEBUG;

        ( $hash_mac, $router_mac ) =
          split( /\|/, $r->pnotes('sl_header') );

        # the leading zero is omitted on some sl_headers
        if ( length($hash_mac) == 7 ) {
            $hash_mac = '0' . $hash_mac;
        }

        $r->log->error("$$ Found sl_header $sl_header")
          unless ( ( length($hash_mac) == 8 )
            && ( length($router_mac) == 12 ) );

        unless ( $router_mac && $hash_mac ) {
            $r->log->error("$$ sl_header present but no hash or router mac");
            return Apache2::Const::SERVER_ERROR;    # not really anything better
        }

        # stash these
        $r->pnotes( 'hash_mac'   => $hash_mac );
        $r->pnotes( 'router_mac' => $router_mac );

        $r->log->debug("$$ router $router_mac, hash_mac $hash_mac") if DEBUG;

        # get rid of this header so that is isn't proxied
        $r->headers_in->unset('x-sl');

    }

    # check for chitika ad
    if ( $r->hostname eq 'mm.chitika.net' ) {
        _handle_chitika_ad($r);
        return &proxy_request($r);
    }

    #############################################
    # start the clock - the stuff above is all memory
    $TIMER->start('db_mod_proxy_filters') if TIMING;

    ###################################
    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("$$ Database has gone away, sending to mod_proxy");
        return &mod_proxy($r);
    }

    ###################################
    # ok check for a splash page if we have a router_mac
    if ( $r->pnotes('sl_header') ) {
        my ( $splash_url, $timeout ) =
          SL::Model::Proxy::Router->splash_page($router_mac);

        if ($splash_url) {
            my $show_splash = handle_splash( $r, $splash_url, $timeout );
            return Apache2::Const::OK if $show_splash;
        }
    }

    #################################
    # blacklisted urls
    if ( url_blacklisted($url) ) {
        $r->log->debug("$$ url $url blacklisted") if DEBUG;
        return &proxy_request($r);
    }

    ###################################
    # check for sub-reqs if it passed the other tests
    my $is_subreq = $Subrequest->is_subrequest( url => $url );
    if ($is_subreq) {
        $r->log->debug("$$ Url $url is a subrequest, proxying") if DEBUG;
        return &proxy_request($r);
    }

    ###################################
    ## Check the cache for a static content match
    return &proxy_request($r)            if $Cache->is_known_not_html($url);
    $r->log->debug("$$ EndTranshandler") if DEBUG;

    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    unless ( $router_mac or $hash_mac ) {

        # valid request that made it through, assign default
        $r->pnotes(
            'router_mac' => SL::Model::Proxy::Router->_mac_from_ip(
                $r->connection->remote_ip
            )
        );
        $r->pnotes( 'hash_mac' => DEFAULT_HASH_MAC );
    }

    return Apache2::Const::OK;
}

# chitika minimall premium
#
# GET /minimall?w=728&h=90&client=silverlining&noctxt=4&sid=Chitika%20Premium&url=http%3A//www.silverliningnetworks.com/network/%23mortgage&type=mpu&searchref=1&vertical=premium&cb=606&required_text=overture&output=simplejs&callback=ch_ad_render_search HTTP/1.1

sub _handle_chitika_ad {
    my $r = shift;

    # require
    my $base_path = '/minimall';
    return unless $r->uri eq $base_path;

    my $args = $r->args;

    my @pairs = split( /\&/, $args );
    my %q;
    my $order = 1;
    foreach my $arg (@pairs) {
        my ( $key, $value ) = split( /\=/, $arg );
        $q{$key}{value} = $value;
        $q{$key}{order} = $order++;
    }

    # these are searches
    return if defined $q{query};

    # normalize the urls
    my $url = $q{url}{value};
    Apache2::URI::unescape_url($url);

    my $ref;
    if ( defined $q{ref} ) {
        $ref = $q{ref}{value};
        Apache2::URI::unescape_url($ref);
    }
    else {
        $q{ref}{order} = $order++;
    }

    # is the referer already a search page?
    if (   $r->pnotes('referer') =~ m/(?:www\.google\.com|search\.yahoo\.com)/ )
    {

        # let the existing referer through
        return;
    }

    # aha, fixup the chitika ad.  First grab the keywords
    my $keywords = SL::Cache->memd->get($url);

    $r->log->debug(
        "retrieved keywords for url $url, " . join( ',', @{$keywords} ) )
      if DEBUG;

    $keywords ||= [qw( flights cars vacations )];

    my $query = join( '++', @{$keywords} );

    $q{ref}{value} =
      URI::Escape::uri_escape(
"http://www.google.com/search?hl=en&q=$query&btnG=Google+Search&aq=f&oq=&type=mpu&searchref=1"
      );
    my $new_args = '';
    foreach my $key ( sort { $q{$a}{order} <=> $q{$b}{order} } keys %q ) {
        $new_args .= join( '=', $key, $q{$key}{value} ) . '&';
    }

    $r->args( substr( $new_args, 0, length($new_args) - 1 ) );

    $r->unparsed_uri( $base_path . '?' . $new_args );
    return 1;
}

sub handle_opera_redirect {
    my $r = shift;

    $r->set_handlers(
        PerlResponseHandler => ['SL::Apache::Proxy::OperaHandler'] );
    return Apache2::Const::OK;
}

sub handle_splash {
    my ( $r, $splash_url, $timeout ) = @_;

    $r->log->debug( "$$ splash $splash_url, timeout $timeout, x-sl "
          . $r->pnotes('sl_header') )
      if DEBUG;

    # aha splash page, check when the last time we saw this user was
    my $last_seen = $User->get_last_seen( $r->pnotes('sl_header') );
    $r->log->debug( "$$ last seen $last_seen seen, time " . time() )
      if ( DEBUG && defined $last_seen );

    my $set_ok = $User->set_last_seen( $r->pnotes('sl_header') );

    if ( !$last_seen
        or ( ( $timeout * 60 ) < ( time() - $last_seen ) ) )
    {

        $r->log->debug("$$ sending to splash handler for url $splash_url")
          if DEBUG;
        $r->pnotes( 'splash_url' => $splash_url );
        $r->pnotes( 'last_seen' => $last_seen ) if defined $last_seen;
        $r->set_handlers(
            PerlResponseHandler => ['SL::Apache::Proxy::SplashHandler'] );
        return 1;
    }
    else {

        return;
    }
}

sub url_blacklisted {
    my $url = shift;

    my $ping = SL::Model::URL->ping_blacklist_regex;

    if ($ping) {    # update the blacklist if it has changed

        $Blacklist = $ping;
    }

    return 1 if ( $url =~ m{$Blacklist}i );

}

sub proxy_request {
    my $r = shift;

    return &perlbal($r);
}

sub _unset_proxy_headers {
    my $r = shift;
    $r->headers_in->unset($_)
      for qw( X-Proxy-Capabilities X-SL X-Forwarded-For );

    return 1;
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
    $r->set_handlers( PerlLogHandler      => undef );

    $r->handler('proxy-server');    # hrm this causes perl response as well
    $r->proxyreq(1);

    $r->server->add_version_component('sl');    # need to patch mod_proxy

    return Apache2::Const::DECLINED;
}

sub perlbal {
    my $r = shift;

    _unset_proxy_headers($r);

    if ( $r->headers_in->{Cookie} ) {

        # sorry perlbal doesn't reproxy requests with cookies
        return mod_proxy($r);
    }

    ##########
    # Use perlbal to do the proxying
    my $uri = $r->construct_url( $r->unparsed_uri );

    my $hostname = $r->hostname;

    # don't resolve ip addresses
    unless ( $hostname =~ m/\d+\.\d+\.\d+\.\d+/ ) {
        my $ip;
        my $query = $resolver->query($hostname);
        if ($query) {
            foreach my $rr ( $query->answer ) {
                next unless $rr->type eq "A";
                $ip = $rr->address;
                last;
            }
        }
        else {
            $r->log->error( "$$ DNS query failed for host $hostname: ",
                $resolver->errorstring );
            return mod_proxy($r);
        }

        $uri =~ s/$hostname/$ip/;
        $r->log->debug("$$ ip for host $hostname is $ip, new uri is $uri")
          if DEBUG;

    }
    $r->headers_out->add( 'X-REPROXY-URL' => $uri );
    $r->set_handlers( PerlResponseHandler => undef );
    $r->set_handlers( PerlLogHandler      => undef );
    $r->log->debug("$$ X-REPROXY-URL for $uri") if DEBUG;
    return Apache2::Const::OK;
}

1;

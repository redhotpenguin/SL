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

use SL::Config;
use SL::Model             ();
use SL::Model::Proxy::URL ();

use SL::BrowserUtil ();
use SL::Cache       ();
use SL::User        ();
use SL::Subrequest  ();
use SL::Static      ();

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE M_GET REDIRECT );
use Apache2::Connection  ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::ServerRec   ();
use Apache2::ServerUtil  ();
use Apache2::URI         ();

use Net::DNS ();

our $resolver = Net::DNS::Resolver->new;

our $Google = 'http://www.google.com/';
our $Yahoo  = 'http://www.yahoo.com/';
our $Youtube  = 'http://www.youtube.com/';
our ( $Config, $Blacklist );

BEGIN {
    $Config    = SL::Config->new();
    $Blacklist = SL::Model::Proxy::URL->generate_blacklist_regex;
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

    $r->log->debug( "$$ " . __PACKAGE__ ) if VERBOSE_DEBUG;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url' => $url );

    #######################
    # user agent and referer
    if ( $r->pnotes('ua') eq 'none' ) {
        $r->log->debug("$$ no user agent, mod_proxy") if DEBUG;
        return &perlbal($r);
    }

    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->pnotes( 'referer' => $referer );

    #########################
    # our secret namespace
    $r->log->debug( "checking for secret ping with " . $r->unparsed_uri )
      if VERBOSE_DEBUG;
    if ( substr( $r->unparsed_uri, 0, 10 ) eq '/sl_secret' ) {
        $r->log->debug("url $url in secret namespace") if VERBOSE_DEBUG;
        return Apache2::Const::OK;
    }

    #########################
    ## Handle non-browsers
    my $browser_name = SL::BrowserUtil->is_a_browser( $r->pnotes('ua') );
    if ( !$browser_name ) {
        $r->log->debug( "$$ not a browser: " . $r->as_string ) if DEBUG;
        $r->pnotes( 'not_a_browser' => 1 );
        return &perlbal($r);

    }
    elsif ($browser_name) {

        $r->pnotes( 'browser_name' => $browser_name );

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
        return &perlbal($r);
    }

    ####################################
    # serving ads on hosts that are ip numbers causes problems
    if ( $hostname =~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {
        $r->log->debug("$$ hostname is ip addr $hostname, perlbal") if DEBUG;
        return &redirect($r);
    }

    ###################################
    ## Static content
    if ( SL::Static->is_static_content( { url => $url } ) ) {
        $r->log->debug("$$ Url $url static content ext, port redir") if DEBUG;

        return &redirect($r);
    }

    #############################################
    # start the clock - the stuff above is all memory
    $TIMER->start('db_mod_proxy_filters') if TIMING;

    ###################################
    # first check that a database handle is available
    my $dbh = SL::Model->connect();
    unless ($dbh) {
        $r->log->error("$$ Database has gone away, sending to mod_proxy");
        return &perlbal($r);
    }

    ###################################
    # ok check for a splash page if we have a router_id
=cut
	if ( $r->pnotes('router_id') ) {

        my ( $splash_url, $timeout ) =
          SL::Model::Proxy::Router->splash_page($r->pnotes('router_id'));

        if ($splash_url && $splash_url ne '') {
            my $show_splash = handle_splash( $r, $splash_url, $timeout );
            return Apache2::Const::OK if $show_splash;
        }
    }
=cut
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
	if ((($url ne $Google) and ($url ne $Yahoo) and ($url ne $Youtube) ) && $Cache->is_known_not_html($url)) {

	    return &redirect($r)
	}

    $r->log->info(
        sprintf( "timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

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

    return 1 if ( $url =~ m{$Blacklist}i );

}

sub proxy_request {
    my $r = shift;

	#return &redirect($r);

    return &perlbal($r);
}

sub _unset_proxy_headers {
    my $r = shift;
    $r->headers_in->unset($_)
      for qw( X-Proxy-Capabilities X-SL X-SLR X-Forwarded-For );

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

sub redirect {
    my ( $r, $uri ) = @_;

    die("oops called proxy redirect without \$r") unless ($r);

    my $newurl = URI->new( $r->pnotes('url') );
    $newurl->port(8135);

    $r->log->debug( "$$ new url is " . $newurl->as_string ) if DEBUG;

    $r->headers_out->set( Location => $newurl->as_string );
    $r->server->add_version_component('sl');
    $r->no_cache(1);

    $r->set_handlers( PerlResponseHandler => undef );
    $r->set_handlers( PerlLogHandler      => undef );

    return Apache2::Const::REDIRECT;
}



sub perlbal {
    my $r = shift;

    _unset_proxy_headers($r);

    if ( $r->headers_in->{Cookie} ) {

	$r->log->debug("cookies present, mod_proxy") if DEBUG;
        # sorry perlbal doesn't reproxy requests with cookies
        return mod_proxy($r);
    }

    ##########
    # Use perlbal to do the proxying
    my $uri = $r->construct_url( $r->unparsed_uri );

    my $hostname = $r->hostname;

    # don't resolve ip addresses
    unless ( $hostname && ($hostname =~ m/\d+\.\d+\.\d+\.\d+/ )) {

        my $router = $r->pnotes('router');
        my $ip = eval { SL::DNS->resolve($hostname, $router->{dnsone}); };
        if ($@ or !$ip) {
            $r->log->error( "$$ DNS query failed for host $hostname: $@");
            return mod_proxy($r);
        }

		unless ($hostname && $ip) {
			$r->log->error("failed to resolve hostname hostname, ip $ip");
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

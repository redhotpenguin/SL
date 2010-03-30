package SL::Proxy::Search::TransHandler;

use strict;
use warnings;

=head1 NAME

SL::Proxy::Search::TransHandler

=head1 SYNOPSIS

Ferrets out requests that should be served by the lightweight proxy handlers

=cut

use constant DEBUG         => $ENV{SL_DEBUG}      || 0;
use constant VERBOSE_DEBUG => $ENV{VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}     || 0;
use constant REQ_TIMING    => $ENV{SL_REQ_TIMING} || 0;

use SL::Config;
use SL::BrowserUtil ();

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

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url' => $url );

	$r->log->debug( "$$ " . __PACKAGE__ . " url $url" ) if DEBUG;

    #######################
    # user agent and referer
    if ( $r->pnotes('ua') eq 'none' ) {
        $r->log->debug("$$ no user agent, mod_proxy") if DEBUG;
        return proxy($r);
    }

    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->pnotes( 'referer' => $referer );

    #########################
    # our secret namespace
    $r->log->debug( "$$ checking for secret ping with " . $r->unparsed_uri )
      if VERBOSE_DEBUG;
    if ( substr( $r->unparsed_uri, 0, 10 ) eq '/sl_secret' ) {
        $r->log->debug("$$ url $url in secret namespace") if DEBUG;
        return Apache2::Const::OK;
    }

    #########################
    ## Handle non-browsers
    my $browser_name = SL::BrowserUtil->is_a_browser( $r->pnotes('ua') );
    if ( !$browser_name ) {
        $r->log->debug( "$$ not a browser: " . $r->as_string ) if DEBUG;
        $r->pnotes( 'not_a_browser' => 1 );
        return proxy($r);

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
    my $hostname = $r->headers_in->{'Host'};
    unless ( defined $hostname  &&
        $hostname !~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {

        $r->log->error("$$ no host header, mod_proxy") if DEBUG;
        return proxy($r);
    }



    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

	$r->log->debug("$$ sending to response handler") if DEBUG;
    return Apache2::Const::OK;
}


sub mod_proxy {
    my ( $r, $uri ) = @_;

    die("oops called proxy_request without \$r") unless ($r);

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



sub proxy {
    my $r = shift;

    my $uri = $r->construct_url( $r->unparsed_uri );
	$r->log->debug("proxying request for $uri") if DEBUG;

    if ( $r->headers_in->{Cookie} ) {

		$r->log->debug("cookies present, mod_proxy not perlbal") if DEBUG;

        # sorry perlbal doesn't reproxy requests with cookies
        return mod_proxy($r);
    }

    # don't resolve ip addresses
    my $hostname = $r->hostname;
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

    $r->log->debug("$$ perlbal X-REPROXY-URL for $uri") if DEBUG;

    return Apache2::Const::OK;
}

1;

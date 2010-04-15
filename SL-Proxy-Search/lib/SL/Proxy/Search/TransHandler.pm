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

use SL::Config ();
use SL::DNS    ();
use SL::Proxy::Cache  ();
use SL::Static ();

use Apache2::Const -compile =>
  qw( OK SERVER_ERROR NOT_FOUND DECLINED CONN_KEEPALIVE DONE M_GET REDIRECT );
use Apache2::Connection  ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::ServerRec   ();
use Apache2::ServerUtil  ();
use Apache2::URI         ();

use URI ();
use URI::Escape ();
use Data::Dumper qw(Dumper);

our $Config = SL::Config->new();
our $Cache  = SL::Proxy::Cache->new();

our $TIMER;
if (TIMING) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

our $Gpartner_code = $Config->sl_gpartner_code;
our $Gpartner_url  = $Config->sl_gpartner_url;

sub handler {
    my $r = shift;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url' => $url );

    $r->log->debug( "$$ " . __PACKAGE__ . " url $url" ) if DEBUG;

    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->pnotes( 'referer' => $referer );

    if ($r->hostname eq 'mm.chitika.net') {

#	my $headers_in = $r->headers_in();
#	$r->log->debug("headers_in original: " . Dumper($headers_in)) if DEBUG;
#	$headers_in->{Referer} =~ s/google/silverliningnetworks/;
#	$r->headers_in($headers_in);
#	$r->log->debug("headers_in processed: " . Dumper($headers_in)) if DEBUG;

	# what the hell are you doing boy?  just intercept /search
#	my $uri = $r->unparsed_uri;
	#$uri =~ s/xyzzy/search/;
#	$uri =~ s/google/silverliningnetworks/;
#	$r->unparsed_uri($uri);

#	my $hostname = $r->hostname;
#	$hostname =~ s/google/silverliningnetworks/;
#	$r->hostname($hostname);

 #       $r->log->debug("chitika request: " . $r->as_string) if DEBUG;

	# have chitika handle it

        $r->log->debug("chitika handler found.") if DEBUG;
        $r->set_handlers( PerlResponseHandler => 'SL::Proxy::Search::Chitika' );
        return Apache2::Const::OK;
	return proxy($r);
    }

    return proxy($r) unless $r->hostname eq 'www.google.com';

    # search response handler
    if (substr($r->uri, 1, 7) eq 'search') {

        $r->log->debug("search handler found.") if DEBUG;
        $r->set_handlers( PerlResponseHandler => 'SL::Proxy::Search' );
        return Apache2::Const::OK;
    }

    ########################
    # we only handle GETs
    unless ( $r->method_number == Apache2::Const::M_GET ) {
        $r->log->debug("$$ not a GET request, mod_proxy") if DEBUG;
        return proxy($r);
    }

    if (($r->uri eq '/url') or ($r->uri eq '/aclk')) {

        return proxy($r);
    }


    #######################################
    ## Check the cache for the content type
    if ( $Cache->is_known_not_html($url)) {

	# non html content
        return proxy($r);
#	return serve_cached($r);
    }

    ########################
    # http 1.1 only
    my $hostname = $r->headers_in->{'Host'};
    unless ( defined $hostname  &&
        $hostname !~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {

        $r->log->debug("$$ no host header, mod_proxy") if DEBUG;
        return proxy($r);
    }

    ###################################
    ## Static content                           
    if ( SL::Static->is_static_content( { url => $url } ) ) {
        $r->log->debug("$$ Url $url static content ext, port redir") if DEBUG;

        return proxy($r);
    }

    ###################################
    # fixup google search urls
    $r->log->debug("$$ unparsed uri: " . $r->unparsed_uri) if DEBUG;

    if (($r->uri eq '/search') or ($r->uri eq '/m/search')) {

	my $uri = $r->unparsed_uri;
	# grab the q param from the query string
	my ($q) = $uri =~ m/[&]?q=([^&]+)[&]?/;
	$r->log->debug("My query is $q") if DEBUG;

=cut
	my $dest = 'http://www.google.com/cse?cx=%s&ie=ISO-8859-1&q=%s&sa=Search&siteurl=%s';

	$dest = sprintf($dest, $Gpartner_code, $q, $Gpartner_url);
=cut
	# remove up to the args
	$uri =~ s/^([^?]+)\?//g;

	# escape the uri
        #$uri = URI::Escape::uri_escape($uri);
	my $dest = "http://www.google.com/search?$uri";

        $r->headers_out->set( Location => $dest );
	return Apache2::Const::REDIRECT;

    }

    $r->log->info(
        sprintf( "$$ timer $$ %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;


    return proxy($r);
}

sub redirect {
    my $r = shift;

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

    if ( $r->headers_in->{Cookie} ) {

        $r->log->debug("cookies present, handing to SL::Proxy") if DEBUG;

        # sorry perlbal doesn't reproxy requests with cookies
        $r->set_handlers( PerlResponseHandler => 'SL::Proxy->handler' );
        return Apache2::Const::OK;
    }

    $r->log->debug("perlbal handling request for $uri") if DEBUG;

    # don't resolve ip addresses
    my $hostname = $r->hostname;
    unless ( $hostname && ($hostname =~ m/\d+\.\d+\.\d+\.\d+/ )) {

        my ($ip) = eval { SL::DNS->resolve({hostname => $hostname,
                                            cache    => $Cache, }) };
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
    $r->log->debug("$$ X-REPROXY-URL for $uri") if DEBUG;
    return Apache2::Const::OK;
}

1;

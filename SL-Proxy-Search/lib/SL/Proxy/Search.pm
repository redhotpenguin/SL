package SL::Proxy::Search;

use strict;
use warnings;

=head1 NAME

SL::Proxy::Search

=head1 SYNOPSIS

Ferrets out requests that should be served by the lightweight proxy handlers

=cut

our $VERSION = 0.04;

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
use Apache2::Request     ();

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

sub handler {
    my $r = shift;

    my $url = $r->construct_url( $r->unparsed_uri );
    $r->pnotes( 'url' => $url );

    my $referer = $r->headers_in->{'referer'} || 'no_referer';
    $r->pnotes( 'referer' => $referer );

    return proxy($r) unless ($r->hostname eq 'www.google.com')
        or ($r->hostname eq 'search.yahoo.com')
        or ($r->hostname eq 'www.bing.com');

    my $req = Apache2::Request->new($r);

    # search response handler
    if (substr($r->uri, 1, 7) eq 'search') {


        my $uri = $r->unparsed_uri;
        my $q = $req->param('q');
        $q =~ s/ /\+/g;

        my $location = $Config->sl_search_href . 'q=' . $q;
        $r->headers_out->set( Location => $location );
        $r->no_cache(1);
    
        return Apache2::Const::REDIRECT;

    } else {

        # proxy the request
        return proxy($r);
    }
}

sub proxy {
    my $r = shift;

    my $uri = $r->construct_url( $r->unparsed_uri );

    if ( $r->headers_in->{Cookie} ) {

        $r->log->debug("cookies present, SL::Proxy") if VERBOSE_DEBUG;

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
            $r->set_handlers( PerlResponseHandler => 'SL::Proxy->handler' );
            return Apache2::Const::OK;
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

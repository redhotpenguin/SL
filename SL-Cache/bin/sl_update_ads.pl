#!/usr/bin/perl

use strict;
use warnings;

use SL::Cache;
use SL::Config;
use HTTP::Date;
use LWP::UserAgent;

my $UA        = LWP::UserAgent->new;
my $CONFIG    = SL::Config->new;
my $DEBUG     = 0;
my $CACHE     = SL::Cache->new->ad_cache;
my $cache_key = 'if_last_modified_ads';

if ( my $last = $CACHE->get($cache_key) ) {

    # set the header
    $UA->headers->header( 'If-Last-Modified' => time2str( time() ) );
    warn("$cache_key is $last") if $DEBUG;
}
else {

    # mark the cache
    $CACHE->set( $cache_key => time2str( time() ) );
    warn("$cache_key not set, setting");
}

my $res = $UA->get( join ( '/', $CONFIG->sl_cache_url, 'ads' ) );

if ( $res->code == 304 ) {
    warn('304 response, up to date') if $DEBUG;
    exit(0);
}
elsif ( $res->code == 200 ) {
    $CACHE->set( 'if_last_modified_ads' => time2str( time() ) );
    warn( "200 received, content is " . $res->content ) if $DEBUG;
    my $ads_hashref = $CACHE->deserialize( $res->content );
    $CACHE->update_ads( $ads_hashref );

    exit(0);
}
else {
    warn( "received response code " . $res->code );
    warn( "received response content " . $res->content );
    exit(1);
}

1;

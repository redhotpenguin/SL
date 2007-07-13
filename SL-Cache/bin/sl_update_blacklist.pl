#!/usr/bin/perl

use strict;
use warnings;

use SL::Cache;
use SL::Config;
use HTTP::Date;
use LWP::UserAgent;

my $UA     = LWP::UserAgent->new;
my $CONFIG = SL::Config->new;
my $DEBUG  = 0;
my $CACHE  = SL::Cache->new->data_cache;

# grab the blacklist regex
if ( my $last = $CACHE->get('if_last_modified_blacklist') ) {

    # set the header
    $UA->headers->header( 'If-Last-Modified' => time2str( time() ) );
    warn("if_last_modified_blacklist is $last") if $DEBUG;
}
else {

    # mark the cache
    $CACHE->set( 'if_last_modified_blacklist' => time2str( time() ) );
    warn("if_last_modified_blacklist not set, setting");
}

my $res = $UA->get( join ( '/', $CONFIG->sl_cache_url, 'blacklist' ) );

if ( $res->code == 304 ) {
    warn('304 response, regex is up to date') if $DEBUG;
    exit(0);
}
elsif ( $res->code == 200 ) {
    $CACHE->set( blacklist_regex              => $res->content );
    $CACHE->set( 'if_last_modified_blacklist' => time2str( time() ) );
    warn( "200 received, regex is " . $res->content ) if $DEBUG;
}
else {
    warn( "received response code " . $res->code );
    warn( "received response content " . $res->content );
    exit(1);
}

1;

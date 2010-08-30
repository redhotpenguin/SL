#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('WebService::Yahoo::BOSS') }

can_ok( 'WebService::Yahoo::BOSS', qw( Web ) );

SKIP: {
    skip "ENV{YAHOO_APPID} not defined", 2, unless $ENV{YAHOO_APPID};

    my $boss = WebService::Yahoo::BOSS->new( appid => $ENV{YAHOO_APPID} );
    isa_ok( $boss, 'WebService::Yahoo::BOSS' );
    my $search = $boss->Web( query => 'sushi' );
    isa_ok( $search->[0], 'WebService::Yahoo::BOSS::Result' );
}

#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('WebService::LinkShare');
    can_ok( 'WebService::LinkShare', qw( new targeted_merchandise ) );
}

eval { WebService::LinkShare->new };
ok( $@, 'exception thrown' );

SKIP: {
    skip 'set $ENV{LINKSHARE_APITOKEN} for live tests', 2
      unless $ENV{LINKSHARE_APITOKEN};

    my $linkshare =
      WebService::LinkShare->new( { token => $ENV{LINKSHARE_APITOKEN} } );

    isa_ok( $linkshare, 'WebService::LinkShare' );

    diag('we need some pet meds');

    my $mid = 2101;    # 1-800-pet-meds

    my $res = $linkshare->targeted_merchandise( { advertiser_mid => $mid } );
    isa_ok( $res, 'HASH' );
}
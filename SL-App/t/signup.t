#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;    # last test to print

use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;

my $host = shift or die "$0 http://127.0.0.1/\n";

my $res = $mech->get_ok("$host/signup");

# basic test
$res = $mech->submit_form(
    form_number => 1,
    fields      => {
        email         => 'phredwolf@yahoo.com',
        password      => 'yomaing',
        retype        => 'yomaing',
        #router_mac    => '00:17:f2:43:38:bd',
        router_mac    => '0017f24338bd',
        serial_number => 'CL7C1H201917',
    }
);

cmp_ok( $res->code, '==', 200, 'ok return' );

$mech->title_like( qr/Announcements/i, 'check for home page' );
$mech->content_contains( 'Announcements', 'announcements' );
use strict;
use warnings;

use Test::More;
plan('no_plan');

use SL::Test;

my $test = SL::Test->new;
my $mech = $test->mech;

my $url = "http://app.redhotpenguin.com/apache_pb.gif";

$mech->get_ok( $url, "Retrieving url $url" );
cmp_ok( $mech->response->content_type, 'eq', "image/gif", "Check image/gif");

$url = "http://app.redhotpenguin.com";
$test = SL::Test->new;
$mech = $test->mech;

$mech->get_ok( $url, "Retrieving url $url" );
cmp_ok( $mech->response->content_type, 'eq', "text/html", "Check content type");
$mech->content_like( qr/SilverLining/i, "Check for SilverLining ad signature");


use strict;
use warnings;

use Test::More;
plan('no_plan');
use SL::Test;

my $test = SL::Test->new;
my $mech = $test->mech;

my $url = "http://www.opera.com/";

$mech->get_ok( $url, "Retrieving url $url" );
SKIP: {
    skip "No ad served", 1, ( $mech->content =~ m/\.css/ );
    $mech->content_like( qr/SilverLining/i, "Check for SilverLining ad");
}

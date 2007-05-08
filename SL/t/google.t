use strict;
use warnings;

use Test::More;
plan('no_plan');
use SL::Test;

my $test = SL::Test->new;
my $mech = $test->mech;

my $url = "http://www.google.com/";

$mech->get_ok( $url, "Retrieving url $url" );
$mech->content_like( qr/SilverLining/i, "Check for SilverLining ad signature");

# Run a search
$mech->submit_form(
    form_number => 1,
    fields => {
        search => "Paris Hilton",
    },
);

cmp_ok( $mech->response, "==", "200", "Request returned 200 response code");
$mech->content_like( qr/silverlining/i, "Check for SL signature");


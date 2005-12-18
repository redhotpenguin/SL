use strict;
use warnings;

use Test::More;
plan('no_plan');
use SL::Test;

my $test = SL::Test->new;
my $mech = $test->mech;
$mech->proxy('http', 'http://192.168.1.1:8888');

my $url = "http://www.google.com/";

$mech->get_ok( $url, "Retrieving url $url" );
$mech->content_like( qr/SilverLining/i, "Check for SilverLining ad signature");

# Run a search
$mech->update_html( $mech->content );
$mech->submit_form(
    form_number => 1,
    fields => {
        q => "Paris Hilton",
    },
    button => 'btnG',
);

cmp_ok( $mech->response->code, "==", "200", "Request returned 200 response code");
$mech->content_like( qr/silverlining/i, "Check for SL signature");


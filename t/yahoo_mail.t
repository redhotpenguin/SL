use strict;
use warnings;

use Test::More;
plan('no_plan');
use SL::Test;

my $test = SL::Test->new;
my $mech = $test->mech;

print "Testing webmail interface\n";

$mech->get_ok( "http://mail.yahoo.com", "Retrieving url" );
SKIP: {
    skip "No ad served", 1, ( $mech->content =~ m/\.css/ );
    $mech->content_like( qr/SilverLining/i, "Check for SilverLining ad");
}

my $username = "guntherhust";
my $password = "123456";

### HACK ALERT - for some reason $mech->forms returns undef unless updated
$mech->update_html( $mech->content );

$mech->submit_form(
    form_number => 1,
    fields => {
        login => $username,
        passwd => $password,
    },
);

cmp_ok( $mech->response->code, "==", "200", "Check 200 response code" );

# Yahoo hands us a meta redirect page
$mech->content_like( qr/meta http-equiv="?Refresh"?/i, "Check redirect");

$mech->follow_link( n => 1 );

sleep 1;


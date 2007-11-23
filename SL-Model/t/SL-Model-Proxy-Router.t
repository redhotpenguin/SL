use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

my $pkg;

BEGIN {
    $pkg = 'SL::Model::Proxy::Router';
    use_ok($pkg);
}

can_ok( $pkg, qw( replace_port add_router_from_mac splash_page ) );

use SL::Model;

my $dbh = SL::Model->connect or die 'no db connection!';
my $mac = $dbh->selectcol_arrayref("SELECT macaddr from router limit 1")->[0];

my $splash_href = SL::Model::Proxy::Router->splash_page($mac);

1;

#!perl -w

use strict;
use warnings;

use RPC::XML;
use RPC::XML::Client;

$RPC::XML::ENCODING = 'UTF-8';

my $login_url = '/LogonXmlRpcService.php';
my $url = 'http://127.0.0.1/openx/www/api/v1/xmlrpc/';
my $cli = RPC::XML::Client->new( $url . $login_url);

my $username = 'redhotpenguin';
my $password = 'yomaing';

my $res = $cli->send_request( 'logon', $username, $password );

print STDERR $res->as_string . "\n";

my $sid = $res->value;

my $uri = 'AgencyxmlRpcService.php';
$cli = RPC::XML::Client->new( $url . $uri);
$res = $cli->send_request( 'getAgencyList', $sid);

my @agency_ids = map { $_->{agencyId}->value } @{ $res };

$uri = 'PublisherXmlRpcService.php';
$cli = RPC::XML::Client->new( $url . $uri );
$res = $cli->send_request( 'getPublisherListByAgencyId', $sid, $agency_ids[0] );

my @publisher_ids = map { $_->{publisherId}->value } @{ $res };

my $zone_url = 'ZoneXmlRpcService.php';
$cli = RPC::XML::Client->new( $url . $zone_url);
$res = $cli->send_request( 'getZoneListByPublisherId', $sid, 1);

$res = $cli->send_request( 'getZone', $sid, $res->[0]->{zoneId}->value);


print STDERR $res->as_string . "\n";

sleep 1;



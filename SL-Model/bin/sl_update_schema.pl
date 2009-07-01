#!perl -w

use strict;
use warnings;

use DBI;
my $db_options = {
    RaiseError         => 0,
    PrintError         => 1,
    AutoCommit         => 1,
    FetchHashKeyName   => 'NAME_lc',
    ShowErrorStatement => 1,
    ChopBlanks         => 1,
};

use FindBin qw($Bin);
my $sql_root = "$Bin/../sql/table";

my $db = shift or die "gimme a database name yo\n";
my $host = shift or die "gimme a hostname yo\n\n";

my $dsn = "dbi:Pg:dbname='$db'";
my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );

use SL::Model::App;

# get to work

##############################

$dbh->do("alter table ad_zone add column image_href text");
$dbh->do("alter table ad_zone add column link_href text");
$dbh->do("alter table ad_zone add column weight integer default 1");
$dbh->do("update ad_size set grouping='8' where ad_size_id=23");
$dbh->do("update ad_size set grouping=9 where ad_size_id in (20,21)");

# move all the bugs into ad zones
my @bugs = SL::Model::App->resultset('Bug')->all;

foreach my $bug ( @bugs ) {

    next unless (($bug->ad_size_id == 22) or ($bug->ad_size_id == 23));

    warn("transforming bug for account " . $bug->account->name);

    my $name = "Branding Image from bug id " . $bug->bug_id;
    $dbh->do(<<SQL, {}, ($name,$bug->account_id, $bug->ad_size_id,14, $bug->image_href, $bug->link_href, 't'));
INSERT INTO AD_ZONE
(code,name,account_id,ad_size_id,reg_id,image_href,link_href, is_default)
VALUES
( '', ?,   ?,         ?,         ?,     ?,         ?, ? )
SQL

    # get the ad zone id of the new bug => zone
    my $ad_zone_id = $dbh->selectall_arrayref(<<SQL, {Slice => {}}, $name)->[0]->{ad_zone_id};
SELECT ad_zone_id FROM ad_zone WHERE name  = ?
SQL

    warn("new ad zone for account bug, zone id $ad_zone_id");

    my $routers = $dbh->selectall_arrayref(<<SQL, {Slice => {}}, $bug->account_id);
SELECT router_id from router where account_id = ?
SQL

    foreach my $router_id (@{$routers}) {

        warn("new router ad zone for router $router_id, zone $ad_zone_id");
        $dbh->do(sprintf("insert into router__ad_zone (router_id, ad_zone_id) values ( %s, %s ) ", $router_id->{router_id}, $ad_zone_id));

    }

}

warn("finished");

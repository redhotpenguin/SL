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

# get to work

##############################

$dbh->do("alter table ad_zone add column image_href text");
$dbh->do("alter table ad_zone add column link_href text");
$dbh->do("alter table ad_zone add column weight integer default 1");
$dbh->do("update ad_size set grouping='8' where ad_size_id=23");
$dbh->do("update ad_size set grouping=9 where ad_size_id in (20,21)");

# move all the bugs into ad zones
my $bugs = $dbh->selectall_arrayref(<<SQL, { Slice => {} } );
SELECT * FROM bug
SQL

foreach my $bug ( @{$bugs} ) {

    next if (($bug->ad_size_id == 22) or ($ad_size_id == 23));

    $dbh->do(<<SQL, {}, ($bug->{account_id}, 14, $bug->{image_href}, $bug->{link_href}));
INSERT INTO AD_ZONE
(code,name,account_id,ad_size_id,reg_id,image_href,link_href)
VALUES
( '', 'Branding Image',   ?,         22,         ?,     ?,         ? )
SQL


    my $ad_zone_ids = $dbh->selectall_arrayref(<<SQL, {Slice => {}}, $bug->{bug_id} );
SELECT ad_zone_id FROM ad_zone WHERE bug_id = ?
SQL

    my $bug_id = $dbh->selectrow_arrayref("SELECT ad_zone_id from ad_zone, ad_size where ad_zone.ad_size_id=ad_size.ad_size_id AND ad_size.grouping = 2")->[0];
    foreach my $ad_zone_id (@{$ad_zone_ids}) {
      $dbh->do("update ad_zone set is_default='t' where ad_zone_id = $bug_id");

      my $radzones = $dbh->selectall_arrayref(<<SQL, {Slice => {}}, $ad_zone_id->{ad_zone_id});
SELECT router_id from router__ad_zone where ad_zone_id = ?
SQL
      foreach my $radzone ( @{$radzones}) {

        $dbh->do(sprintf("insert into router__ad_zone (router_id, ad_zone_id) values ( %s, %s ) ", $radzone->{router_id},
                         $radzone->{ad_zone_id}));

      }


    }



}

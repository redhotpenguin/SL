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

my $dsn = "dbi:Pg:dbname='$db';";
my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );

# get to work
# ad_group first
$dbh->do(
"alter table ad_group add column css_url text default 'http://www.redhotpenguin.com/css/sl.css' NOT NULL"
  )
  or die $DBI::errstr;
$dbh->do(
"alter table ad_group add column template text default 'text_ad.tmpl' NOT NULL"
  )
  or die $DBI::errstr;

# occ
$dbh->do(
"update ad_group set css_url = 'http://www.redhotpenguin.com/css/sl.css' where name = 'occ'"
  )
  or die $DBI::errstr;
$dbh->do("update ad_group set template = 'occ.tmpl' where name = 'occ'")
  or die $DBI::errstr;

# drop the template column on ad_sl
$dbh->do("alter table ad_sl drop column template") or die $DBI::errstr;

# add tag to subrequest
$dbh->do(
    "alter table subrequest add column tag varchar(10) default '' NOT NULL")
  or die $DBI::errstr;

# create location
my $fh;
open( $fh, '<', "$sql_root/location.sql" ) or die $!;
my $sql = do { local $/; <$fh> };
$dbh->do($sql) or die $DBI::errstr;

# create router__location
open( $fh, '<', "$sql_root/router__location.sql" ) or die $!;
$sql = do { local $/; <$fh> };
$dbh->do($sql) or die $DBI::errstr;

# migrate router info to location
$sql = "select * from router";
my $sth = $dbh->prepare($sql);
$sth->execute or die $DBI::errstr;
while ( my $row = $sth->fetchrow_hashref ) {
    my $other_sql =
"INSERT INTO location (ip, name, default_ok, custom_rate_limit) values (?, ?, ?, ?)";
    my $other_sth = $dbh->prepare($other_sql);
    $other_sth->bind_param( 1, $row->{ip} );
    $other_sth->bind_param( 2, $row->{name} || '' );
    $other_sth->bind_param( 3, $row->{default_ok} );
    $other_sth->bind_param( 4, $row->{custom_rate_limit} );
    $other_sth->execute or die $DBI::errstr;
}

# populate router__location
$sth->execute or die $DBI::errstr;
while ( my $row = $sth->fetchrow_hashref ) {
    my $loc_sql = "select location_id from location where ip = ?";
    my $loc_sth = $dbh->prepare($loc_sql);
    $loc_sth->bind_param( 1, $row->{ip} );
    $loc_sth->execute or die $DBI::errstr;
    my $location_id = $loc_sth->fetchrow_arrayref->[0];

    my $other_sql =
      "INSERT INTO router__location (location_id, router_id) VALUES (?, ?)";
    my $other_sth = $dbh->prepare($other_sql);
    $other_sth->bind_param( 1, $location_id );
    $other_sth->bind_param( 2, $row->{router_id} );
    $other_sth->execute or die $DBI::errstr;
}

# prune router table
foreach my $col
  qw( ip name description street_addr apt_suite referer code custom_rate_limit feed_enabled default_ok)
{
    $dbh->do("alter table router drop column $col") or die $DBI::errstr;
}

# location__ad_group
open( $fh, '<', "$sql_root/location__ad_group.sql" ) or die $!;
$sql = do { local $/; <$fh> };
$dbh->do($sql) or die $DBI::errstr;

1;

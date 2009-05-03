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

##############################
$dbh->do("alter table account drop column aaa");
$dbh->do("alter table account add plan text not null default 'free'");
$dbh->do("alter table reg add column first_name text not null default ''");
$dbh->do("alter table reg add column last_name text not null default ''");
$dbh->do("alter table reg add column street text not null default ''");
$dbh->do("alter table reg add column city text not null default ''");
$dbh->do("alter table reg add column state text not null default ''");
$dbh->do("alter table reg add column zip text not null default ''");
$dbh->do("alter table reg add column card_last_four text not null default ''");
$dbh->do("alter table reg add column card_type text not null default ''");
$dbh->do("alter table reg add column card_expires text not null default ''");

$dbh->do("alter table location drop column custom_rate_limit");
$dbh->do("alter table location drop column default_ok");
$dbh->do("alter table location drop column state");
$dbh->do("alter table location drop column city");
$dbh->do("alter table location drop column zip");
$dbh->do("alter table location drop column apt_suite");
$dbh->do("alter table location drop column street_addr");
$dbh->do("alter table location drop column description");
$dbh->do("alter table location drop column name");

$dbh->do("alter table router drop column openmesh_macaddr");





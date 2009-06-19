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
$dbh->do("update ad_size set grouping='8' where ad_size_id=23");
$dbh->do("update ad_size set grouping=9 where ad_size_id in (20,21)");

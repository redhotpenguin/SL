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

my $dsn = "dbi:Pg:dbname='$db';host='$host'";

my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );


# get to work

##############################
use SL::Model::App;
$dbh->do("alter table ad_size add column swap boolean default 'f'");
$dbh->do("update ad_size set width=728,height=90,swap='t', grouping=3 where ad_size_id=1");
$dbh->do("update ad_size set width=468,height=60,swap='t', grouping=13 where ad_size_id=2");
$dbh->do("update ad_size set width=120,height=600,swap='t', grouping=18 where ad_size_id=4");
$dbh->do("update ad_size set width=160,height=600,swap='t', grouping=4 where ad_size_id=5");
$dbh->do("update ad_size set width=300,height=600,swap='t', grouping=5 where ad_size_id=6");
$dbh->do("update ad_size set width=300,height=250,swap='t', grouping=1 where ad_size_id=15");
$dbh->do("update ad_size set width=250,height=250,swap='t', grouping=8 where ad_size_id=16");
$dbh->do("update ad_size set width=240,height=400,swap='t', grouping=9 where ad_size_id=17");
$dbh->do("update ad_size set width=336,height=280,swap='t', grouping=10 where ad_size_id=18");
$dbh->do("update ad_size set width=180,height=150,swap='t', grouping=2 where ad_size_id=19");
$dbh->do("update ad_size set width=120,height=90,swap='t', grouping=15 where ad_size_id=20");
$dbh->do("update ad_size set width=120,height=60,swap='t', grouping=6 where ad_size_id=21");
$dbh->do("update ad_size set width=88,height=31,swap='t', grouping=7 where ad_size_id=24");



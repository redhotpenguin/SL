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

$dbh->do("drop table bug");
$dbh->do("drop table paypal_attempt");
$dbh->do("alter table account add column map_center text not null default 94109");
$dbh->do("alter table account add column map_zoom integer not null default 10");
$dbh->do("alter table account add column users_lastmonth integer not null default 0");
$dbh->do("alter table account add column megabytes_lastmonth integer not null default 0");
$dbh->do("alter table router add column users_daily integer not null default 0");


warn("finished");

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
$dbh->do("alter table ad_size add column height integer not null default 0");
$dbh->do("alter table ad_size add column width integer not null default 0");


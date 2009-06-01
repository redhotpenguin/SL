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

my $dsn = "dbi:Pg:dbname='$db';hostname=$host;";
my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );

# get to work

##############################

$dbh->do("alter table router add column notes text not null default ''");
$dbh->do("alter table router add lat float8");
$dbh->do("alter table router add lng float8");
$dbh->do("alter table router add column ip inet");

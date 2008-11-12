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
warn("dropping old payment table");
$dbh->do("drop table payment");

warn("loading new payment table");
`psql -d $db -f $sql_root/payment.sql`;

$dbh->do("alter table usr add column name text");
$dbh->do("alter table usr add column email text");

$dbh->do("alter table router add column wan_ip inet");
$dbh->do("alter table router add column lan_ip inet");

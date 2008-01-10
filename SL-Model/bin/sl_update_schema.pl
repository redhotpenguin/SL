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

warn('alter the reg table');
$dbh->do("alter table reg add column paypal_id character varying(64) DEFAULT ''::character varying");
$dbh->do("alter table reg add column payment_threshold integer not null default 5");

warn("loading payment table");
`psql -d $db -f $sql_root/payment.sql`;

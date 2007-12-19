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

warn('location');
$dbh->do("alter table click add column location_id integer DEFAULT 1");
$dbh->do("ALTER TABLE ONLY click ADD CONSTRAINT location_id_fkey FOREIGN KEY (location_id) REFERENCES location(location_id) ON UPDATE CASCADE ON DELETE CASCADE");
$dbh->do("update click set location_id = ( select location_id from location where ip = click.ip)");

warn('usr_id');
$dbh->do("alter table click add column usr_id integer DEFAULT 1");
$dbh->do("ALTER TABLE ONLY click ADD CONSTRAINT usr_id_fkey FOREIGN KEY (usr_id) REFERENCES usr(usr_id) ON UPDATE CASCADE ON DELETE CASCADE");

warn('router_id');
$dbh->do("alter table click add column router_id integer DEFAULT 1");
$dbh->do("ALTER TABLE ONLY click ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE");

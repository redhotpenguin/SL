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
# ad group mods
$dbh->do("alter table ad_group add column reg_id integer not null default 14");
my $SQL = <<SQL;
ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group__reg_id_fkey 
        FOREIGN KEY (reg_id) REFERENCES reg(reg_id) 
     ON UPDATE CASCADE;
SQL
$dbh->do($SQL);

# ad mods
$dbh->do("alter table ad add column ad_group_id integer not null default 1");
$SQL = <<SQL;
ALTER TABLE ONLY ad
    ADD CONSTRAINT ad__ad_group_id_fkey FOREIGN KEY (ad_group_id)
        REFERENCES ad_group(ad_group_id) ON UPDATE CASCADE ON DELETE CASCADE;
SQL
$dbh->do($SQL);

# create friends
my $fh;
open( $fh, '<', "$sql_root/reg__reg.sql" ) or die $!;
my $sql = do { local $/; <$fh> };
$dbh->do($sql) or die $DBI::errstr;

use SL::Model::App;

my @ad__ad_groups = SL::Model::App->resultset('AdAdGroup')->search()->all;
print STDERR "Found " . scalar(@ad__ad_groups) . "\n";
foreach my $ad__ad_group (@ad__ad_groups) {
    print STDERR "processing ad id " . $ad__ad_group->ad_id->ad_id . "\n";
    my ($ad) = SL::Model::App->resultset('Ad')->search({ ad_id => $ad__ad_group->ad_id->ad_id });
    $ad->ad_group_id($ad__ad_group->ad_group_id->ad_group_id);
    $ad->update;
}



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

$dbh->do("drop table click");
$dbh->do("drop sequence click_click_id_seq");

$dbh->do("drop table reg__reg");

$dbh->do("drop table reg__ad_group");
$dbh->do("drop table router__ad_group");
$dbh->do("drop table router__reg");
$dbh->do("drop table ad_sl");
$dbh->do("drop sequence ad_sl_ad_sl_id_seq");
$dbh->do("drop table ad__ad_group");

$dbh->do("alter table ad_group drop constraint ad_group__reg_id_fkey");
$dbh->do("drop table ad_group");

# drop the view constraint so the views don't disappear when ad table is dropped
$dbh->do("alter table view drop constraint ad_id_fkey");



$dbh->do("drop table bug");
$dbh->do("alter table ad_group drop column bug_id");

$dbh->do("alter table router drop column replace_port");

warn("drop the feeds");
$dbh->do("alter table router drop column feed_google");
$dbh->do("alter table router drop column feed_linkshare");

$dbh->do("alter table reg drop column $_")
    for qw( zipcode firstname lastname description street_addr apt_suite
            referer phone cts sponsor street_addr2 root custom_ads paypal_id
            payment_threshold );

# load the acccount table
`psql -d $db -f $sql_root/account.sql`;
$dbh->do("insert into account (name) values ('Silver Lining')");

# load the ad zone
`psql -d $db -f $sql_root/ad_zone.sql`;
$dbh->do("insert into ad_zone (code, name, account_id, type) values ('legacy', 'legacy', 1, 'text_ad')");

`psql -d $db -f $sql_root/bug.sql`;
`psql -d $db -f $sql_root/router__account.sql`;
`psql -d $db -f $sql_root/account_ad_zone.sql`;

# update the view table
$dbh->do("alter table view rename COLUMN ad_id TO ad_zone_id");
$dbh->do("update view set ad_zone_id = '1'");
$dbh->do("alter table only view add constraint view__ad_zone_id_fkey foreign key (ad_zone_id) references ad_zone(ad_zone_id) on update cascade on delete cascade");

$dbh->do("drop table ad");
$dbh->do("drop SEQUENCE ad_ad_id_seq");
$dbh->do("drop table ad_group");

$dbh->do("alter table payment drop column reg_id");
$dbh->do("alter table payment add column account_id integer not null");
$dbh->do("alter table payment ADD CONSTRAINT account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE");

$dbh->do("drop table rate_limit");
$dbh->do("drop table root");
$dbh->do("drop sequence root_root_id_seq");
$dbh->do("drop table subrequest");
$dbh->do("drop table location__ad_group");


$dbh->do("drop table ad_linkshare");
$dbh->do("DROP SEQUENCE ad_linkshare_ad_linkshare_id_seq");

$dbh->do("CREATE TYPE ad_size as enum ('leaderboard', 'full_banner', 'text_ad')");




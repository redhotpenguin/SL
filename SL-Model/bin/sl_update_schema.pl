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

$dbh->do("drop table location__ad_group");

$dbh->do("drop table ad_linkshare");
$dbh->do("DROP SEQUENCE ad_linkshare_ad_linkshare_id_seq");

# drop the view constraint so the views don't disappear when ad table is dropped
$dbh->do("alter table view drop constraint ad_id_fkey");

$dbh->do("drop table ad");
$dbh->do("drop SEQUENCE ad_ad_id_seq");

$dbh->do("drop table ad_group");

$dbh->do("drop table bug");

warn("dropping router columns");
$dbh->do("alter table router drop column replace_port");
$dbh->do("alter table router drop column bug_image_href");
$dbh->do("alter table router drop column bug_link_href");
$dbh->do("alter table router drop column feed_google");
$dbh->do("alter table router drop column feed_linkshare");

$dbh->do("alter table reg drop column $_")
    for qw( zipcode firstname lastname description street_addr apt_suite
            referer phone cts sponsor street_addr2 root custom_ads paypal_id
            payment_threshold );

# load the acccount table
warn("updating accounts");
`psql -d $db -f $sql_root/account.sql`;
$dbh->do("insert into account (name) values ('Silver Lining')");
$dbh->do("insert into account (name) values ('Kharma Consulting')");
$dbh->do("insert into account (name) values ('Desitec')");
$dbh->do("insert into account (name) values ('Walkwire')");
$dbh->do("insert into account (name) values ('WiFi Guys')");
$dbh->do("insert into account (name) values ('CFS Software')");
$dbh->do("insert into account (name) values ('Drop It There')");
$dbh->do("insert into account (name) values ('Color Broadband')");
$dbh->do("insert into account (name) values ('Jamba Juice')");
$dbh->do("insert into account (name) values ('Ad Val Media')");
$dbh->do("insert into account (name) values ('Web Bond')");
$dbh->do("insert into account (name) values ('Hurmuz')");
$dbh->do("insert into account (name) values ('Bishop Roasters')");
$dbh->do("insert into account (name) values ('DavidWu')");
$dbh->do("insert into account (name) values ('Lane-8')");
$dbh->do("insert into account (name) values ('Marina Roof')");
$dbh->do("insert into account (name) values ('Medhat')");
$dbh->do("insert into account (name) values ('TMN')");
$dbh->do("insert into account (name) values ('Kohout')");
$dbh->do("insert into account (name) values ('Ferdzter')");
$dbh->do("insert into account (name) values ('airCloud')");
$dbh->do("insert into account (name) values ('Thomas Norcio')");
$dbh->do("insert into account (name) values ('Aabejaro')");


$dbh->do("update account set premium='t' where account_id = 2");

warn("updating reg");
$dbh->do("alter table reg add column account_id integer not null default 1 references account(account_id) on update cascade on delete cascade");
$dbh->do("update reg set account_id = 2 where reg_id in ( 62, 60 )"); # kharma
$dbh->do("update reg set account_id = 3 where reg_id in ( 64 )"); # desitec
$dbh->do("update reg set account_id = 4 where reg_id in ( 44 )"); # walkwire
$dbh->do("update reg set account_id = 5 where reg_id in ( 48 )"); # wifi guys
$dbh->do("update reg set account_id = 6 where reg_id in ( 49 )"); # CFS
$dbh->do("update reg set account_id = 7 where reg_id in ( 58 )"); # Drop it there
$dbh->do("update reg set account_id = 8 where reg_id in ( 52 )"); # color broadband
$dbh->do("update reg set account_id = 9 where reg_id in ( 53 )"); # jamba juice
$dbh->do("update reg set account_id = 10 where reg_id in ( 61, 59 )"); # Ad Val Media
$dbh->do("update reg set account_id = 11 where reg_id in ( 54 )"); # webbond
$dbh->do("update reg set account_id = 12 where reg_id in ( 51 )"); # Hurmuz
$dbh->do("update reg set account_id = 13 where reg_id in ( 18 )"); # Bishop Roasters
$dbh->do("update reg set account_id = 14 where reg_id in ( 65 )"); # David Wu
$dbh->do("update reg set account_id = 15 where reg_id in ( 66 )"); # Lane-8
$dbh->do("update reg set account_id = 16 where reg_id in ( 57 )"); # Marina Roof
$dbh->do("update reg set account_id = 17 where reg_id in ( 63 )"); # Medhat
$dbh->do("update reg set account_id = 18 where reg_id in ( 69 )"); # Thomas Norcio
$dbh->do("update reg set account_id = 19 where reg_id in ( 67 )"); # Mike Kohout
$dbh->do("update reg set account_id = 20 where reg_id in ( 68 )"); # ferdzter
$dbh->do("update reg set account_id = 21 where reg_id in ( 71 )"); # airCloud
$dbh->do("update reg set account_id = 22 where reg_id in ( 69 )"); # norcio
$dbh->do("update reg set account_id = 23 where reg_id in ( 70 )"); # aabejaro



warn("updating routers");

$dbh->do("alter table router add column account_id integer not null default 1 references account(account_id) on update cascade on delete cascade");

$dbh->do("update router set account_id = 2 where router_id in ( 80,61,60,62,58,64,69,63,91 )");
$dbh->do("update router set account_id = 3 where router_id in ( 79 )");
$dbh->do("update router set account_id = 6 where router_id in ( 45 )");
$dbh->do("update router set account_id = 7 where router_id in ( 66 )");
$dbh->do("update router set account_id = 8 where router_id in ( 37 )");
$dbh->do("update router set account_id = 9 where router_id in ( 33, 52 )");
$dbh->do("update router set account_id = 10 where router_id in ( 38, 68 )"); # ad val
$dbh->do("update router set account_id = 11 where router_id in ( 53 )");  # webbond
$dbh->do("update router set account_id = 12 where router_id in ( 40, 56 )"); # hurmuz
$dbh->do("update router set account_id = 14 where router_id in ( 81 )"); # davidwu
$dbh->do("update router set account_id = 15 where router_id in ( 72 )"); # essam lane-8
$dbh->do("update router set account_id = 16  where router_id in ( 48 )"); # blaine
$dbh->do("update router set account_id = 17  where router_id in ( 70 )"); # medhat
$dbh->do("update router set account_id = 18  where router_id in ( 89 )"); # norcio
$dbh->do("update router set account_id = 19  where router_id in ( 84 )"); # kohout
$dbh->do("update router set account_id = 20  where router_id in ( 88 )"); # ferdzter
$dbh->do("update router set account_id = 21  where router_id in ( 92,93 )"); # aircloud
$dbh->do("update router set account_id = 22  where router_id in ( 89 )"); # norcio
$dbh->do("update router set account_id = 23  where router_id in ( 90 )"); # aabejaro


$dbh->do("update reg set active = 'f'  where reg_id in ( 17,20, 50 )"); # old reg


# load the ad zone
`psql -d $db -f $sql_root/ad_size.sql`;
`psql -d $db -f $sql_root/bug.sql`;

$dbh->do("INSERT INTO bug (account_id, ad_size_id, image_href, link_href ) values (1, 1, 'http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif','http://www.silverliningnetworks.com/?referer=silverlining' )");
$dbh->do("INSERT INTO bug (account_id, ad_size_id, image_href, link_href ) values (1, 2, 'http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif','http://www.silverliningnetworks.com/?referer=silverlining') ");
$dbh->do("INSERT INTO bug (account_id, ad_size_id, image_href, link_href ) values (1, 3, 'http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif', 'http://www.silverliningnetworks.com/?referer=silverlining' ) " );


`psql -d $db -f $sql_root/ad_zone.sql`;
$dbh->do("insert into ad_zone (code, name, account_id, ad_size_id) values ('legacy code', 'legacy', 1, 3)");

`psql -d $db -f $sql_root/router__ad_zone.sql`;

# update the view table
$dbh->do("alter table view rename COLUMN ad_id TO ad_zone_id");
$dbh->do("update view set ad_zone_id = '1'");
$dbh->do("alter table only view add constraint view__ad_zone_id_fkey foreign key (ad_zone_id) references ad_zone(ad_zone_id) on update cascade on delete cascade");

$dbh->do("alter table payment drop column reg_id");
$dbh->do("delete from payment");
$dbh->do("alter table payment add column account_id integer not null");
$dbh->do("alter table payment ADD CONSTRAINT account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE");

$dbh->do("drop table rate_limit");
$dbh->do("drop table root");
$dbh->do("drop sequence root_root_id_seq");
$dbh->do("drop table subrequest");

warn("deleting unused routers");
$dbh->do("delete from router where router_id in (9,13,16,18,19,20,21,22,23,24,28,50)");
$dbh->do("update router set active='f' where router_id in (1,4,8,46,47,57,59,71,73,74,76,78)");





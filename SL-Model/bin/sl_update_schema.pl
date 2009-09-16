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

$dbh->do("alter table account add column map_center text not null default '94109'");
$dbh->do("alter table account add column map_zoom integer not null default 20");
$dbh->do("alter table account add column users_today integer not null default 0");
$dbh->do("alter table account add column megabytes_today integer not null default 0");
$dbh->do("alter table account add column users_monthly integer not null default 0");
$dbh->do("alter table account add column megabytes_monthly integer not null default 0");
$dbh->do("alter table account add column beta boolean not null default 'f'");




=cut

$dbh->do("create table network (network_id serial not null primary key)");
$dbh->do("alter table network add column account_id integer NOT NULL");
$dbh->do("ALTER TABLE ONLY network ADD CONSTRAINT network__account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE");
$dbh->do("alter table network add column location varchar(30) not null default ''");
$dbh->do("alter table network add column net_name varchar(30) not null default ''");
$dbh->do("alter table network add column ap1_essid varchar(30) NOT NULL default 'Silver Lining'");
$dbh->do("alter table network add column ap1_key varchar(30) NOT NULL default ''");
$dbh->do("alter table network add column ap2_enable boolean not null default 't'");
$dbh->do("alter table network add column ap2_essid varchar(30) NOT NULL default 'Silver Lining Secure'");
$dbh->do("alter table network add column ap2_key varchar(30) NOT NULL default 's1lv3r'");
$dbh->do("alter table network add column node_pwd varchar(30) not null default 's1lv3r'");
$dbh->do("alter table network add column splash_enable boolean default 't'");
$dbh->do("alter table network add column splash_redirect_url varchar(75) not null default 'http://www.silverliningnetworks.com'");
$dbh->do("alter table network add column splash_idle_timeout integer not null default 1440");
$dbh->do("alter table network add column splash_force_timeout integer not null default 1440");
$dbh->do("alter table network add column download_limit integer not null default 1024");
$dbh->do("alter table network add column upload_limit integer not null default 512");
$dbh->do("alter table network add column clients_last_day integer not null default 512");
$dbh->do("alter table network add column clients_last_week integer not null default 512");
$dbh->do("alter table network add column clients_last_month integer not null default 512");
$dbh->do("alter table network add column access_control_list text not null default ''");
$dbh->do("alter table network add column lan_block boolean default 't'");
$dbh->do("alter table network add column ap1_isolate boolean default 't'");
$dbh->do("alter table network add column ap2_isolate boolean default 't'");


=cut



$dbh->do("alter table router add column users_daily integer not null default 0");
$dbh->do("alter table router add column traffic_daily integer not null default 0");
$dbh->do("alter table router add column memfree integer not null default 0");
$dbh->do("alter table router add column clients integer not null default 0");
$dbh->do("alter table router add column hops integer not null default 0");
$dbh->do("alter table router add column kbup integer not null default 0");
$dbh->do("alter table router add column kbdown integer not null default 0");
$dbh->do("alter table router add column neighbors text not null default ''");
$dbh->do("alter table router drop column gateway");
$dbh->do("alter table router add column gateway inet");
$dbh->do("alter table router add column gateway_quality text not null default ''");
$dbh->do("alter table router add column routes text not null default ''");
$dbh->do("alter table router add column load text not null default ''");
$dbh->do("alter table router add column download_last integer not null default 0");
$dbh->do("alter table router add column download_average integer not null default 0");
$dbh->do("alter table router add column mesh_ip inet");

$dbh->do("alter table router add column checkin_status text not null default 'No checkin history'");
$dbh->do("alter table router add column speed_test text not null default 'No speed test data'");
$dbh->do("alter table router add column firmware_build text not null default ''");
$dbh->do("alter table router add column users_monthly integer not null default 0");
$dbh->do("alter table router add column megabytes_monthly integer not null default 0");





`psql -d $db -f ./sql/table/checkin.sql`;



$dbh->do("ALTER TABLE ONLY router__location ADD CONSTRAINT router__location__router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE");
$dbh->do("ALTER TABLE ONLY router__location ADD CONSTRAINT router__location__location_id_fkey FOREIGN KEY (location_id) REFERENCES location(location_id) ON UPDATE CASCADE ON DELETE CASCADE");

$dbh->do("ALTER TABLE ONLY router__ad_zone ADD CONSTRAINT router__ad_zone__router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE");

$dbh->do("ALTER TABLE ONLY router__ad_zone ADD CONSTRAINT router__ad_zone__ad_zone_id_fkey FOREIGN KEY (ad_zone_id) REFERENCES ad_zone(ad_zone_id) ON UPDATE CASCADE ON DELETE CASCADE");

warn("finished");

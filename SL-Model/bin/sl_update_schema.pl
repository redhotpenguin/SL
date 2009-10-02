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

warn("finished");

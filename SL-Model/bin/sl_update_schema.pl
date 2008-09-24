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

$dbh->do("alter table ad_zone add column code_double text not null default ''");
$dbh->do("alter table ad_size rename column height to bug_height;");
$dbh->do("alter table ad_size rename column width to bug_width;");

$dbh->do("update ad_size set bug_width='200' where ad_size_id = 1");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_leaderboard.css' where ad_size_id = 1");

$dbh->do("update ad_size set bug_width='200' where ad_size_id = 2");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_fullbanner.css' where ad_size_id = 2");

$dbh->do("update ad_size set bug_width='120' where ad_size_id = 3");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_textad.css' where ad_size_id = 3");

$dbh->do("update ad_size set bug_height='90' where ad_size_id = 4");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_textad.css' where ad_size_id = 4");

$dbh->do("update ad_size set bug_height='90' where ad_size_id = 5");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_wide_skyscraper.css' where ad_size_id = 5");

$dbh->do("update ad_size set bug_height='90' where ad_size_id = 6");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_halfpage.css' where ad_size_id = 6");


# set the double wide skyscraper to normal wide skyscraper
$dbh->do("update ad_zone set ad_size_id = 5 where ad_size_id = 7");

$dbh->do("update ad_size set name='Full Banner & Skyscraper' where ad_size_id = 7");
$dbh->do("update ad_size set bug_height='60' where ad_size_id = 7");
$dbh->do("update ad_size set bug_width='120' where ad_size_id = 7");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_double_fb_ss.css' where ad_size_id = 7");

$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width) values (8, 'Leaderboard & Skyscraper', 'http://www.silverliningnetworks.com/resources/css/sl_double_lb_ss.css', 90, 120) ");


$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width) values (9, 'Leaderboard & Wide Skyscraper', 'http://www.silverliningnetworks.com/resources/css/sl_double_lb_wss.css', 90, 160) ");


$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width) values (10, 'Floating Leaderboard', 'http://www.silverliningnetworks.com/resources/css/sl_floating_leaderboard.css', 90, 200) ");

$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width) values (11, 'Floating Full Banner', 'http://www.silverliningnetworks.com/resources/css/sl_floating_full_banner.css', 60, 200) ");



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
my ($css_url, $js_url);

##############################
$dbh->do("alter table ad_zone add column code_double text");
$dbh->do("alter table ad_zone add column public boolean default false NOT NULL");
$dbh->do("alter table ad_size rename column height to bug_height;");
$dbh->do("alter table ad_size rename column width to bug_width;");
$dbh->do("alter table ad_size add column template text not null default '';");
$dbh->do("alter table ad_size add column grouping  integer not null default 1");
$dbh->do("alter table ad_size add column js_url text not null default ''");
$dbh->do("alter table ad_size add column head_html text");
$dbh->do("update acccount set premium='t'");

##############################
$dbh->do("update ad_size set bug_width='200' where ad_size_id = 1");

$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/horizontal.js' where ad_size_id = 1;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_leaderboard.css' where ad_size_id = 1;");

$dbh->do("update ad_size set template='horizontal_leaderboard.tmpl' where ad_size_id = 1");

##############################
$dbh->do("update ad_size set bug_width='200' where ad_size_id = 2");

$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/horizontal.js' where ad_size_id = 2;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_fullbanner.css' where ad_size_id = 2;");

$dbh->do("update ad_size set template='horizontal_full_banner.tmpl' where ad_size_id = 2");

##############################
$dbh->do("update ad_size set bug_width='120' where ad_size_id = 3");
$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/horizontal.js' where ad_size_id = 3;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_textad.css' where ad_size_id = 3;");
$dbh->do("update ad_size set template='horizontal_textad.tmpl' where ad_size_id = 3");

##############################
$dbh->do("update ad_size set bug_height='90' where ad_size_id = 4");

$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/skyscraper.js' where ad_size_id = 4;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_skyscraper.css' where ad_size_id = 4;");

$dbh->do("update ad_size set grouping=2 where ad_size_id = 4");
$dbh->do("update ad_size set template='vertical_skyscraper.tmpl' where ad_size_id = 4");

##############################
$dbh->do("update ad_size set bug_height='90' where ad_size_id = 5");

$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/wide_skyscraper.js' where ad_size_id = 5;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_wide_skyscraper.css' where ad_size_id = 5;");

$dbh->do("update ad_size set grouping=2 where ad_size_id = 5");
$dbh->do("update ad_size set template='vertical_wide_skyscraper.tmpl' where ad_size_id = 5");


##############################
$dbh->do("update ad_size set bug_height='90' where ad_size_id = 6");

$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/half_page.js' where ad_size_id = 6;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_halfpage.css' where ad_size_id = 6;");

$dbh->do("update ad_size set grouping=2 where ad_size_id = 6");
$dbh->do("update ad_size set template='vertical_half_page.tmpl' where ad_size_id = 6");


# set the double wide skyscraper to normal wide skyscraper
$dbh->do("update ad_zone set ad_size_id = 5 where ad_size_id = 7");

##############################
$dbh->do("update ad_size set name='Double (Full Banner & Skyscraper)' where ad_size_id = 7");
$dbh->do("update ad_size set bug_height='60' where ad_size_id = 7");
$dbh->do("update ad_size set bug_width='120' where ad_size_id = 7");


$dbh->do("update ad_size set js_url='http://www.silverliningnetworks.com/resources/js/double_fb_ss.js' where ad_size_id = 7;");
$dbh->do("update ad_size set css_url='http://www.silverliningnetworks.com/resources/css/sl_double_fb_ss.css' where ad_size_id = 7;");

$dbh->do("update ad_size set grouping=3 where ad_size_id = 7");
$dbh->do("update ad_size set template='double_fullbanner_skyscraper.tmpl' where ad_size_id = 7");

##############################

$js_url='http://www.silverliningnetworks.com/resources/js/double_lb_ss.js';
$css_url='http://www.silverliningnetworks.com/resources/css/sl_double_lb_ss.css';

$dbh->do("insert into ad_size (ad_size_id, name, css_url, js_url, bug_height, bug_width, template) values (8, 'Double (Leaderboard & Skyscraper)', " . $dbh->quote($css_url) . ", " . $dbh->quote($js_url) . ", 90, 120, 'double_leaderboard_skyscraper.tmpl') ");
$dbh->do("update ad_size set grouping=3 where ad_size_id = 8");


##############################
$js_url='http://www.silverliningnetworks.com/resources/js/double_lb_wss.js';
$css_url='http://www.silverliningnetworks.com/resources/css/sl_double_lb_wss.css';

$dbh->do("insert into ad_size (ad_size_id, name, css_url, js_url, bug_height, bug_width, template) values (9, 'Double (Leaderboard & Wide Skyscraper)', " .  $dbh->quote($css_url) .  ", " . $dbh->quote($js_url) . ", 90, 160, 'double_leaderboard_wide_skyscraper.tmpl') ");

$dbh->do("update ad_size set grouping=3 where ad_size_id = 9");

##############################
my $head_html;
$js_url='http://www.silverliningnetworks.com/resources/js/floating_top.js';
$css_url='http://www.silverliningnetworks.com/resources/css/sl_floating_leaderboard.css';
$head_html = <<HTML;
<!--[if lte IE 6]><style type="text/css" media="screen"> html { padding-top:116px;overflow:hidden;}  body {padding-top:0 !important;} #silver_lining_webpage { width: 98%; }</style><![endif]-->
HTML

$dbh->do("insert into ad_size (ad_size_id, name, css_url, js_url, head_html, bug_height, bug_width, template) values (10, 'Floating Leaderboard', " .  $dbh->quote($css_url) . ", " . $dbh->quote($js_url) . ", " . $dbh->quote($head_html) . ", 90, 200, 'floating_leaderboard.tmpl') ");
$dbh->do("update ad_size set grouping=4 where ad_size_id = 10");

##############################
$js_url='http://www.silverliningnetworks.com/resources/js/floating_top.js';
$css_url='http://www.silverliningnetworks.com/resources/css/sl_floating_full_banner.css';
$head_html = <<HTML;
<!--[if lte IE 6]><style type="text/css" media="screen">html {padding-top:86px; overflow:hidden;}body {padding-top:0; !important;} #silver_lining_webpage { width: 98%;}</style><![endif]-->
HTML

$dbh->do("insert into ad_size (ad_size_id, name, css_url, js_url, head_html, bug_height, bug_width, template) values (11, 'Floating Full Banner', " . $dbh->quote($css_url) . ", " . $dbh->quote($js_url) . ", " . $dbh->quote($head_html) . ", 60, 200, 'floating_full_banner.tmpl') ");
$dbh->do("update ad_size set grouping=4 where ad_size_id = 11");

##############################
$js_url='http://www.silverliningnetworks.com/resources/js/floating_footer.js';
$css_url='http://www.silverliningnetworks.com/resources/css/sl_floating_footer_leaderboard.css';
$head_html = <<HTML;
<!--[if lte IE 6]><style type="text/css" media="screen">html {padding-bottom:116px !important;  overflow:hidden;} body {padding-bottom:0 !important;}</style><![endif]-->
HTML

$dbh->do("insert into ad_size (ad_size_id, name, css_url, js_url, head_html, bug_height, bug_width, template) values (12, 'Floating Footer Leaderboard', " .  $dbh->quote($css_url) . ", " .  $dbh->quote($js_url) . ", " . $dbh->quote($head_html) . ", 90, 200, 'floating_footer_leaderboard.tmpl') ");
$dbh->do("update ad_size set grouping=4 where ad_size_id = 12");

##############################
$js_url='http://www.silverliningnetworks.com/resources/js/floating_footer.js';
$css_url='http://www.silverliningnetworks.com/resources/css/sl_floating_footer_full_banner.css';
$head_html = <<HTML;
<!--[if lte IE 6]><style type="text/css" media="screen">html {padding-bottom:86px !important;  overflow:hidden;} body {padding-bottom:0 !important;}</style><![endif]-->
HTML


$dbh->do("insert into ad_size (ad_size_id, name, css_url, js_url, head_html, bug_height, bug_width, template) values (13, 'Floating Footer Full Banner', " . $dbh->quote($css_url) . ", " . $dbh->quote($js_url) . ", " . $dbh->quote($head_html) . ", 60, 200, 'floating_footer_full_banner.tmpl') ");
$dbh->do("update ad_size set grouping=4 where ad_size_id = 13");







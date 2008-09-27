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
my $css_url;

##############################
$dbh->do("alter table ad_zone add column code_double text not null default ''");
$dbh->do("alter table ad_size rename column height to bug_height;");
$dbh->do("alter table ad_size rename column width to bug_width;");
$dbh->do("alter table ad_size add column template text not null default '';");

##############################
$dbh->do("update ad_size set bug_width='200' where ad_size_id = 1");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_leaderboard.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() { $('div#silver_lining_ad_horizontal').hide("slow"); }); }); </script>
CSS

$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 1");
$dbh->do("update ad_size set template='horizontal_leaderboard.tmpl' where ad_size_id = 1");

##############################
$dbh->do("update ad_size set bug_width='200' where ad_size_id = 2");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_fullbanner.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() { $('div#silver_lining_ad_horizontal').hide("slow"); }); }); </script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 2");
$dbh->do("update ad_size set template='horizontal_full_banner.tmpl' where ad_size_id = 2");

##############################
$dbh->do("update ad_size set bug_width='120' where ad_size_id = 3");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_textad.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() { $('div#silver_lining_ad_horizontal').hide("slow"); }); }); </script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 3");
$dbh->do("update ad_size set template='horizontal_textad.tmpl' where ad_size_id = 3");

##############################
$dbh->do("update ad_size set bug_height='90' where ad_size_id = 4");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_skyscraper.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() { $('div#silver_lining_ad_vertical').hide("slow");$('div#silver_lining_skyscraper_webpage').css("margin-left", "0px"); }); }); </script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 4");
$dbh->do("update ad_size set template='vertical_skyscraper.tmpl' where ad_size_id = 4");

##############################
$dbh->do("update ad_size set bug_height='90' where ad_size_id = 5");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_wide_skyscraper.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() { $('div#silver_lining_ad_vertical').hide("slow");$('div#silver_lining_wideskyscraper_webpage').css("margin-left", "0px"); }); }); </script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 5");
$dbh->do("update ad_size set template='vertical_wide_skyscraper.tmpl' where ad_size_id = 5");

##############################
$dbh->do("update ad_size set bug_height='90' where ad_size_id = 6");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_halfpage.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() { $('div#silver_lining_ad_vertical').hide("slow");$('div#silver_lining_halfpage_webpage').css("margin-left", "0px"); }); }); </script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 6");
$dbh->do("update ad_size set template='vertical_half_page.tmpl' where ad_size_id = 6");


# set the double wide skyscraper to normal wide skyscraper
$dbh->do("update ad_zone set ad_size_id = 5 where ad_size_id = 7");

##############################
$dbh->do("update ad_size set name='Full Banner & Skyscraper' where ad_size_id = 7");
$dbh->do("update ad_size set bug_height='60' where ad_size_id = 7");
$dbh->do("update ad_size set bug_width='120' where ad_size_id = 7");
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_double_fb_ss.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function() { $('a#silver_lining_close').click(function() {$('div#silver_lining_ad_horizontal').hide("slow"); $('div#silver_lining_double_ad_fb').css("top", "0")});$('a#silver_lining_close'_vert').click(function(){$('div#silver_lining_double_ad_fb').hide("slow");$('div#silver_lining_skyscraper_webpage').css("margin-left", "0px");});});</script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("update ad_size set css_url=$css_url where ad_size_id = 7");
$dbh->do("update ad_size set template='double_fullbanner_skyscraper.tmpl' where ad_size_id = 7");

##############################
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_double_lb_ss.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function(){$('a#silver_lining_close').click(function(){$('div#silver_lining_ad_horizontal').hide("slow");$('div#silver_lining_double_ad_lb').css("top", "0")});$('a#silver_lining_close'_vert').click(function(){$('div#silver_lining_double_ad_lb').hide("slow");$('div#silver_lining_skyscraper_webpage').css("margin-left", "0px");});});</script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width, template) values (8, 'Leaderboard & Skyscraper', $css_url, 90, 120, 'double_leaderboard_skyscraper.tmpl') ");


##############################
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_double_lb_wss.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function(){$('a#silver_lining_close').click(function(){$('div#silver_lining_ad_horizontal').hide("slow");$('div#silver_lining_double_ad_lb').css("top", "0")});$('a#silver_lining_close'_vert').click(function(){$('div#silver_lining_double_ad_lb').hide("slow");$('div#silver_lining_wideskyscraper_webpage').css("margin-left", "0px");});});</script>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width, template) values (9, 'Leaderboard & Wide Skyscraper', $css_url, 90, 160, 'double_leaderboard_wide_skyscraper.tmpl') ");


##############################
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_floating_leaderboard.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function(){$('a#silver_lining_close').click(function(){$('div#silver_lining_floating_horizontal').hide("slow");$(body).css("padding-top", "0px");$('html').css("padding-top", "0px");});});</script><!--[if lte IE 6]><style type="text/css" media="screen">html {padding-top:116px;overflow:hidden;}body {padding-top:0;}</style><![endif]--></head>
CSS
$css_url = $dbh->quote($css_url);
$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width, template) values (10, 'Floating Leaderboard', $css_url, 90, 200, 'floating_leaderboard.tmpl') ");

##############################
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_floating_full_banner.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function(){$(body).css("padding-top", "86px");$('a#silver_lining_close').click(function(){$('div#silver_lining_floating_horizontal').hide("slow");$(body).css("padding-top", "0px");});});</script>
CSS

$css_url = $dbh->quote($css_url);
$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width, template) values (11, 'Floating Full Banner', $css_url, 60, 200, 'floating_full_banner.tmpl') ");

##############################
$css_url = <<'CSS';
<link rel="stylesheet" href="http://www.silverliningnetworks.com/resources/css/sl_floating_footer_leaderboard.css" type="text/css" /><script type="text/javascript" src="http://www.silverliningnetworks.com/resources/js/jquery.js"></script><script type="text/javascript">$(document).ready(function(){$('a#silver_lining_close').click(function(){$('div#silver_lining_floating_horizontal').hide("slow");$('body').css("padding-bottom", "0px");$('html').css("padding-bottom", "0px");});  });</script><!--[if lte IE 6]><style type="text/css" media="screen">html {padding-bottom:116px;overflow:hidden;} body {padding-bottom:0; }</style><![endif]-->
CSS

$css_url = $dbh->quote($css_url);
$dbh->do("insert into ad_size (ad_size_id, name, css_url, bug_height, bug_width, template) values (12, 'Floating Footer Leaderboard', $css_url, 90, 200, 'floating_leaderboard.tmpl') ");




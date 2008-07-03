#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 56;

BEGIN { use_ok('SL::Subrequest') or die }

# slurp the test webpage
my $content = do { local $/; <DATA> };

use Time::HiRes qw(tv_interval gettimeofday);

my $base_url   = 'http://wwww.sfgate.com';
my $subreq     = SL::Subrequest->new();
my $start      = [gettimeofday];
my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);
my $interval = tv_interval( $start, [gettimeofday] );

is( scalar( @{$subreq_ref} ), 59, 'subrequests extracted' );
diag("extraction took $interval seconds");
my $limit = 0.15;
cmp_ok( $interval, '<', $limit,
    "subrequests extracted in $interval seconds" );

diag("check correct subrequests were extracted");
my $i = 0;
# unique subrequests
my %subreq_hash = map { $_->[0] => 1 } @{$subreq_ref};
foreach my $test_url ( @{ test_urls() } ) {
    ok(exists $subreq_hash{$test_url}, "checking $test_url");
}

diag('test replacing the links');
my $port = '6969';
$start = [gettimeofday];
my $ok = $subreq->replace_subrequests(
        { port => $port, content_ref => \$content, subreq_ref => $subreq_ref });

no strict 'refs';
open(FH, '>', '/tmp/replace') or die;
print FH $content;
close(FH);

ok($ok, 'replace_subrequests ok');
$interval = tv_interval( $start, [gettimeofday] );
diag("replacement took $interval seconds");
cmp_ok( $interval, '<', $limit, "replace_subrequests took $interval seconds" );

my $subrequests_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);

##
diag("Check for mixed relative/absolute url contamination");
unlike($content, qr{sfgate\.comhttp}, 'no mixed absolute and relative urls');

sub test_urls {

    return [
'/c/pictures/2007/07/04_t/dd_dshaguilera102_t.gif',
'/templates/types/store/pages/buyphotos/images/homepage_gg100x100.jpg',
'/templates/types/homepage/graphics/sub_morenews.gif',
'http://js.adsonar.com/js/adsonar.js',
'/templates/types/homepage/graphics/sub_podcasts.gif',
'/templates/types/homepage/graphics/block_red.gif',
'/templates/types/homepage/graphics/dashes215x5.gif',
'http://pagead2.googlesyndication.com/pagead/imp.gif?client=ca-sfgate-home_js&amp;event=noscript',
'/templates/types/object/graphics/dip_t.gif',
'/templates/types/homepage/graphics/dashes210x5.gif',
'/c/pictures/2007/07/03_t/ga_AsianBirdFluEricsueyoshi_t.gif',
'/templates/types/gatemainpages/graphics/railwhitediv.gif',
'/templates/types/homepage/graphics/shop1.gif',
'http:///b/ss/hearstsfgatedev/1/H.9--NS/0',
'/templates/types/google/afc/javascript/afct.js',
'/templates/types/universal/graphics/clear.gif',
'/c/pictures/2007/07/01_t/tr_dsc_2298_t.gif',
'http://autos.sfgate.com/includes/array_makemodel.asp',
'/templates/types/common/graphics/clear.gif',
'/templates/types/polls/graphics/skins/homepage/header.gif',
'/templates/types/home/graphics/navlink_chronicle.gif',
'/gallery/pod/dip_popup.js',
'http://pagead2.googlesyndication.com/pagead/show_ads.js',
'/templates/types/gatemainpages/graphics/redarrow10x4.gif',
'/business/graphics/red_dot.gif',
'/templates/types/gatemainpages/images/redarrow5x4.gif',
'/templates/types/homepage/graphics/sub_featured.gif',
'/polls/2007/07/03/libby/result.gif',
'/c/pictures/2006/07/05_t/mn_firewowrks1_lm_t.gif',
'/js/omniture/s_code.js',
'/graphics/homepage/blackdot5x7.gif',
'/c/pictures/2007/06/25_t/ba_gaypride405_t.gif',
'/templates/types/homepage/graphics/insidesfgate.gif',
'/templates/types/common/graphics/logo/google-coloronwhite-56x18.gif',
'/templates/types/homepage/graphics/sub_blog.gif',
'/templates/types/homepage/graphics/bluedot6x7.gif',
'/templates/types/gatemainpages/images/clear.gif',
'/templates/types/homepage/graphics/sub_marketplace1.gif',
'/templates/types/homepage/graphics/dashes160x1.gif',
'/templates/types/homepage/graphics/autos1.gif',
'http://www.sfgate.com/templates/types/universal/graphics/clear.gif',
'/c/pictures/2007/07/03/mn-220x194-jones_garcia_099.jpg',
'/templates/types/common/graphics/icons/headphones-24x24.gif',
'/templates/types/homepage/graphics/sfis_64x64.gif',
'/templates/types/homepage/graphics/realestate.gif',
'http://www.sfgate.com/',
'http://personalshopper.sfgate.com/',
'http://js.adsonar.com/',
'http://sfgate.com/',
'http://www.sportsnetwork.com/',
    ];
}

__DATA__
<html> 
<head> 

<script>
var sfgate_interstitial_showad = '/cgi-bin/interstitial/main/showad?target_url=';
var sfgate_interstitial_cookie_name = 'SFGateInterstitial';
var sfgate_interstitial_cookie_expire = 1;
function sfgate_setaonclick() {
}
</script>

<meta name="KEYWORDS" content="The Gate, SF Gate, San Francisco Chronicle, News, Sports, Entertainment, San Francisco 49ers, Oakland Raiders, San Francisco Giants, Oakland Athletics, Herb Caen, Bay Area eGuide, classified advertising, Bay Area, Northern California, Technology"> 
<meta name="DESCRIPTION" content="SFGate: The Bay Area's Home Page -- online home of the San Francisco Chronicle, and much more."> 
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<title>SF Gate: News and Information for the San Francisco Bay Area</title>

<!-- Google AFC implementation -->





<!-- begin google/afc/javascript/afct.shtml -->
<!-- set ssi google afc defaults -->



























<script type="text/javascript">
google_ad_client = 'ca-sfgate-home_js';
google_ad_channel = 'homepage,fmt_narrowbox';
google_ad_output = 'js';
google_max_num_ads = '2';
google_safe = 'high';
google_adtest = 'off';
google_ad_type = 'text';
google_feedback = 'on';
sfg_afc_google_encl_div = 'googlebox';
sfg_afc_maxvu_length = '24';

</script>

<script  type="text/javascript"
  src="/templates/types/google/afc/javascript/afct.js"></script>
<!-- end google/afc/javascript/afct.shtml -->

<script language='javascript1.2' type="text/javascript">
<!--
var BrowserName = navigator.appName;
var plat = navigator.appVersion;
if (BrowserName
    && navigator.appName.indexOf("Netscape")>=0
    && navigator.appVersion.indexOf("4.")>=0) {
    document.write('<link rel="stylesheet" href="/templates/types/universal/style.ns4.css">');
} else {
    // default style sheet loaded if no browsers match
    document.write('<link rel="stylesheet" type="text/css" href="/templates/types/universal/style.css">');
document.write('<link rel="stylesheet" type="text/css" href="/templates/types/Default/style/basic.css" title="SFGate">');
    document.write('<link rel="stylesheet" type="text/css" href="/n/s/p/2004/infantmortality/style/special.css" title="special style">');
}
//-->
</script>

<link rel="stylesheet" type="text/css" href="/templates/types/common/style/searchbar.css" title="SFGate" />
<link rel="stylesheet" type="text/css" href="/templates/types/homepage/style/homepage.css" title="SFGate" />
<link rel="stylesheet" type="text/css" href="/templates/types/ads/pages/quigo/style/quigo.css" title="SFGate" />
<link rel="stylesheet" type="text/css" href="/templates/types/ads/style/homepage_text_ads.css" title="SFGate" />
<link rel="stylesheet" type="text/css" href="/templates/types/google/style/google.css" title="SFGate" />
<link rel="stylesheet" type="text/css" href="/place-ads/localads/localads.css" title="SFGate" />
	<script language="JavaScript">

	function changeImage(image_name,image_src) {
		document.images[image_name].src = image_src;
}
	</script>
<link href="http://www.sfgate.com/rss/feeds/news.xml" rel="alternate" type="application/rss+xml" title="SFGate: Top News Stories" />



<!------ OAS SETUP begin ------>
<SCRIPT LANGUAGE=JavaScript>
<!--
//configuration
OAS_url = 'http://oascentral.sfgate.com/RealMedia/ads/';
//OAS_sitepage = window.location.hostname + window.location.pathname;
OAS_sitepage = 'www.sfgate.com/main';
OAS_listpos = 'Frame2,x01,x02,x03,x31,x32,x33,x34,Position2,Right1,Frame1';
OAS_query = 'kw=';
OAS_target = '_top';
//end of configuration
OAS_version = 10;
OAS_rn = '001234567890'; OAS_rns = '1234567890';
OAS_rn = new String (Math.random()); OAS_rns = OAS_rn.substring (2, 11);
function OAS_NORMAL(pos) {
  document.write('<A HREF="' + OAS_url + 'click_nx.ads/' + OAS_sitepage + '/1' + OAS_rns + '@' + OAS_listpos + '!' + pos + '?' + OAS_query + '" TARGET=' + OAS_target + '>');
  document.write('<IMG SRC="' + OAS_url + 'adstream_nx.ads/' + OAS_sitepage + '/1' + OAS_rns + '@' + OAS_listpos + '!' + pos + '?' + OAS_query + '" BORDER=0></A>');
}
//-->
</SCRIPT>

<SCRIPT LANGUAGE=JavaScript1.1>
<!--
OAS_version = 11;
if (navigator.userAgent.indexOf('Mozilla/3') != -1 || navigator.userAgent.indexOf('Mozilla/4.0 WebTV') != -1)
  OAS_version = 10;
if (OAS_version >= 11)
  document.write('<SCR' + 'IPT LANGUAGE=JavaScript1.1 SRC="' + OAS_url + 'adstream_mjx.ads/' + OAS_sitepage + '/1' + OAS_rns + '@' + OAS_listpos + '?' + OAS_query + '"><\/SCRIPT>');//-->
</SCRIPT>

<SCRIPT LANGUAGE=JavaScript>
<!--
document.write('');
function OAS_AD(pos) {
  if (OAS_version >= 11)
    OAS_RICH(pos);
  else
    OAS_NORMAL(pos);
}
//-->
</SCRIPT>
<!------ OAS SETUP end ------>


<script language="javascript" src="/gallery/pod/dip_popup.js" type="text/javascript"></script>

</head> 
<body text="#000000" bgcolor="#ffffff" link="#5A0303" alink="#FF0000" vlink="#993333" marginwidth="0" marginheight="0" leftmargin="0" topmargin="0" background="/templates/types/homepage/graphics/bg_homeblu5.gif" onload="sfgate_setaonclick();"> 







<div style="display:none">
<script language="JavaScript" src="/js/omniture/s_code.js"></script>
</div>
<script language="JavaScript"><!--
/* You may give each page an identifying name, server, and channel on
the next lines. */

s.pageName="SFGate Home Page";
s.server="";
s.channel="Home Page";
s.prop3="";
s.prop4="";
s.prop5="";
s.prop6="Home Page";
s.prop17=s.getQueryParam('iref');

/************* DO NOT ALTER ANYTHING BELOW THIS LINE ! **************/
var s_code=s.t();if(s_code)document.write(s_code)//--></script>

<script language="JavaScript"><!--
if(navigator.appVersion.indexOf('MSIE')>=0)document.write(unescape('%3C')+'\!-'+'-')
//--></script><noscript><a href="http://www.omniture.com" title="Web Analytics"><img
src="http:///b/ss/hearstsfgatedev/1/H.9--NS/0"
height="1" width="1" border="0" alt="" /></a></noscript><!--/DO NOT REMOVE/-->
<!-- End SiteCatalyst code version: H.9. -->



<div id="container">
<div id="groupbody">


<!-- START HEADER TABLE -->
<table cellspacing="0" cellpadding="0" border="0" width="770"><tr bgcolor="#64898A"><td colspan="2" valign="middle" align="right" height="74" background="/templates/types/homepage/graphics/header795x94.jpg" style="background-repeat: no-repeat;" bgcolor="#64898A">

<script language="javascript" type="text/javascript">
<!--
OAS_AD('Frame2');
//-->
</script>
&nbsp;</td></tr>
<tr><td valign="top" width="127"><img src="/templates/types/homepage/graphics/block_red.gif" width="127" height="26" /></td><td style="background-color: #CCE5E5; border-right:1px solid #999; border-bottom:1px solid #999;">


<div id="headermenu">
<div id="statsmenu"><p class="inlinemenu">
<a href="traffic">Traffic</a> | <a href="/weather/">Weather</a>  |  <a href="liveviews/">Live Views</a> | <a href="/chronicle/">Today's Chronicle</a></p></div>

<div id="subscribechronicle"><p class="inlinemenu"><a href="/chronicle/"><img src="/templates/types/home/graphics/navlink_chronicle.gif" border="0" /></a> &raquo; <a href="https://www.subscriber-services.com/sfchron/zipcheck.asp?pid=3">Get Home Delivery</a></p></div>

<div class="clear">&nbsp;</div>
</div>

</td></tr></table>
<!-- END HEADER TABLE -->

<!-- START MAIN CONTENT TABLE -->

<table cellspacing="0" cellpadding="0" border="0" width="770"><tr>
<td width="120" valign="top" rowspan="5">


<div id="verticalmenu">
<h4>Marketplace</h4>
<ul>
<li><a href="/jobs/">Jobs &nbsp;<span style="color:#861D17;text-transform:lowercase;">new!</span></a></li>
<li><a href="/cars/">Cars</a></li>
<li><a href="/homes/">Real Estate</a></li>
<li><a href="http://marketplace.sfgate.com/">Classifieds</a></li>
<li><a href="http://personalshopper.sfgate.com/RopCategory.aspx">Chronicle Ads</a></li>
</ul>
<a href="http://www.sfgate.com/partners/classifieds/main_placeanad.html" class="placead">Place a classified ad</a>
</div>

<!-- BEGIN LEFT RAIL AREA --> 
<table width="115" cellspacing="0" cellpadding="0" border="0">
<tr><td valign="top">
<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>
<font face="verdana, arial, sans-serif" size="1" color="#333"><img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Main Sections</strong></font><br />
<strong><a href="/sports/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Sports</font></a></strong><br>
<strong><a href="/business/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Business</font></a></strong><br>
<strong><a href="/eguide/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Entertainment</font></a></strong><br><strong><a href="/food/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Food&amp;Dining</a></font></strong><br>
<strong><a href="/travel/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Travel</a></font></strong><br>
<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<font face="verdana, arial, sans-serif" size="1" color="#333333">
<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>News &amp; Features</strong><br>
</font>
<a href="/opinion/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Opinion</font></a><br>
<a href="/politics/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Politics</font></a><br>
<a href="/technology" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Technology</font></a><br>
<a href="/news/crime/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Crime</font></a><br>
<a href="/science/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Science</font></a><br>
<a href="/cars/news_research.shtml" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Cars</font></a><br>
<a href="http://allbusiness.sfgate.com" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Small Business</font></a><br>
<a href="/news/bondage/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Weird News</font></a><br>
<a href="/polls/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Polls</font></a><br>
<a href="/gallery/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Photo Gallery</font></a><br>
<a href="/video/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Video Reports</font></a><br>
<a href="/slideshows/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Audio Slideshows</font></a><br>
<a href="/columnists/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Columnists</font></a><br>
<a href="/travel/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Travel</font></a><br>
<a href="/news/lottery/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Lottery</font></a><br>
<a href="/chronicle/obituaries/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Obituaries</font></a><br>
<a href="/cgi-bin/blogs/main/page" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Blogs</font></a><br>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<div style="padding:0 0 0 10px;color:#666"><font face="verdana, arial, sans-serif" size="1"><strong>
<a href="/community/blogs/" style="color:#366">Community Blogs</a>
</strong><br />By our readers for our readers&nbsp; <span style="color:#990000; font-weight: bold;">BETA</span></font></div>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>


<font face="verdana, arial, sans-serif" size="1" color="#333333">

<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Regional</strong><br>
</font>

<a href="/traffic/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Traffic</font></a><br>
<a href="/weather/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Weather</font></a><br>
<a href="/liveviews/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Live Views</font></a><br>
<a href="/maps/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Maps</font></a><br>
<a href="/traveler/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Bay Area Traveler</font></a><br>
<a href="/wine/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Wine Country</font></a><br>
<a href="/traveler/guide/renotahoe/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Reno &amp; Tahoe</font></a><br>
<a href="/sports/skiing/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Ski &amp; Snow</font></a><br>
<a href="/sports/outdoors/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Outdoors</font></a><br>
<a href="/earthquakes/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Earthquakes</font></a><br>
<a href="http://www.sfgate.com/education/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Education</font></a><br>
<a href="/chronicle/chroniclewatch/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Chronicle Watch</font></a><br>
<a href="http://www.legalnotice.org/pl/SFGate/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Public Notices</font></a><br>



<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<strong><a href="/eguide/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#333"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Entertainment</font></a></strong><br>
<a href="/eguide/food/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Food &amp; Dining</font></a><br>
<a href="/wine/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Wine</font></a><br>
<a href="/96hours/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">96 Hours</font></a><br>
<a href="/eguide/movies/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Movies</font></a><br>
<a href="/eguide/music/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Music &amp; Nightlife</font></a><br>
<a href="/eguide/events/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Events</font></a><br>
<a href="/eguide/performance/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Performance</font></a><br>
<a href="/eguide/art/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Art</font></a><br>
<a href="/eguide/books/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Books</font></a><br>
<a href="/comics/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Comics</font></a><br>
<a href="/tvradio/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">TV &amp; Radio</font></a><br>
<a href="/eguide/search/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Search Listings</font></a><br>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<font face="verdana, arial, sans-serif" size="1" color="#333333">
<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Living</strong><br>
</font>

<a href="/health/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Health</font></a><br>
<a href="/homeandgarden/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Home &amp; Garden</font></a><br>
<a href="/eguide/gay/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Gay &amp; Lesbian</font></a><br>
<a href="/eguide/horoscope/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Horoscope</font></a><br>
<a href="http://personals.sfgate.com" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Personals</font></a><br>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<font face="verdana, arial, sans-serif" size="1" color="#333333">
<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Resources</strong><br>
</font>

<a href="/rss/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">RSS Feeds</font></a><br>
<a href="/myfeeds/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">My Feeds</font></a><br>
<a href="/cgi-bin/qws/as/main" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Search &amp; Archives</font></a><br>
<a href="/feedback/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Feedback/Contacts</font></a><br>
<a href="/pages/corrections/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Corrections</font></a><br>
<a href="/newsletters/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Newsletters</font></a><br>
<a href="/promotions/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Promotions</font></a><br>
<a href="/index/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Site Index</font></a><br>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>
<font face="verdana, arial, sans-serif" size="1" color="#333333">
<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Advertising</strong><br>
</font>
<a href="/sales/mediakit/contact/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Advertise Online</font></a><br>

<font face="verdana, arial, sans-serif" size="1" color="#336666">
<a href="http://www.sfgate.com/chronicle/advertise/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Advertise in Print</font></a><br>

<a href="http://sfgate.com/classifieds/chronicle/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Place a Classified</font></a><br>

<a href="/mediakit/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">SF Gate Media Kit</font></a><br>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<font face="verdana, arial, sans-serif" size="1" color="#333">
<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Newspaper</strong><br>
</font>

<a href="/chronicle/advertise/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Advertise</font></a><br>

<a href="https://www.subscriber-services.com/sfchron/nie/EduIndex.asp" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Chronicle<br />
<img src="/templates/types/universal/graphics/clear.gif" width="11" height="1" hspace="0" vspace="0" border="0" />In Education</font></a><br>

<a href="/chronicle/info/e-mail/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Contacts</font></a><br>

<a href="/chronicle/events/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Chronicle Events</font></a><br>

<a href="/chronicle/faq.shtml" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">FAQ</font></a><br>

<a href="/chronicle/newsroomjobs/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Jobs at<br />
<img src="/templates/types/universal/graphics/clear.gif" width="11" height="1" hspace="0" vspace="0" border="0" />the Chronicle</font></a><br>

<a href="/chronicle/submissions/" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Submissions</font></a><br>

<img src="/templates/types/gatemainpages/graphics/railwhitediv.gif" width="105" height="1" border="0" vspace="7" hspace="5"><br>

<font face="verdana, arial, sans-serif" size="1" color="#333333">
<img src="/templates/types/universal/graphics/clear.gif" width="10" height="1" border="0" vspace="0"><strong>Subscriber Service</strong><br>
</font>
<!--a href="https://www.subscriber-services.com/sfchron/landing.asp?code=HDDEFA" class="rail" --><a href="https://www.subscriber-services.com/sfchron/zipcheck.asp?pid=3" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Get Home Delivery</a><br />
<img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2"><a href="https://www.subscriber-services.com/sfchron/SplashScreen.asp" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666">Manage Account,<br />
<img src="http://www.sfgate.com/templates/types/universal/graphics/clear.gif" width="10" height="1" hspace="0" vspace="0" border="0">Missed Delivery,<br />
<img src="http://www.sfgate.com/templates/types/universal/graphics/clear.gif" width="10" height="1" hspace="0" vspace="0" border="0">Vacation Hold</a><br></font></a><br>
<!-- <a href="https://www.subscriber-services.com/sfchron/CSSearch.asp?PageName=MissedPaper%2Easp&Hdr=REDELIVER+PAPER&Login=True" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Missed Delivery</font></a><br>
<a href="https://www.subscriber-services.com/sfchron/landing.asp?code=VAC" class="rail"><font face="verdana, arial, sans-serif" size="1" color="#336666"><img src="/templates/types/gatemainpages/graphics/redarrow10x4.gif" width="10" height="4" border="0" vspace="2">Vacation Hold</font></a><br> -->




</font>
</td></tr>
</table>
 
<!-- END LEFT RAIL --> 

<!--<div style="padding:0 5px 0 10px;"><font face="verdana, arial, sans-serif" size="1" color="#000000">NOTE:  Subscriber Services will be down for maintenance on May 5, 2007. Please report missed deliveries and vacation holds by calling 1-800-281-2476 between the hours of 6:30 AM and 11:00 AM on Saturday. We apologize for any inconvenience this may cause, and thank you for your patience.</font></div>-->

 


<div id="leftnavads">

<script language="javascript" type="text/javascript">
<!--
OAS_AD('x01');
//-->
</script>

<script language="javascript" type="text/javascript">
<!--
OAS_AD('x02');
//-->
</script>

<script language="javascript" type="text/javascript">
<!--
OAS_AD('x03');
//-->
</script>
<!--set var="position" value="x04"  -->
<!--include virtual="/templates/types/realmedia/templates/mjx_placement.shtml" -->
<!--set var="position" value="x05"  -->
<!--include virtual="/templates/types/realmedia/templates/mjx_placement.shtml" -->
</div>

</TD> 
<!-- END LEFT RAIL AREA -->


<!-- SEARCH BAR -->
<td colspan="8">
<div id="searchbar">
<form METHOD="get" action="/cgi-bin/csearch/cs">
<div class="row">
<input type="TEXT" name="term" size="24" class="entry" /> 
<input type="hidden" name="Submit" value="S">
<input name="Go" value="Search" width="56" height="22" class="button" alt="Submit" type="image" src="/templates/types/common/graphics/buttons/search-greywhite-56x22.gif" />

<span class="option"><input name="st" type="radio" value="s" class="radio" checked="checked" />SFGate News</span> <span class="option"><input name="st" type="radio" value="w" class="radio" /> Web by <img src="/templates/types/common/graphics/logo/google-coloronwhite-56x18.gif" alt="Google" id="googlelogosm" /></span>
</div>
</form>
</div><!-- /#searchbar -->
 
</td></tr>
<!-- END SEARCH BAR -->

<tr>

<!-- THE GUTTER ---> 
<td valign="top" width="15" rowspan="5">
<img src="/templates/types/universal/graphics/clear.gif" width="15" height="1" border="0" vspace="0" hspace="0" /></td> 
<!-- END GUTTER -->

<!-- BEGIN MAIN SPREAD -->

<td align="left" valign="bottom" width="220" style="padding: 3px 0px 2px 0px; font-family: geneva, arial,sans-serif; font-size: 10px; color: #CC0000; border-bottom: 1px solid #CCCCCC;">
Tuesday, July  3, 2007</td>


<td width="10" nowrap style="border-bottom: 1px solid #CCCCCC;"><img src="/templates/types/gatemainpages/images/clear.gif" width="10" height="8" border="0" hspace="0" vspace="0" /></td>

<td align="right" valign="bottom" width="220" class="text1sm" style="font-family: geneva, arial, sans-serif; font-size: 10px; padding: 3px 5px 2px 0px; color: #CC0000; border-bottom: 1px solid #CCCCCC;">
Updated: 03:15 PM PDT</td>

<td width="7" rowspan="4" valign="top" ><img src="/templates/types/gatemainpages/images/clear.gif" width="7" height="8" border="0" hspace="0" vspace="0" /></td>

<td width="1" rowspan="4" valign="top" style="border-left: 1px dashed #666666;"><img src="/templates/types/gatemainpages/images/clear.gif" width="1" height="8" border="0" hspace="0" vspace="0" /></td>

<td width="7" rowspan="4" valign="top"><img src="/templates/types/gatemainpages/images/clear.gif" width="7" height="8" border="0" hspace="0" vspace="0" /></td>

<td valign="top" rowspan="5" style="padding: 0px 0px 5px 0px;" width="160">

<div style="margin-top:10px;width:160px;height:80px;border-top:1px solid #666;border-bottom:1px solid #666;background-image: url(/graphics/allstarpromo_200x200.gif);"><a href="http://www.sfgate.com/allstar/"><img src="/templates/types/gatemainpages/images/clear.gif" width="160" height="75" border="0" hspace="0" vspace="0" /></a></div>

<img src="/templates/types/homepage/graphics/sub_featured.gif" width="68" height="12" border="0" vspace="4" hspace="0"></a><br />
<table border="0" width="160" cellspacing="0" cellpadding="0">
<tr><td width="64" style="padding: 0 2px 0 0;"><a href="/cgi-bin/article/article?f=/g/a/2007/07/03/apop.DTL"><img src="/c/pictures/2007/07/03_t/ga_AsianBirdFluEricsueyoshi_t.gif" width="64" height="64" hspace="0" vspace="0" border="1" /></a></td><td class="text1sm" align="left" valign="middle" style="padding: 0px 0px 0px 2px;">18 Mighty Mountain Warriors lead a comic revival. <a href="/cgi-bin/article/article?f=/g/a/2007/07/03/apop.DTL">Asian Pop</a>.
<br /></td></tr>
</table>
<div style="padding: 8px 0px 2px 0px;"><img src="/templates/types/homepage/graphics/dashes160x1.gif" width="160" height="1" hspace="0" vspace="0" border="0" /></div>


<!-- DAY IN PICTURES -->



  

<style type="text/css" title="SFGate">
/* <![CDATA[ */
#dayinpictures      {font-family:Geneva, Arial, sans-serif;font-size:10px;}
#dayinpictures h4   {margin:3px 0 10px 0;padding:0;}
#dayinpictures h4 a {display:block;width:118px;height:15px;text-indent:-1024px;
   background:url('/templates/types/homepage/graphics/sub_dip2.gif') no-repeat;}
#dayinpictures img  {float:left;margin:-7px 4px 0 0;border:1px solid #000;}
/* ]]> */
</style>
<div id="dayinpictures">
<h4><a href="/cgi-bin/object/dayinpictures?f=/g/a/2007/07/02/dip.DTL" target="DayInPictures" onclick="dip_popup();">Day in Pictures</a></h4>
<a href="/cgi-bin/object/dayinpictures?f=/g/a/2007/07/02/dip.DTL" target="DayInPictures" onclick="dip_popup();"><img src="/templates/types/object/graphics/dip_t.gif" /></a>
Dancing bears and a 112th b-day. 
<a href="/cgi-bin/object/dayinpictures?f=/g/a/2007/07/02/dip.DTL" target="DayInPictures" onclick="dip_popup();">DIP!</a><!--DIP--> Now with more chocolate.
</div>


<!--include virtual="/includes/yip.txt"-->

<!--dip sponsorship-->
<!--
<img src="/templates/types/gatemainpages/images/clear.gif" width="160" height="3" border="0" /><br />
<table cellpadding="0" cellspacing="0">
<tr><td class="text2sm" valign="top" style="color:#999;align:left;padding-top:5px;">sponsored
by:</td>
<td valign="top" style="padding-top:5px;">
-->
<!--set var="position" value="Left"-->
<!--include virtual="/templates/types/realmedia/templates/mjx_placement.shtml"-->
<!--</td></tr></table>-->
<!--set var="position" value="Left"  -->
<!--include virtual="/templates/types/realmedia/templates/mjx_placement.shtml" -->
<!--dip sponsorship end-->

<img src="/templates/types/universal/graphics/clear.gif" width="160" height="8" border="0" /><br />

<img src="/templates/types/homepage/graphics/dashes160x1.gif" alt="seperator" width="160" height="1" align="middle" vspace="3" /><br />
<!-- BLOG -->
<!-- blogs/bloghome_fivestrip.html generated by gen1 on Tue 03 Jul 2007 03:08:37 PM PDT -->

<div id="blogwidget">
<h2><a href="http://www.sfgate.com/cgi-bin/blogs/main/page" style="color:#900;"><img src="/templates/types/homepage/graphics/sub_blog.gif" alt="Blogs" border="0" /></a></h2>
<h4><a href="/cgi-bin/blogs/sfgate/indexn?blogid=14" title="Politics Blog">Politics Blog</a> </h4>
<p>Carla Marinucci -- It's tough out there</p>
<h4><a href="/cgi-bin/blogs/sgreen/index?" title="Sports Columnists">Sports Columnists</a> </h4>
<p>Tuesday: Day 8 at Wimbledon</p>

<h4><a href="/cgi-bin/blogs/sfgate/indexd?blogid=7" title="The Daily Dish">The Daily Dish</a> </h4>
<p>Aguilera's dad confirms pregnancy; Jessica Simpson back with Cook?</p>
<h4><a href="/cgi-bin/blogs/sfgate/indexn?blogid=3" title="Culture Blog">Culture Blog</a> </h4>
<p>Rocchi's Retro Rental: America, The Beautiful and Complicated; Bay Blogwalker Unleashed</p>
<h4><a href="/cgi-bin/blogs/opinionshop/index?" title="Opinion Shop">Opinion Shop</a> </h4>
<p>Windbags of the world</p>

<h4 style="font-weight:normal;"><a href="http://www.sfgate.com/cgi-bin/blogs/main/page" style="color:#900;">View all blogs</a> or
<script language="JavaScript">
<!--
function jumpMenu(targ,selObj,restore){
if (selObj.selectedIndex != 1)
eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
if (restore) selObj.selectedIndex=0;
}
//-->

</script>
<form name="allblogs" class="select_menu" style="margin:7px 0 5px 0;padding:0;">
<select name="" onChange="jumpMenu('parent',this,0)">
<option value="#" selected="selected">Select a Blog</option>
<option value="#">--------</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=24">The Bastard Machine</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=3">Culture Blog</option>
<option value="/cgi-bin/blogs/nwzchik/index?">NWZCHIK</option>
<option value="/cgi-bin/blogs/foreigndesk/index?">The Ross Report</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=26">Michael Bauer</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=14">Politics Blog</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=15">World Views</option>
<option value="/cgi-bin/blogs/localnews/index?">Local News Blog</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=18">C.W. Nevius</option>
<option value="/cgi-bin/blogs/parenting/index?">The Poop</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=19">The Tech Chronicles</option>
<option value="/cgi-bin/blogs/opinionshop/index?">Opinion Shop</option>
<option value="/cgi-bin/blogs/persianality/index?">Inside Iran</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=10">Niners Turf</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=11">Raiders Silver And Black</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=21">A's Drumbeat</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=22">Giants Splash</option>
<option value="/cgi-bin/blogs/warriors/index?">Golden State Warriors</option>
<option value="http://sfgate.com/cgi-bin/blogs/sfgate/category?blogid=27&cat=893">Prep Football</option>
<option value="http://sfgate.com/cgi-bin/blogs/sfgate/category?blogid=27&cat=895">The Fool and the Fantasy Man</option>
<option value="/cgi-bin/blogs/mlasalle/index?">Maximum Strength Mick</option>
<option value="/cgi-bin/blogs/photoblogfl/index?">Mystical Photography</option>
<option value="/cgi-bin/blogs/sfgate/indexd?blogid=7">The Daily Dish</option>
<option value="/cgi-bin/blogs/sgreen/index?">Sports Columnists</option>
<option value="/cgi-bin/blogs/sfgate/indexn?blogid=13">Two Cents</option>

</select>
</form>
</h4>

</div>

<!-- end blogs/bloghome_fivestrip.html -->



<!-- COLLEAGUES REMEMBERED -->
<style type="text/css" title="SFGate">
/* <![CDATA[ */
#colleagues     {font-family:Geneva, Arial, sans-serif;font-size:10px;
                 margin-bottom:5px;}
#colleagues h4  {margin:0;padding:0;font-size:12px;}
/* ]]> */
</style>
<div id="colleagues">
<h4><a href="/cgi-bin/blogs/sfgate/category?blogid=28&cat=1301">Colleagues Remembered</a></h4>
The San Francisco Chronicle honors departing staff members.
</div>


<img src="/templates/types/homepage/graphics/dashes160x1.gif" alt="seperator" width="160" height="1" align="middle" vspace="3" /><br />
<!-- PODCASTS -->
<table border="0" width="160" cellspacing="0" cellpadding="0" style="margin: 0px 0px 5px 0px;"><!--  border: 1px solid #BFC6CB; -->
<tr><td class="text1md" align="left" valign="top">
<img src="/templates/types/common/graphics/icons/headphones-24x24.gif" width="24" height="24" hspace="0" vspace="0" border="0" alt="Podcasts" style="margin: 3px 10px 0 0;" align="right" /><img src="/templates/types/homepage/graphics/sub_podcasts.gif" width="76" height="15" hspace="0" vspace="0" border="0" alt="Podcasts" style="margin: 3px 0 0 0;" />
<br />
<strong><a href="/cgi-bin/blogs/sfgate/indexn?blogid=5" style="color: #993300;">
Chronicle Podcasts</a></strong><br /><span class="text1sm">Interview with ex-prime minister of Pakistan; opening online music stores; Durst riffs.</span><br/>
<img src="/templates/types/common/graphics/clear.gif" alt="" width="1" height="4" /><br />
<strong><a href="/cgi-bin/blogs/sfgate/category?blogid=5&cat=1066" style="color: #993300;">
Correct Me If I'm Wrong</a></strong><br /><span class="text1sm">What to tell your propaganda soldier.</span><br/>

</td></tr>
</table>


<!-- CLASSIFIEDS VERTICALS -->


<!-- HOMES -->
<table width="130" border="0" cellpadding="0" cellspacing="0">
<tr><td><img src="/templates/types/homepage/graphics/dashes160x1.gif" alt="seperator" width="160" height="1" align="middle" vspace="3"></td></tr>
<tr><td valign="top" align="left" colspan="2" class="text1sm">
<a href="http://www.sfgate.com/realestate/" target="_self"><img src="/templates/types/homepage/graphics/realestate.gif" width="82" height="12" border="0" vspace="2" alt="real estate" hspace="0"></a><br>
Find a home on our new <a href="http://www.sfgate.com/realestate/" target="_self">Real Estate</a> site.
</td></tr>
<tr>
<td align="left" valign="top">
<select name="to" class="ads_jump" onChange="window.open(this.options[this.selectedIndex].value,'_top')">
<option value="">Select A County</option>
<option value="/realestate/" >Homes For Sale</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=10" >-Alameda</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=11" >-Contra Costa</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=12" >-Marin</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=13" >-Napa</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=14" >-SF</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=15" >-San Mateo</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=16" >-Santa Clara</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=17" >-Solano</option>
<option value="http://realestate.sfgate.com/RealEstate/Sales/Search.asp?CountyIds=18">-Sonoma</option>
</select>
</td>
<td valign="top" align="left"></form></td></tr>
</table>
<!-- END HOMES -->

<script language="javascript" type="text/javascript">
<!--
OAS_AD('Right1');
//-->
</script>

<!-- PRINT ADS -->
<table width="130" border="0" cellpadding="0" cellspacing="0">
<tr><td>
<img src="/templates/types/homepage/graphics/dashes160x1.gif" alt="seperator" width="160" height="1" align="middle" vspace="3">
</td></tr>
<tr><td width="130" valign="top" align="left"><a href="http://personalshopper.sfgate.com/" target="_self"><img src="/templates/types/homepage/graphics/shop1.gif" width="130" height="25" border="0" hspace="0" vspace="0"></a><!-- <br> -->
<!-- <font size="1" color="#CC0000" face="verdana, arial, sans-serif">Chronicle print ads:</font> --></td>
</tr>
<tr><td align="left" valign="top">
<form method="GET" action="/cgi-bin/sfgate/auto_dropdown.cgi" onsubmit="window.open(this.elements[0].options[this.elements[0].selectedIndex].value,'_top'); return(false)">
<select name="to" class="ads_jump" onChange="window.open(this.options[this.selectedIndex].value,'_top')">
<option value="http://personalshopper.sfgate.com/ROP/Categories.aspx">By category</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3327">
Agriculture</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3328">
Announcements</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3329">
Apparel & Jewelry</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3330">
Automotive</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3331">
Business</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3332">
Community</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3333">
Dining & Entertainment</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3334">
Home Improvement</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3335">
Medical</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3336">
Real Est./Rentals</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3337">
Recreation</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3338">
Services</option>
<option value="http://personalshopper.sfgate.com/ROP/Subcat.aspx?cat=3339">
Shopping</option>
<option value="http://personalshopper.sfgate.com/ROP/Categories.aspx">
Other Categories</option>
</select>
<img src="/templates/types/homepage/graphics/dashes160x1.gif" alt="seperator" width="160" height="1" align="middle" vspace="3">
</td>
<td></form></td>
</tr>
</table>

<!-- END PRINT ADS -->

<!-- AUTOS -->
<table width="130" border="0" cellpadding="0" cellspacing="0">
<SCRIPT LANGUAGE="javascript" TYPE="text/javascript" SRC="http://autos.sfgate.com/includes/array_makemodel.asp"></SCRIPT>
<form name="AutoPD" method="post" action="http://autos.sfgate.com/SearchResults.asp"  target="_top">
<input name="NewOrUsed" type="hidden" value=2 > 
<input type="hidden" name="SearchBy" value="UsedCar" > 
<input type="hidden" name="SortAs" value=" desc" > 
<input type="hidden" name="SearchCategory"  value=1 > 
<input type="hidden" name="SearchSubCategory"  value="" > 
<input type="hidden" name="Radius"  value="50" > 
<input type="hidden" name="StartYear"  value="1900" > 
<input type="hidden" name="EndYear"  value="2006" >
<tr><td width="130" valign="top" align="left">
<a href="http://www.sfgate.com/cars/" target="_self"><img src="/templates/types/homepage/graphics/autos1.gif" width="130" height="11" border="0" hspace="0" vspace="2"></a></td>
</tr>
<tr>
<td colspan="2" align="left" valign="top">
<select name="makes" class="ads_jump" onChange="document.AutoPD.submit();">
<option value="">Find a Car</option>
<script lanugage="JavaScript">
function undupeArray(arrayName) {
	 var unduped = new Object;
	 for (i=0;i<arrayName.length;i++) {   
	     unduped[arrayName[i][0]] = arrayName[i];
	     }
	     var uniques = new Array;
	     for (var k in unduped) {
		 uniques.push(unduped[k]);
		 }
		 return uniques;
}
myArray = undupeArray(MakesCaches);

for (y=0;y < myArray.length;y++) {

    document.write("<option value='" + myArray[y][0] + "'>" + myArray[y][1] + "</option>");

}
</script>
</select>
</td></tr>
</form>
</table>
<!-- END AUTOS -->

<br />



<!-- QUIGO -->

<!-- BEGIN QUIGO -->
 <div id="quigo">
 <h4>Sponsored Links</h4>
 <div class="listgroup">
<script type="text/javascript">adsonar_pid=195757;adsonar_ps=780669;adsonar_zw=160;adsonar_zh=224;adsonar_jv='ads.adsonar.com';</script><script language="JavaScript" src="http://js.adsonar.com/js/adsonar.js"></script>
 </div>
<div class="inlinemenu">
<p><img src="/business/graphics/red_dot.gif" border="0" alt="-"/>  <a href="http://sfgate.com/marketing/adlinks/">Advertise here and get <br />your first $50 Free! &raquo;</a> </p>
 </div>
 
</div>
<!-- END QUIGO -->

<!-- POLL -->
<a name="poll">
<!-- story link goes here -->
<!-- to activate/de-activate, add/remove the # from before the word 'set' -->
<!-- text inside value tag is the same as what would be in a HREF tag -->










<script language="JavaScript">
<!--
function makeremote(pollid) {
  remote = window.open("","remotewin",
    "width=200,height=300,resizable=yes,scrollbars=auto,screenx=15,screeny=15,toolbar=no");
  remote.location.href = pollid+'/q';
  if (remote.opener == null)
    remote.opener = window;
  remote.opener.name = "opener";
}
function makeDisclaimer() {
  remote = window.open("","disc","width=300,height=300");
  remote.location.href = "/templates/types/polls/disclaimer.html";
  if (remote.opener == null)
    remote.opener = window;
  remote.opener.name = "opener";
}
//-->
</script>
<form action="javascript:makeremote('/polls/2007/07/03/libby');" method="post">

   <table cellpadding="0" cellspacing="0" bgcolor="#EEEEEE" width="160" border="0" style="border: 1px solid #99CCCC;">
   <tr>
    <td colspan="2" style="padding: 6px 0px 5px 6px; border-bottom: 1px solid #99CCCC;">
     <img src="/templates/types/polls/graphics/skins/homepage/header.gif">
    </td>
   </tr>
   <tr>
    <td colspan="2" style="padding: 6px 0px 5px 6px;">
     <img src="/polls/2007/07/03/libby/result.gif"></td>
   </tr>
   <tr>
    <td valign="top" style="padding: 0px 0px 5px 8px;">
     <input type="image" name="action"
      src="/templates/types/polls/graphics/skins/homepage/vote_button.gif" border=0>
    </td>
    <td align="right" valign="bottom" style="padding: 0px 6px 5px 2px;">
     <font size="1" face="geneva, arial, sans-serif"><a href="javascript:makeDisclaimer()">Disclaimer</a></font>&nbsp;<br>
     <img src="/templates/types/gatemainpages/images/clear.gif" width="1" height="3">
    </td>
   </tr>


<tr><td align="center" colspan="2" border="0">
<span class="text1sm">
<A HREF="/cgi-bin/article.cgi?file=/c/a/2007/07/03/MNGPNQQ31V1.DTL&amp;tsp=1">Read Story</A>
</span>
</td></tr>



   </table>

</form>




<!--include virtual="/includes/polls/recent_polls.html" -->



</a>



</td></tr>


<tr>
<td align="center" valign="middle" colspan="3">
<!--


<table width="100%" cellspacing="0" cellpadding="0" border="0" style="border-bottom: 1px solid #CCCCCC; padding: 5px 0px 6px 0px;">
<tr><td align="center" valign="top">
<br>
<span class="bannerhed"><a href="/cgi-bin/article.cgi?f=/n/a/2007/07/02/national/w145109D75.DTL">Bush Commutes 'Excessive' Libby Sentence</a></span><br>

<span class="bannertext">
No prison for aide | <a href="/cgi-bin/article/comments/view?f=/n/a/2007/07/02/national/w145109D75.DTL">Comments</A> | <a href="/cgi-bin/blogs/sfgate/sso_detail?blogid=13&entry_id=18211">2 Cents: Right Call?</A> | <a href="/cgi-bin/blogs/foreigndesk/detail?blogid=16&entry_id=18209">Ross Report</A>

</span><br/>

</td></tr></table>


-->

</td></tr>


<tr>
<td valign="top" align="left" style="padding: 14px 0px 0px 0px;">
<table border="0" cellspacing="0" cellpadding="0" width="220">
<tr valign=top><td align="left">
<font size="3" face="helvetica,arial,sans-serif">

<b><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3D11.DTL">Best Friends In Life, Death</a></b></font></td></tr>
<tr><td valign=top align="left">
<A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3D11.DTL"><IMG SRC="/c/pictures/2007/07/03/mn-220x194-jones_garcia_099.jpg" WIDTH="220" HEIGHT="194" BORDER="0" VSPACE=3 ALT="best friends"></A><BR>
</td></tr><tr><td align="left" valign="top">
<font size="1" face="geneva,arial,sans-serif">

Teenage buddies <A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3D11.DTL">Gregory Jones (left) and Chris Garcia</A> did everything together. Early Saturday, a homeless man found their stabbed bodies in a remote part of Hunters Point. They died "virtually in each others' arms," police said.

</font></td></tr></table>


<!-- ad begin -->
<br />

<script language="javascript" type="text/javascript">
<!--
OAS_AD('Frame1');
//-->
</script>
<!-- ad end -->

<p><img src="/templates/types/homepage/graphics/sub_morenews.gif" width="220" height="9" border="0" vspace="3" hspace="0">

<TABLE WIDTH="225" CELLSPACING="0" CELLPADDING="2" BORDER="0">

<TR><td align="left" valign="top">
<!--IMAGE--/c/pictures/2007/07/04_t/dd_dshaguilera102_t.gif--IMAGE-->
<!--THUMBURL--/cgi-bin/blogs/sfgate/indexd?blogid=7--THUMBURL-->

<a href="/cgi-bin/blogs/sfgate/indexd?blogid=7"><img src="/c/pictures/2007/07/04_t/dd_dshaguilera102_t.gif" width="64" height="64" vspace="0" hspace="0" border="1"></a>
</td>
<td align="left" valign="top">
<FONT SIZE="1" FACE="geneva,arial,sans-serif">
<!--CAPTION--><b><A HREF="/cgi-bin/blogs/sfgate/indexd?blogid=7">Who's Your Granddaddy?</a></B><BR>Aguilera's dad confirms pregnancy; Jessica Simpson back with Cook?; is Prince William still dating Kate? <a href="/cgi-bin/blogs/sfgate/indexd?blogid=7">Dish</a>!<!--CAPTION-->
</font>
</td></tr>


<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle1-->Goldmans buy rights to <A HREF="/cgi-bin/article.cgi?f=/n/a/2007/07/02/entertainment/e202028D98.DTL">O.J.'s canceled book.</a> <!--endpagetitle1-->
</FONT></td></tr>
<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle10-->Best of the week's pics: <a href="/columns/throughthelens/">Through The Lens</a>.<!--endpagetitle10-->
</FONT></td></tr>
<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle3-->Opera diva <A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAG6NQQ0BU1.DTL">Beverly Sills</A> dies. <a href="/cgi-bin/object/article?f=/c/a/2007/07/03/SILLS.TMP&o=0">Photos</a>. <!--endpagetitle3-->
</FONT></td></tr>
<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle4-->Oakland garbage collectors are <a href="http://sfgate.com/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3AG1.DTL">locked out</a>.<!--endpagetitle4-->
</FONT></td></tr>
<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle7--><a href="http://sfgate.com/cgi-bin/article.cgi?f=/c/a/2007/07/03/DDGK9QPN781.DTL">'Cherry Orchard'</a> plays in Ashland.<!--endpagetitle7-->
</FONT></td></tr>
<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle8-->Rules of <A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAG6NQQ0U11.DTL">forest management</a> to be reviewed.<!--endpagetitle8-->
</FONT></td></tr>
<tr><td valign="top" colspan="2"><img src="/templates/types/homepage/graphics/bluedot6x7.gif" width="6" height="7" border="0" vspace="0" hspace="0"><FONT SIZE="1" FACE="geneva,arial,sans-serif"><!--pagetitle9--><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3AI1.DTL">Tough test</A>  for voting mchines.<!--endpagetitle9-->
</FONT></td></tr>

</table>



</p>
<p>
<img src="/templates/types/homepage/graphics/insidesfgate.gif" width="220" height="15" border="0" vspace="0" hspace="0"><br />
<table width="220" cellpadding="1" cellspacing="0" border="0">
<tr><td bgcolor="#CC9966">
<table width="220" cellpadding="4" cellspacing="0" border="0" bgcolor="#FFFFFF">



<tr> <td valign="top" align="left">
<a href="/listings/macroevent.php?events,m45"><img src="/c/pictures/2006/07/05_t/mn_firewowrks1_lm_t.gif" align="left" border="1" alt="" hspace="2px"></a></td>
    <td valign="middle" align="left" class="text1sm" style="padding: 0 0 0 3px;"><img src="/templates/types/gatemainpages/images/clear.gif" width="30" height="1" border="0" vspace="0" hspace="0"><br />
    <font size="1" face="geneva,arial,sans-serif"><b><a href="/listings/macroevent.php?events,m45">Fourth Of July</a></b><br />From parades to live music to, of course, fireworks, the Bay Area is bursting with July 4 celebrations. <a href="/summerpicnics/">Or pack a picnic</a>!<br /></font>

<!-- don't pull these tags up alongside the previous text, it causes bad spacing -->

</td></tr>





<tr><td colspan="2">
<img src="/templates/types/homepage/graphics/dashes210x5.gif" width="210" height="5" border="0" vspace="0" hspace="0"></td></tr>

<tr> <td valign="top" align="left">
<a href="/cgi-bin/living/gay/pride2007"><img src="/c/pictures/2007/06/25_t/ba_gaypride405_t.gif" align="left" border="1" alt="" hspace="2px"></a></td>
    <td valign="middle" align="left" class="text1sm" colspan="2" style="padding: 0 0 0 3px;"><img src="/templates/types/gatemainpages/images/clear.gif" width="30" height="1" border="0" vspace="0" hspace="0"><br />
    <font size="1" face="geneva,arial,sans-serif"><b><a href="/cgi-bin/living/gay/pride2007">Pride 2007</a></b><br />The 37th annual San Francisco LGBT Pride parade is a memory. Check out photos from this year's event or past parades.<br /></font>
<!-- don't pull these tags up alongside the previous text, it causes bad spacing -->
</font>
</td></tr>




<tr><td valign="top" colspan="2">
<img src="/templates/types/homepage/graphics/dashes210x5.gif" width="210" height="5" border="0" vspace="4" hspace="0"><br>
<font size="1" face="geneva,arial,sans-serif">
<b>Find Entertainment Listings:</b><br>
<a href="/eguide/movies/playing/">Movies</a>, <a href="/eguide/search/food/">Food &amp; Dining</a>, <a href="/eguide/search/music/">Music</a>, <a href="/eguide/search/performance/">Theater...</a><br>
</td></tr>





<tr><td colspan="2">
<img src="/templates/types/homepage/graphics/dashes210x5.gif" width="210" height="5" border="0" vspace="0" hspace="0"></td></tr>

<tr> <td valign="top" align="left"> <a href="/mexico/"><img
src="/c/pictures/2007/07/01_t/tr_dsc_2298_t.gif" align="left" border="1" alt=""
hspace="2px"></a></td> <td valign="middle" align="left" class="text1sm"
colspan="2" style="padding: 0 0 0 3px;"><img
src="/templates/types/gatemainpages/images/clear.gif" width="30" height="1"
border="0" vspace="0" hspace="0"><br /> <font size="1"
face="geneva,arial,sans-serif"><b><a href="/mexico/">Mazatl&aacute;n Miracles</a></b><br />After decades of Old Town decay, the city's <a href="/mexico/">cultural heart beats anew</a>.<br
/></font>

<img src="/templates/types/gatemainpages/images/clear.gif" width="30" height="1" border="0" vspace="0" hspace="0"><br /></td></tr>






</table>
</td></tr>
</table>

<!-- <br clear="all" /> -->
<!--include virtual="/personals/includes/home.txt"-->
</P>
<!-- google afc -->
<!-- begin google/afc/javascript/placead.shtml -->
<script type="text/javascript" language="JavaScript"
src=" http://pagead2.googlesyndication.com/pagead/show_ads.js "></script>
<noscript>
  <img height="1"
       alt="google ad"
       width="1"
       border="0"
       src="http://pagead2.googlesyndication.com/pagead/imp.gif?client=ca-sfgate-home_js&amp;event=noscript" />
</noscript>
<!-- end google/afc/javascript/placead.shtml -->


<table width="220" style="border: 1px solid #666; margin: 0 0 10px 0; padding: 5px; width: 220px; background-color:#b6cfbe;">
<tr><td valign="top">

<a href="http://personalshopper.sfgate.com/SS/Page.aspx?&secid=30333&pagenum=1"><img src="/templates/types/homepage/graphics/sfis_64x64.gif" border="1" style="border-color:#ccc"/></a></td>

<td class="text1md"><strong>SFiS</strong><br /><span class="text2sm"><strong>Swingin' Swimwear &mdash;</strong><br />
Summer's Sexiest Suits<br />
<a href="http://personalshopper.sfgate.com/SS/Page.aspx?&secid=30333&pagenum=1">July issue</a> | <a href="http://personalshopper.sfgate.com/SS/Tiles.aspx?&type=sfis">archive</a></span>


</td></tr>
</table>

<img src="/templates/types/homepage/graphics/sub_marketplace1.gif" alt="marketplace" width="220" height="9" hspace="0" vspace="8" border="0" /><br clear="all" />

<table width="220" cellpadding="5" cellspacing="0" border="0" bgcolor="#E6E6E6" style="border: 1px solid #999999; margin: 0 0 5px 0;">

<tr><td>
<div id="buyphotoproducts">

<strong><p class="text1md"><a href="/buyphotos/">Chronicle Photo Store</a></p></strong>
</p>

<div class="row">
<div class="left">
<a href="/buyphotos/"><img src="/templates/types/store/pages/buyphotos/images/homepage_gg100x100.jpg" border="1" /></a></div>

<p class="text1sm">Purchase Chronicle photos from our collection of timeless, telling, newsworthy and beautiful images. </p>


</div>
</div>
</td></tr>

<tr><td>
<div id="buyphotoproducts" class="text1sm">

<div class="row">

<strong><p align="left">Books from<br />
The San Francisco Chronicle Press</strong></p>
</p>

<p><img src="/templates/types/gatemainpages/images/redarrow5x4.gif" width="5" height="4" border="0" hspace="2" vspace="1" /><strong><a href="http://www.sfgate.com/cgi-bin/store/buybooks/workingcook">The Working Cook: Fast And Fresh Meals For Busy People</a></strong> by Tara Duggan</p>

<p><img src="/templates/types/gatemainpages/images/redarrow5x4.gif" width="5" height="4" border="0" hspace="2" vspace="1" /><strong><a href="http://www.sfgate.com/cgi-bin/store/buybooks/sfcentury">San Francisco Century</a></strong> by Carl Nolte</p>

<p><img src="/templates/types/gatemainpages/images/redarrow5x4.gif" width="5" height="4" border="0" hspace="2" vspace="1" /><strong><a href="http://www.sfgate.com/cgi-bin/store/buybooks/mysticalsf">Mystical San Francisco</a></strong> by Fred Larson and Herb Caen</p>
</div>
</div>
</td></tr>



</table>

<table width="220" cellspacing="0" cellpadding="0" border="0">

<tr><td valign="top" align="left" style="padding: 3px 0px 0px 0px;">
<img src="/templates/types/gatemainpages/images/redarrow5x4.gif" vspace="4" hspace="0" width="5" height="4" border="0" /></td>
<td valign="top" align="left" class="text1sm" style="padding: 3px 0px 0px 0px;"><b>
<a href="/jobs/">Yahoo! HotJobs on SFGate.com</a></b><br>
Now you can search over 25,000 job listings in the Bay Area.</a>
</td></tr>

<!-- <tr><td valign="top" align="left" style="padding: 3px 0px 0px 0px;">
<img src="/templates/types/gatemainpages/images/redarrow5x4.gif" vspace="4" hspace="0" width="5" height="4" border="0" /></td>
<td valign="top" align="left" class="text1sm" style="padding: 3px 0px 0px 0px;"><b>
<a href="http://www.sfgate.com/classifieds/chronicle/">Chronicle Classifieds.</a></b><br>
Check out our great NEW offers! Easy online placement.</a>
</td></tr> -->

<tr><td valign="top" align="left">
<img src="/templates/types/gatemainpages/images/redarrow5x4.gif" vspace="4" hspace="0" width="5" height="4" border="0" /></td>

<td valign="top" align="left" class="text1sm">
<b><a href="/mobile/roundpoint/">Chronicle Mobile</a></b><br>
Get The Chronicle on your PDA.
</td></tr>

<tr><td valign="top" align="left">
<img src="/templates/types/gatemainpages/images/redarrow5x4.gif" vspace="4" hspace="0" width="5" height="4" border="0" /></td>

<td valign="top" align="left" class="text1sm">
<a href="http://www.stubhub.com/san-francisco-events-tickets/" onclick=this.href=this.href+'?gcid=C12289x251'><b>Buy &amp; Sell Tickets</a></b><br>
Sports, Concerts and Theater
</td></tr>

</table>







<P>

<!-- ad begin -->
<!--set var="position" value="Right"  -->
<!--include virtual="/templates/types/realmedia/templates/mjx_placement.shtml" -->



</p>
</td>

<td width="10" nowrap><img src="/templates/types/gatemainpages/images/clear.gif" width="10" height="8" border="0" /></td>

<td align="left" valign="top" style="padding: 16px 0px 0px 0px;">
<style type="text/css" title="SFGate">
/* <![CDATA[ */

#container h3.snscores { font-family: Geneva, Arial, sans-serif;
margin:0; padding:0; font-size: 13px; } 

#snscores { width:218px; margin:0 0 10px 0;
border:1px solid #999; }

#snscores table { border: 0; }

#snscores th, #snscores td, #snrefresh, #groupbody p.snscores {
font-family: Geneva, Tahoma, sans-serif; font-size: 10px; }

#snscores th, #snscores td { padding: 1px; }

#snscores th.TSN6, #snscores th.TSN2 { font-weight:normal; }

#groupbody p.snscores { margin: -7px 0 15px 0; padding: 0; }

/* Team-Specific Styles ------------------------------------------------------------------------- */

/* table border color */
#container div.sns_warriors { background: #001c4c; }

/* game period or Final heading */
#container div.sns_giants    th.TSN6 { background: #3a3838; color:#fff; }
#container div.sns_athletics th.TSN6 { background: #005349; color:#fff; }
#container div.sns_49ers     th.TSN6 { background: #900;    color:#fff; }
#container div.sns_raiders   th.TSN6 { background: #fff;    color:#fff; }
#container div.sns_sharks    th.TSN6 { background: #00526f; color:#fff; }
#container div.sns_warriors  th.TSN6 { background: #e16020; color:#fff; }

/* inning/period headings */
#container div.sns_giants    th.TSN2 { background: #f4793e; }
#container div.sns_athletics th.TSN2 { background: #fdc469; }
#container div.sns_49ers     th.TSN2 { background: #ffcf3d; }
#container div.sns_raiders   th.TSN2 { background: #cfcfcf; }
#container div.sns_sharks    th.TSN2 { background: #66cccc; }
#container div.sns_warriors  th.TSN2 { background: #e16020; }

/* team names and scores */
#container div.sns_giants    td.TSN5 { background: #ededed; }
#container div.sns_athletics td.TSN5 { background: #ededed; }
#container div.sns_49ers     td.TSN5 { background: #fff;    }
#container div.sns_raiders   td.TSN5 { background: #ededed; }
#container div.sns_sharks    td.TSN5 { background: #ededed; }
#container div.sns_warriors  td.TSN5 { background: #ededed; }

/* ]]> */
</style>

<!-- *** SCOREBOARD HEADING: edit first, then un-comment -->

<!-- 

<h3 class="snscores">Scoreboard</h3>

-->
<!-- *** SCOREBOARD DIVS: un-comment one  -->

 
<!-- 
<div id="snscores" class="sns_warriors"><script type="text/javascript" language="javascript" src="http://www.sportsnetwork.com/aspdata/clients/sfgate/nbagame.aspx?team=098"></script></div>

<p class="snscores">Get game updates in the <a href="/cgi-bin/blogs/warriors/index?">Warriors blog</a>.</p>
-->


<!-- 
<div id="snscores" class="sns_giants"><script type="text/javascript" language="javascript" src="http://www.sportsnetwork.com/aspdata/clients/sfgate/game.aspx?team=011"></script></div>
<p class="snscores">More Giants news in the <a href="/cgi-bin/blogs/sfgate/indexn?blogid=22">Splash blog</a>.</p>
-->



<!-- 
<div id="snscores" class="sns_athletics"><script type="text/javascript" language="javascript" src="http://www.sportsnetwork.com/aspdata/clients/sfgate/game.aspx?team=037"></script></div>
<p class="snscores">More A's news in the <a href="/cgi-bin/blogs/sfgate/indexn?blogid=21">Drumbeat blog</a>.</p>
-->


<!-- 
<div id="snscores" class="sns_49ers"><script type="text/javascript" language="javascript" src="http://www.sportsnetwork.com/aspdata/clients/sfgate/nflgame.aspx?team=084"></script></div>
-->

<!-- 
<div id="snscores" class="sns_raiders"><script type="text/javascript" language="javascript" src="http://www.sportsnetwork.com/aspdata/clients/sfgate/nflgame.aspx?team=073"></div>
-->

<!-- 
<div id="snscores" class="sns_sharks"><script type="text/javascript" language="javascript" src="http://www.sportsnetwork.com/aspdata/clients/sfgate/nhlgame.aspx?team=142"></script></div>
-->





<!-- *** SCOREBOARD FOOTER PARAGRAPH: optional. edit first, then un-comment 

-->

<font size="2" face="geneva,arial,sans-serif">
<!--ITEM-->
<font size="3" face="helvetica,arial,sans-serif"><B><A 
HREF="/cgi-bin/article.cgi?f=/n/a/2007/07/03/international/i052311D55.DTL&tsp=1">6 Doctors In UK Terror Plot</a></b></FONT><BR>
Suspect burned in Glasgow attack is Lebanese physician. Another doc nabbed in Australia. <font color="#333333" size="1">AP</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?file=/n/a/2007/07/03/international/i101500D76.DTL">Brown cheered for attacks response</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/n/a/2007/07/03/international/i071939D27.DTL">Yemen officials feared attack</a></font>
<P>

<!--ITEM-->
<font size="3" face="helvetica,arial,sans-serif"><B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGFQQQGPM9.DTL&tsp=1">Insanity Claim In SF Attack</a></b></FONT><BR>
Man accused of accosting Nobel winner and Holocaust survivor Elie Wiesel in a hotel pleads not guilty. <br><font color="#FF0000" size="1">Chronicle Breaking News 2:23 PM</font>
<P>


<img src="/templates/types/homepage/graphics/dashes215x5.gif" width="215" height="5" border="0" vspace="3" hspace="0"><br>
<table border="0" cellpadding="2" cellspacing="0" bgcolor="#EEEEEE" width="215">
<tr><td valign="top">
<b><font size="2" face="geneva,arial,sans-serif">AP Headlines</font></b></td></tr>
<tr><td valign="top"><font size="1" face="geneva,arial,sans-serif"><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><a href="/cgi-bin/article.cgi?f=/n/a/2007/07/03/national/a141205D92.DTL">Court: Mental Anguish Money Taxable</a></font></td></tr>

<tr><td valign="top"><font size="1" face="geneva,arial,sans-serif"><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><a href="/cgi-bin/article.cgi?f=/n/a/2007/07/03/national/a120454D74.DTL">City Sued for Court's Jesus Painting</a></font></td></tr>

<tr><td valign="top"><font size="1" face="geneva,arial,sans-serif"><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><a href="/cgi-bin/article.cgi?f=/n/a/2007/07/03/international/i141930D92.DTL">Steamy YouTube Clip Riles Lawmakers</a></font></td></tr>

<tr><td valign="top"><font size="1" face="geneva,arial,sans-serif"><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><a href="/cgi-bin/article.cgi?f=/n/a/2007/07/03/politics/p122440D94.DTL&type=politics">Giuliani Campaign Pulls in $17M in 2Q</a></font></td></tr>
</table>
<img src="/templates/types/homepage/graphics/dashes215x5.gif" width="215" height="5" border="0" vspace="5" hspace="0"><br><br>


<font size="2" face="geneva,arial,sans-serif">
<!--leave the font tag above-->

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3GL1.DTL">Motorist Saw Priest's Car Plunge</a></b><BR>
Witness called 911 after car with missing Calif. pair went off the road in Oregon. But crews couldn't find them. <a href="http://cdn.sfgate.com/blogs/sounds/sfgate/chroncast/2007/07/03/Oregon911Call-20070703.mp3">911 tape audio</a>. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?file=/c/a/2007/07/03/BAGVRQQH488.DTL">Fire official ID'd as Carquinez crash victim</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGJFQQGVJ5.DTL">Use Less Power, Residents Asked</a></b><BR>
Power grid manager asks consumers to conserve today and this week amid heat and SoCal electrical problems. <br><font color="#FF0000" size="1">Chronicle Breaking News 2:42 PM</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?file=/c/a/2007/07/03/BAGJFQQ9408.DTL">Power back on in Excelsior after outage</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAG4RQQ9NF7.DTL">Deep, Dark Rx Chocolate</a></b><BR>
A square a day keeps the blood pressure at bay, according to a new German study. <br><font color="#FF0000" size="1">Chronicle Breaking News 1:03 PM</font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?file=/n/a/2007/07/03/state/n130732D98.DTL">No-Pooh School Dress Code Nixed</a></b><BR>
Judge in Tigger socks lawsuit bars Napa district from enforcing strict attire policy.  <font color="#333333" size="1">AP</font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/n/a/2007/07/03/national/w092713D45.DTL&tsp=1">Libby Pardon Still Possible</a></b><BR>
Bush refuses to close the door on eventually clearing the ex-White House aide altogether. <font color="#333333" size="1">AP</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?file=/c/a/2007/07/03/MNGPNQQ31V1.DTL">Will commuting Libby's sentence hurt Bush?</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/EDG6QQ4TMA1.DTL">Editorial: Trumping the rule of law</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/blogs/foreigndesk/detail?blogid=16&entry_id=18223">Ross Report</a> | <A HREF="/cgi-bin/blogs/sfgate/detail?blogid=13&entry_id=18211">2 Cents</a></font>
<P>

<!--ITEM-->
<B><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3CV1.DTL">Soccer Star Slaying A Mystery</a></b><BR>
Jose Santillan, 19, had incredible skills, but four men ended his life in a vicious N. Beach attack. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3AM1.DTL">Gang member guilty of killing rival</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/blogs/sgreen/detail?blogid=40&entry_id=18219">'You Will Look At Balls'</a></b><BR>
That's one of the deep thoughts Serena Williams reads to herself at Wimbledon. Bruce Jenkins cringes. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/SPG9FQPSQ91.DTL">More Jenkins at Wimbledon</A></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/DDG6TQOR2G1.DTL">Please To Be Enjoying Gimmick</a></b><BR>
Local 7-Eleven becomes the Kwik-E Mart of "The Simpsons." <font color="#333333" size="1">Chronicle</font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/DDG6TQOQE41.DTL">Our Patriotic Duty To Blow Stuff Up</a></b><BR>
Fireworks are banned in almost every Bay town. An outrage! says Peter Hartlaub.  <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/blogs/sfgate/detail?blogid=13&entry_id=18210">2 Cents: Best place to watch?</A> | <A HREF="/listings/macroevent.php?events,m45">4th events</A></font>
<P>

<!--ITEM-->
<B><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/MNGPNQQ3211.DTL">Warming Of Political Tensions</a></b><BR>
Two members of the state's Air Resources Board exit, saying the governor pressured them. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGFTQQ9RU47.DTL">Enviro lawyer to lead state air board</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAG3VQQ8EV18.DTL">Yosemite-Area Soldier Killed</a></b><BR>
Sergeant, 31, slain in Ta'meem, Iraq, when his unit comes under fire. <br><font color="#FF0000" size="1">Chronicle Breaking News 11:27 AM</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A 
HREF="/cgi-bin/article.cgi?file=/n/a/2007/07/03/national/a102707D60.DTL">GI could face death in Iraqi slayings</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAGBIQQ3GF1.DTL">Rise Of An Intestinal Defect</a></b><BR>
Babies of young mothers are at the greatest risk of the organ growing outside the body.  <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAG6NQQ0TV1.DTL">TB testing for students called a waste</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?file=/c/a/2007/07/03/MNGPNQQ31T1.DTL">29 Run For Coverage</a></b><BR>
Only 82,000 uninsured in SF remain as city's universal health care initiative begins. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/MNG4NQQ13T1.DTL">Answers to health plan questions</a></font>
<P>

<!--ITEM-->
<b><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/SPGOAQQ4111.DTL">Welcome, Rookie; Don't Unpack</a></b><BR>
Warriors greet Brandan Wright, but he may be gone if the team can land superstar Kevin Garnett. <font color="#333333" size="1">Chronicle</font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/g/a/2007/07/03/apop.DTL">Sound Of One Troupe Laughing</a></b><BR>
The 18 Mighty Mountain Warriors is ready for its sketch comedy closeup. Asian Pop. <A HREF="/cgi-bin/article/comments/view?f=/g/a/2007/07/03/apop.DTL#commentform">Comment</A>.  <font color="#333333" size="1">SFGate</font>
<P>

<!--ITEM-->
<b><A HREF="/cgi-bin/article.cgi?f=/chronicle/archive/2007/07/03/SPGOAQQ3DF1.DTL">Big Love For Big Hurt</a></b><BR>
Pregame embrace fest for the A's and Frank Thomas. Gwen Knapp. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BAG6NQQ0V91.DTL">Extreme All-Star game safety measures</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/allstar/">Special All-Star page</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/SPGOAQQ40P1.DTL">Blue Jays torch DiNardo, A's</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/SPG9FQPSQ71.DTL">Giants questions in need of answers</a></font>
<p>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BUGM5QPPLE1.DTL">Yahoo!, Personalized Searches</a></b><BR>
The Net titan will start serving users with more personal and local marketing pitches. <font color="#333333" size="1">Chronicle</font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BUGM5QPPLG1.DTL">Apple says Universal won't quit iTunes</a></font>
<br><img src="/graphics/homepage/blackdot5x7.gif" width="5" height="7" border="0" vspace="0" hspace="0"><font size="1"><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/BUGM5QPPLO1.DTL">NetSuite filing shows link to Oracle</a></font>
<P>

<!--ITEM-->
<B><A 
HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/DDG6TQOR2I1.DTL">Behold The Stylish Black Slab</a></b><BR>
Molecular Foundry at UC Berkeley packs a streamlined architectural punch. John King. <font color="#333333" size="1">Chronicle</font>
<P>

<!--ITEM-->
<b><A HREF="/cgi-bin/article.cgi?f=/c/a/2007/07/03/DDG6TQOR2E1.DTL">Flick They Should've Annulled</a></b><BR>
"License To Wed" will haunt its makers for all eternity. Mick LaSalle.  <font color="#333333" size="1">Chronicle</font>
<P>




<!-- end of page -->
 

</font>
</td>
</tr>
<tr>
<td align="center" valign="middle" colspan="3">
<hr noshade="noshade" size="1" />
<table border="0" cellpadding="0" cellspacing="0" width="100%">
<tr><td align="center">
<font size="1" face="geneva, arial, sans-serif">
<a href="/staff/">SFGate Staff</a> | 
<a href="/pages/makehomepage.shtml">Make SFGate your home page</a> | 
<a href="http://www.sfchronicle.com/hr/">Jobs at the Chronicle</a> |
<a href="/pages/privacy/">Privacy Policy</a> | 
<a href="/pages/corrections/">Corrections</a>

</font></td></tr></table>

<hr noshade="noshade" size="1" />

<p><FONT SIZE="1" FACE="Geneva, Arial, Sans-Serif"><A
HREF="http://www.sfgate.com/chronicle/info/copyright/" target="_new">&#153; &#169;
2007 Hearst Communications Inc.</A></FONT>


<!--------END MAIN SPREAD--------> 

</td></tr>
</table>

</div><!-- /#groupbody -->

<div id="groupmenu">
<!-- START SKY AD -->

<script language="javascript" type="text/javascript">
<!--
OAS_AD('Position2');
//-->
</script>
<!-- END SKY AD -->

<p id="localadshead">Local Advertisers</p>
<div id="localads">
<div id="localadsinner">



<script language="javascript" type="text/javascript">
<!--
OAS_AD('x31');
//-->
</script>


<script language="javascript" type="text/javascript">
<!--
OAS_AD('x32');
//-->
</script>


<script language="javascript" type="text/javascript">
<!--
OAS_AD('x33');
//-->
</script>


<script language="javascript" type="text/javascript">
<!--
OAS_AD('x34');
//-->
</script>



</div>
</div>




</div><!-- /#groupmenu -->

<div class="clear">&nbsp;</div>
</div>





<!--set var="position" value="x12"  -->
<!--include virtual="/templates/types/realmedia/templates/mjx_placement.shtml" -->

</body> </html>











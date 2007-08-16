#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

BEGIN {
    use_ok('SL::Model::Ad');
}

my $content = do { local $/ = undef; <DATA> };

my $ad       = _ad_content();
my $css_link = 'http://www.redhotpenguin.com/css/local.css';

use Time::HiRes qw(tv_interval gettimeofday);

my $start = [gettimeofday];
my $ok = SL::Model::Ad::container( \$css_link, \$content, \$ad );
ok($ok);
my $interval = tv_interval( $start, [gettimeofday] );

like( $content, qr/$ad/s,       'ad not inserted ok' );
like( $content, qr/$css_link/, 'css link not inserted ok' );
diag("Ad insertion took $interval");
cmp_ok( $interval, '<', 0.010,
    'Ad inserted in less than 10 milliseconds' );

sub _ad_content {
    my $ad = <<HTML;
<p><a style="text-decoration: none;" href="http://www.local.com/">
<img style="position: absolute; top: 6px; left: 8px;border: 0px;padding: 0px;" src="http://www.redhotpenguin.com/images/sl/local_logo.gif" /></a>
<span class="sl_textad_text">
<!-- SEARCH FORM -->
TODO - haven't figured out how to escape the local.com html yet
<!--END SEARCH FORM-->
</span>
<span class="sl_black">
<a href="/sl_secret_blacklist_button" >Close this Bar</a>
</span>
<span class="sl_link">
<a href="http://www.silverliningnetworks.com/" >Ad Bar by Silver Lining</a></span></p>
HTML
    return $ad;
}

1;

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><head>































<meta name="GOOGLEBOT" content="NOSNIPPET">
<meta name="GOOGLEBOT" content="NOARCHIVE">
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"><!--added for registration bypass2 October 3,2002--><!-- CDS hostname /sbkj2kappp01/ -->

 

<meta http-equiv="refresh" content="1200;URL=/public/us?refresh=on"> 
<meta name="pagename" content="U.S. Home_0_0002_public">
<meta name="section" content="Home">
<meta name="subsection" content="Home Page Public">
<meta name="csource" content="WSJ Online">
<meta name="ctype" content="home page">
<meta name="displayname" content="U.S. Home">
<meta name="keywords" content="Business Financial News, Business News Online, Personal Finance News, Financial News, Business News, Finance news, Personal Finance, Personal Financial News, Busines Newspaper">
<meta name="description" content="Business Financial News - The Wall Street Journal is the world's leading business publication. At WSJ.com users can access business news online as well as personal finance news">
 
<link rel="SHORTCUT ICON" href="http://online.wsj.com/favicon.ico">

<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var userName = '(none)';
var serverTime = new Date("July 24, 2007 02:45:07");
//-->
</script>
<meta http-equiv="Cache-Control" content="no-cache">
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT">
<link rel="alternate" type="application/rss+xml" title="WSJ.com: What's News US" href="http://feeds.wsjonline.com/wsj/xml/rss/3_7011.xml">
<link rel="stylesheet" href="us_files/j20type.css" type="text/css">
<link rel="stylesheet" href="us_files/freeTodayBoxAdjuster.css" type="text/css">
<script type="text/javascript"><!--
var pID="0_0002_public",nSP="",uP="http://online.wsj.com",gcPH="/pj/PortfolioDisplay.cgi",gcWIA="http://users.wsj.com/WebIntegration/WebIntegrationServlet",gcLFU="https://users1.wsj.com/lmda/do/submitLogin",gcHSP="https://",gcDomain="online.wsj.com",pStl="nonsub-summary",PSS="0_0002_public",PSSG="header0_0002_public",_navTxt="News";
var isTrial=false, isDenial=false, isFree=false;
//--></script>

	<script type="text/javascript">var mpsection='Home Page Public'</script>


<script type="text/javascript" src="us_files/2007_07_20_05_19.html"></script>
<script type="text/javascript" src="us_files/navigation.js"></script><script type="text/javascript" src="us_files/headerscripts.js"></script><script type="text/javascript" src="us_files/userstate.html"></script><script type="text/javascript" src="us_files/commonFunctions.js"></script><script language="JavaScript">
<!--
function refreshWin(url){;window.location.reload(false);}
//-->
</script><script language="JavaScript1.1">
<!--
function refreshWin(url){;window.location.replace(url);}
//-->
</script><script language="JavaScript1.2">
<!--
function refreshWin(url){;window.location.href=url;}
//-->
</script><script type="text/javascript" src="us_files/rightClickSearch.js"></script><script type="text/vbscript" src="us_files/vbFunctions.js"></script><script src="us_files/httpRequest.js"></script><script src="us_files/stringFunctions.js"></script><title>Business Financial News, Business News Online &amp; Personal Finance News at WSJ.com - WSJ.com</title><style type="text/css">
<!--
.vTabN, a.vTabN:link, a.vTabN:visited, a.vTabN:active {
	/*float:left;*/
	border-left:1px solid #CCC;
	background-image:url(/img/hpVideoBg0.gif);
	background-position:left top;
	background-repeat:repeat-x;
	font-size:10px;
	padding:2px 5px 2px 5px;
	color:#0253b7;
	background-color:#5a87b0;
}
.vTabS, a.vTabS:link, a.vTabS:visited, a.vTabS:active, a.vTabN:hover {
	/*float:left;*/
	border-left:1px solid #CCC;
	background-image:url(/img/hpVideoBg1.gif);
	background-position:left top;
	background-repeat:repeat-x;
	font-size:10px;
	padding:2px 5px 2px 5px;
	color:#FFF;
}
a.vTabS:hover,a.vTabN:hover {
	text-decoration: none;
}
#vTabC {
	border:1px solid #CCC;
	height:17px;
	overflow:hidden;
	border-left:0px solid #CCC;
	width:231px;	
}
-->
</style></head><body style="margin: 0px; padding: 0px; background-color: rgb(255, 255, 255);" onunload="onUnloadAction();exitPopup();" onload="onLoadAction()"><script id="DL_260080_37_263293" type="text/javascript" src="us_files/decide.html"></script><div id="ndiv" style="position: absolute; z-index: 1; visibility: hidden; left: 127px; top: 417px;" onmouseover="OverNav=true" onmouseout="OverNav=false"><table bgcolor="#000000" border="0" cellpadding="1" cellspacing="0" width="130"><tbody><tr><td bgcolor="#000000"><table bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="0" width="128"><tbody><tr><td><table align="center" bgcolor="#efefef" border="0" cellpadding="0" cellspacing="0" width="128"><tbody><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/redirect/markets.html?mod=1_0021" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Markets Main</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/todays_market.html?mod=2_0064" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Today's Markets</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/marketsdata?mod=2_3000" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Markets Data Center</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/market_movers.html?mod=2_0022" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Market Movers</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/articles/heard_on_the_street?mod=2_0033" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Heard on the Street</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/commodities.html?mod=2_0030" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Commodities</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/credit_markets.html?mod=2_0031" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Credit Markets</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/foreign_exchange.html?mod=2_0032" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Foreign Exchange</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/public/page/deals.html?mod=2_0029" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Deals &amp; Deal Makers</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/hedge_funds.html?mod=2_1154" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Hedge Funds</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/tech_stocks.html?mod=2_0024" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Tech Stocks</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/asia_markets.html?mod=2_0027" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Asia Markets</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/europe_markets.html?mod=2_0026" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Europe Markets</span></a></nobr></td></tr><tr bgcolor="#ffffff"><td height="1"><spcer type="block" width="1"></spcer></td></tr><tr><td height="20" valign="middle"><nobr><spacer height="20"><img src="us_files/b.gif" align="texttop" border="0" height="17" width="1"><span style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 14px; line-height: normal; font-size-adjust: none; font-stretch: normal;">&nbsp;&nbsp;</span><a href="http://online.wsj.com/page/americas_markets.html?mod=2_0028" style="color: rgb(0, 0, 0); font-family: arial,sans-serif; font-style: normal; font-variant: normal; font-weight: normal; font-size: 12px; line-height: normal; font-size-adjust: none; font-stretch: normal;"><span class="p12">Americas Markets</span></a></nobr></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></div>

<div id="rcMenu" class="arial" style="position: absolute; z-index: 1; left: 0px; top: 0px; width: 340px; display: none;"><div style="background: rgb(248, 249, 239) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;"><img src="us_files/right_click_search_header.gif" alt="Search Results for Selected Items" usemap="#rightClickSearchImageMap" border="0" height="41" width="340"><map name="rightClickSearchImageMap" id="rightClickSearchImageMap"><area shape="rect" coords="312,15,330,32" href="#" alt="close" onclick="hideRightClickSearch();return false"></map></div><div id="rcSearchText" style="border: 1px solid rgb(126, 155, 196); padding: 0px 18px; background: rgb(126, 155, 196) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; color: rgb(255, 255, 255); font-weight: bold; font-size: 95%;" title=""></div><div id="rcMenuContent" style="border: 1px solid rgb(126, 155, 196); padding: 0px 18px 15px; background: rgb(237, 242, 247) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; color: rgb(102, 102, 102); font-size: 75%;"></div></div><script type="text/javascript" src="us_files/rolloverQuotes.js"></script><script type="text/javascript" src="us_files/mouse.js"></script><script type="text/javascript" src="us_files/objDimensions.js"></script><script type="text/javascript" src="us_files/SimpleDateFormat.js"></script><script type="text/javascript" src="us_files/video.js"></script>
<script type="text/javascript" src="us_files/quotesearch.js"></script>
<script type="text/javascript" src="us_files/cornerstone.js"></script>
<script type="text/javascript" src="us_files/dateTimeFunctions.js"></script>
<script type="text/javascript" src="us_files/stringFunctions.js"></script>
<script type="text/javascript" src="us_files/mathFunctions.js"></script>
<script type="text/javascript" src="us_files/xmlFunctions.js"></script>
<script type="text/javascript" src="us_files/httpRequest.js"></script>
<script type="text/javascript" src="us_files/partialRefresh.js"></script>
<script type="text/javascript" src="us_files/matchheight.js"></script>

<script type="text/javascript">
<!--
window.name = "wndMain"
function onLoadAction(){
	setTimeout('initPartialRefresh()',3*1000);matchHeight2('left_rr','right_rr');SurveyPopUp('WSJPopup','http://public.wsj.com/marketing/nonsub_popup/entry_top10_mdc.html',100,'1d+',373,475,'off',0,0);;
	
}

function onUnloadAction(){
;
}
//-->
</script>


<a name="top"></a>



<!-- Begin header -->
<div style="border: 0px none ; margin: 0px; padding: 0px; width: 990px;">
	<div>
		







<!-- HEADER TABLE STARTS HERE -->
<script type="text/javascript">
<!--
var publicPromoJs='';publicPromoJs+='<'+'div style="padding:0px 0px 0px 0px; text-align:center;">		<'+'span id="Header_Promo_public_us_302x52"><'+'script type="text/javascript">				var tempHTML = \'\';		var adURL = \'http://ad.doubleclick.net/adi/\'+((GetCookie(\'etsFlag\'))?\'ets.wsj.com\':\'interactive.wsj.com\')+\'/us;!category=;msrc=\' + msrc + \';\' + segQS + \';sz=302x52;ord=1234307803078030780;\';		if ( isSafari ) {		  tempHTML += \'<'+'iframe id="publicUSpromo" src="\'+adURL+\'" width="302" height="52" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:302">\';		} else {		  tempHTML += \'<'+'iframe id="publicUSpromo" src="/static_html_files/blank.htm" width="302" height="52" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:302px;">\';		  ListOfIframes.publicUSpromo= adURL;		}		tempHTML += \'<'+'a href="http://ad.doubleclick.net/jump/\'+((GetCookie(\'etsFlag\'))?\'ets.wsj.com\':\'interactive.wsj.com\')+\'/us;!category=;msrc=\' + msrc + \';\' + segQS + \';sz=302x52;ord=1234307803078030780;" target="_new">\';		tempHTML += \'<'+'img src="http://ad.doubleclick.net/ad/\'+((GetCookie(\'etsFlag\'))?\'ets.wsj.com\':\'interactive.wsj.com\')+\'/us;!category=;msrc=\' + msrc + \';\' + segQS + \';sz=302x52;ord=1234307803078030780;" border="0" width="302" height="52" vspace="0" alt="" /></'+'a><'+'br /></'+'iframe>\';		document.write(tempHTML);				</'+'script>	</'+'span></'+'div>';var searchBoxJs='';searchBoxJs+='<'+'table border="0" cellpadding="0" cellspacing="0"><'+'tr><'+'td width="145" style="padding-right:10px" valign="top"><'+'div class="b12">Article Search</'+'div><'+'form name="main_article_search" id="main_article_search" action="/search" method="post" style="margin:0px;padding:0px;"><'+'input type="text" name="KEYWORDS" value="" size="9" style="width:113px;margin:0px;margin-right:3px;" /><'+'input type="image" src="/img/wsj_hed_search_btn.gif" alt="Submit Search" style="border:0;width:19px;height:19px;margin:0px;vertical-align:bottom" /><'+'script type="text/javascript">if (window.document.main_article_search.action[0]==\'/\'){window.document.main_article_search.action=(!loggedIn)?nSP+"/public/search/page/3_0466.html":nSP+window.document.main_article_search.action;}else{window.document.main_article_search.action=(!loggedIn)?"/public/search/page/3_0466.html":window.document.main_article_search.action;}</'+'script></'+'form><'+'div class="p10"><'+'script type="text/javascript">document.write(\'<\'+\'a class="unvisited p10" href="\'+nSP+\'/advanced_search">Advanced Search<\'+\'/a>\');</'+'script></'+'div><'+'form name="fund_search" id="fund_search" action="/fund/page/fund_snapshot.html" method="get" style="padding:0px;margin:0px 0px 0px 0px;">    <'+'input type="hidden" name="page" value="9" />    <'+'input type="hidden" name="sym" size="8" /></'+'form></'+'td><'+'td width="145" valign="top"><'+'div class="b12">Quotes &amp; Research</'+'div><'+'form name="US_search" id="US_search" action="/quotes/main.html" method="get" onsubmit="return checkCRSymbol(\'US_search\',\'fund_search\');" style="margin:0px;padding:0px;">	<'+'input type="hidden" name="type" value="usstock usfund" />	<'+'input type="text" name="symbol_or_name" value="" size="9" style="width:113px;background-color:#E7EFEF;margin:0px;margin-right:3px" />	<'+'input type="image" src="/img/wsj_hed_quotes_research_btn.gif" alt="Submit Search" style="width:19px;height:19px;border:0;margin:0px;vertical-align:bottom"/>	<'+'div class="p10">		<'+'script type="text/javascript">				if(window.document.fund_search.action[0]==\'/\')window.document.fund_search.action=nSP+window.document.fund_search.action;		if(window.document.US_search.action[0]==\'/\')window.document.US_search.action=nSP+window.document.US_search.action;		var showTypeForNonSubs = 1;		var showTypeForSubs = 1;		var subscriber = (GetCookie("user_type") == "subscribed");		if ( (showTypeForSubs && subscriber) || (showTypeForNonSubs && !subscriber) ) {			document.write(\'<'+'table cellpadding="0" cellspacing="0" border="0"><\'+\'tr><\'+\'td><\'+\'input type="radio" name="sym_name_switch" value="symbol" checked="checked"/></\'+\'td><\'+\'td class="p10">Symbol(s)&nbsp;</\'+\'td>\');			document.write(\'<\'+\'td><\'+\'input type="radio" name="sym_name_switch" value="name"/></\'+\'td><\'+\'td class="p10">Name</\'+\'td></\'+\'tr></\'+\'table>\');		} else {			document.write(\'<\'+\'input type="hidden" name="sym_name_switch" value="symbol"/>\');			document.write(\'Enter Symbol\');		}				</'+'script>	</'+'div></'+'form></'+'td></'+'tr></'+'table>';var loginBoxJs='';loginBoxJs+='<'+'div>	<'+'div style="border-bottom:1px solid #9BADCE;background-color: #EFF7F7;background-image: url(/img/hp_login_top_bk.gif);background-repeat: repeat-x;background-position: top;">		<'+'div style="background-image: url(/img/hp_login_rt_bl_bk.gif);background-repeat: repeat-y;background-position: right;">			<'+'div style="background-image: url(/img/hp_login_le_bl_bk.gif);background-repeat: repeat-y;">				<'+'div style="background-image: url(/img/hp_login_tl_bk.gif);background-repeat: no-repeat;background-position: left top;">					<'+'div style="background-image: url(/img/hp_login_tr_bk.gif);background-repeat: no-repeat;background-position: right top;">						<'+'form method="post" action="/login" name="login_form" id="login_form" style="margin:0px;" onsubmit="suppress_popup=true;return true;">							<'+'input type="hidden" name="url" value="/home" />							<'+'table align="center" style="padding:2px 0px 0px 0px;" border="0" cellpadding="0" cellspacing="0">								<'+'tr>									<'+'td style="letter-spacing: -1px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 9px;">User Name:&nbsp;</'+'td>									<'+'td><'+'input type="text" name="user" size="9" maxlength="30" style="width:54px;font-size:9px;" /></'+'td>									<'+'td style="letter-spacing: -1px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 9px;">Password:&nbsp;</'+'td>									<'+'td><'+'input type="password" name="password" size="9" style="width:50px;font-size:9px;" maxlength="30" /></'+'td>								</'+'tr>							</'+'table>							<'+'table align="center" style="padding:2px 0px 0px 0px;" border="0" cellpadding="0" cellspacing="0" width="100%">								<'+'tr>									<'+'td width="14" style="padding-left:12px;"><'+'input type="checkbox" id="savelogin" name="savelogin" value="true" checked="checked" style="padding:0px;margin:0px;width:14px;height:13px;" /></'+'td>									<'+'td class="pb11" valign="middle" colspan="3" style="color:#9D0903;"><'+'label for="savelogin" style="cursor:pointer;">Remember Me</'+'label></'+'td>									<'+'td class="pb11" align="right" style="padding-right:7px;"><'+'a href="/login" onclick="document.login_form.submit();return false" style="color:#9D0903;">Log In&nbsp;<'+'input name="img" type="image" src="/img/loginArrow.gif" alt="" style="width:5px;height:9px;border:0"/></'+'a></'+'td>								</'+'tr></'+'table></'+'form>					</'+'div>				</'+'div>			</'+'div>		</'+'div>	</'+'div>	<'+'div style="background-image: url(/img/hp_login_bottom_bk.gif);background-repeat: repeat-x;background-position: bottom;">		<'+'div style="background-image: url(/img/hp_login_rt_wt_bk.gif);background-repeat: repeat-y;background-position: right;">			<'+'div style="background-image: url(/img/hp_login_le_wt_bk.gif);background-repeat: repeat-y;">				<'+'div style="background-image: url(/img/hp_login_bl_bk.gif);background-repeat: no-repeat;background-position: left bottom;">					<'+'div style="padding:2px 0px 3px 0px;background-image: url(/img/hp_login_br_bk.gif);background-repeat: no-repeat;background-position: right bottom;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 9px;text-align: center;letter-spacing: -1px;"><'+'a href="https://users1.wsj.com/lmda/do/forgotPass">Forgot your username or password?</'+'a> <'+'span style="color:#666666">|</'+'span> 					<'+'script type="text/javascript">										var sourceCode = "FVS05_0107";					if(pID==\'0_0013\'){						sourceCode="SUBSCRIBE_Home_Europe_Login"					}else if(pID==\'0_0014\'){						sourceCode="SUBSCRIBE_Home_Asia_Login"					}else if(pID==\'2_0433\'){						sourceCode="SUBSCRIBE_Todays_Print_US_Login"					}else if(pID==\'2_0434\'){						sourceCode="SUBSCRIBE_Todays_Print_Europe_Login"					}else if(pID==\'2_0435\'){						sourceCode="SUBSCRIBE_Todays_Print_Asia_Login"					}else if(pID==\'0_0110\'){						sourceCode="SUBSCRIBE_My_Online_Journal_US_Login"					}else if(pID==\'0_0112\'){						sourceCode="SUBSCRIBE_My_Online_Journal_Europe_Login"					}else if(pID==\'0_0114\'){						sourceCode="SUBSCRIBE_My_Online_Journal_Asia_Login"					}else if(pID==\'0_0800\'){						sourceCode="SUBSCRIBE_Public_RT_Login"					}					document.write(\'<'+'a href="/reg/promo/\'+sourceCode+\'">Subscribe</'+'a>\');										</'+'script>					</'+'div>				</'+'div>			</'+'div>		</'+'div>	</'+'div></'+'div><'+'script type="text/javascript">document.login_form.url.value=\'http://\'+gcDomain+(pID.indexOf(\'2_3\')==-1?\'/home\':\'/mdc/page/marketsdata.html?mod=mdc_hdr_login\');document.login_form.action=gcLFU;</'+'script>';var userInfoBoxJs='';userInfoBoxJs+='<'+'script type="text/javascript">try {  var userName=laserJ4J?laserJ4J.getUser():"";} catch(e) {  var userName="";}if(userName == null){	userName = "";}</'+'script><'+'div style="width:223px">	<'+'div style="border-bottom:1px solid #9BADCE;background-color: #EFF7F7;background-image: url(/img/hp_login_top_bk.gif);background-repeat: repeat-x;background-position: top;">		<'+'div style="background-image: url(/img/hp_login_rt_bl_bk.gif);background-repeat: repeat-y;background-position: right;">			<'+'div style="background-image: url(/img/hp_login_le_bl_bk.gif);background-repeat: repeat-y;">				<'+'div style="background-image: url(/img/hp_login_tl_bk.gif);background-repeat: no-repeat;background-position: left top;">					<'+'div style="background-image: url(/img/hp_login_tr_bk.gif);background-repeat: no-repeat;background-position: right top;text-align: center;">						<'+'div class="pb11" style="padding-top:4px;padding-bottom:3px;height:15px;vertical-align: middle;">WELCOME <'+'span class="userName" style="color:#9D0903;"><'+'script type="text/javascript">						document.write((userName.length>11)?userName.substring(0,11)+"...":userName)												</'+'script></'+'span> | <'+'span class="p10"><'+'a href="#" onclick="(!GetCookie(\'logoutprompt\'))?OpenWin(\'/static_html_files/logout_confirmation.htm\',\'logoutconfirmation\',325,200,\'off\',true,0,0,true):window.location=\'\\/logout\';return false" class="unvisited p10">Log Out</'+'a></'+'span></'+'div>					</'+'div>				</'+'div>			</'+'div>		</'+'div>	</'+'div>	<'+'div style="background-image: url(/img/hp_login_bottom_bk.gif);background-repeat: repeat-x;background-position: bottom;">		<'+'div style="background-image: url(/img/hp_login_rt_wt_bk.gif);background-repeat: repeat-y;background-position: right;">			<'+'div style="background-image: url(/img/hp_login_le_wt_bk.gif);background-repeat: repeat-y;">				<'+'div style="background-image: url(/img/hp_login_bl_bk.gif);background-repeat: no-repeat;background-position: left bottom;">					<'+'div id="msgCenter" style="background-image: url(/img/hp_login_br_bk.gif);background-repeat: no-repeat;background-position: right bottom;text-align: center;">  <'+'table cellpadding="0" cellspacing="0" border="0" width="100%">  <'+'tr>    <'+'td class="p10" style="padding:4px 0px 5px 0px;border-right:1px solid #9BADCE;" align="center"><'+'a href="/setup/setup_center_mainpage" class="unvisited p10">Edit Preferences</'+'a></'+'td>    <'+'td class="p10" style="padding:4px 0px 5px 0px;" align="center"><'+'a href="/acct/setup_account" class="unvisited p10">My Account/Billing</'+'a></'+'td>  </'+'tr>  </'+'table>					</'+'div>				</'+'div>			</'+'div>		</'+'div>	</'+'div></'+'div>';
//-->
</script>
<table border="0" cellpadding="0" cellspacing="0" width="100%">
	<tbody><tr>
		<td style="padding-left: 22px;"><a href="http://online.wsj.com/home"><img src="us_files/wsj_header_408_62.gif" alt="The Wall Street Journal Home Page" border="0" height="62" width="408"></a></td>
		<!-- including header js: -->
		<td style="padding-left: 16px;" valign="bottom"><script type="text/javascript">if (loggedIn) { document.write(searchBoxJs); } else { document.write(publicPromoJs); }</script><div style="padding: 0px; text-align: center;">		<span id="Header_Promo_public_us_302x52"><script type="text/javascript">				var tempHTML = '';		var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=302x52;ord=1234307803078030780;';		if ( isSafari ) {		  tempHTML += '<iframe id="publicUSpromo" src="'+adURL+'" width="302" height="52" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:302">';		} else {		  tempHTML += '<iframe id="publicUSpromo" src="/static_html_files/blank.htm" width="302" height="52" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:302px;">';		  ListOfIframes.publicUSpromo= adURL;		}		tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=302x52;ord=1234307803078030780;" target="_new">';		tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=302x52;ord=1234307803078030780;" border="0" width="302" height="52" vspace="0" alt="" /></a><br /></iframe>';		document.write(tempHTML);				</script><iframe id="publicUSpromo" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 302px;" frameborder="0" height="52" scrolling="no" width="302">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us;!category=;msrc=null;null;sz=302x52;ord=1234307803078030780;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us;!category=;msrc=null;null;sz=302x52;ord=1234307803078030780;"
border="0" width="302" height="52" vspace="0" alt=""
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>	</span></div></td>
		<!-- including header js: -->
		<td style="padding-left: 13px;"><script type="text/javascript">if (loggedIn) { document.write(userInfoBoxJs); } else { document.write(loginBoxJs); }</script><div>	<div style="border-bottom: 1px solid rgb(155, 173, 206); background-color: rgb(239, 247, 247); background-image: url(/img/hp_login_top_bk.gif); background-repeat: repeat-x; background-position: center top;">		<div style="background-image: url(/img/hp_login_rt_bl_bk.gif); background-repeat: repeat-y; background-position: right center;">			<div style="background-image: url(/img/hp_login_le_bl_bk.gif); background-repeat: repeat-y;">				<div style="background-image: url(/img/hp_login_tl_bk.gif); background-repeat: no-repeat; background-position: left top;">					<div style="background-image: url(/img/hp_login_tr_bk.gif); background-repeat: no-repeat; background-position: right top;">						<form method="post" action="https://users1.wsj.com/lmda/do/submitLogin" name="login_form" id="login_form" style="margin: 0px;" onsubmit="suppress_popup=true;return true;">							<input name="url" value="http://online.wsj.com/home" type="hidden">							<table style="padding: 2px 0px 0px;" align="center" border="0" cellpadding="0" cellspacing="0">								<tbody><tr>									<td style="letter-spacing: -1px; font-family: Verdana,Arial,Helvetica,sans-serif; font-size: 9px;">User Name:&nbsp;</td>									<td><input name="user" size="9" maxlength="30" style="width: 54px; font-size: 9px;" type="text"></td>									<td style="letter-spacing: -1px; font-family: Verdana,Arial,Helvetica,sans-serif; font-size: 9px;">Password:&nbsp;</td>									<td><input name="password" size="9" style="width: 50px; font-size: 9px;" maxlength="30" type="password"></td>								</tr>							</tbody></table>							<table style="padding: 2px 0px 0px;" align="center" border="0" cellpadding="0" cellspacing="0" width="100%">								<tbody><tr>									<td style="padding-left: 12px;" width="14"><input id="savelogin" name="savelogin" value="true" checked="checked" style="margin: 0px; padding: 0px; width: 14px; height: 13px;" type="checkbox"></td>									<td class="pb11" colspan="3" style="color: rgb(157, 9, 3);" valign="middle"><label for="savelogin" style="cursor: pointer;">Remember Me</label></td>									<td class="pb11" style="padding-right: 7px;" align="right"><a href="http://online.wsj.com/login" onclick="document.login_form.submit();return false" style="color: rgb(157, 9, 3);">Log In&nbsp;<input name="img" src="us_files/loginArrow.gif" alt="" style="border: 0pt none ; width: 5px; height: 9px;" type="image"></a></td>								</tr></tbody></table></form>					</div>				</div>			</div>		</div>	</div>	<div style="background-image: url(/img/hp_login_bottom_bk.gif); background-repeat: repeat-x; background-position: center bottom;">		<div style="background-image: url(/img/hp_login_rt_wt_bk.gif); background-repeat: repeat-y; background-position: right center;">			<div style="background-image: url(/img/hp_login_le_wt_bk.gif); background-repeat: repeat-y;">				<div style="background-image: url(/img/hp_login_bl_bk.gif); background-repeat: no-repeat; background-position: left bottom;">					<div style="padding: 2px 0px 3px; background-image: url(/img/hp_login_br_bk.gif); background-repeat: no-repeat; background-position: right bottom; font-family: Verdana,Arial,Helvetica,sans-serif; font-size: 9px; text-align: center; letter-spacing: -1px;"><a href="https://users1.wsj.com/lmda/do/forgotPass">Forgot your username or password?</a> <span style="color: rgb(102, 102, 102);">|</span> 					<script type="text/javascript">										var sourceCode = "FVS05_0107";					if(pID=='0_0013'){						sourceCode="SUBSCRIBE_Home_Europe_Login"					}else if(pID=='0_0014'){						sourceCode="SUBSCRIBE_Home_Asia_Login"					}else if(pID=='2_0433'){						sourceCode="SUBSCRIBE_Todays_Print_US_Login"					}else if(pID=='2_0434'){						sourceCode="SUBSCRIBE_Todays_Print_Europe_Login"					}else if(pID=='2_0435'){						sourceCode="SUBSCRIBE_Todays_Print_Asia_Login"					}else if(pID=='0_0110'){						sourceCode="SUBSCRIBE_My_Online_Journal_US_Login"					}else if(pID=='0_0112'){						sourceCode="SUBSCRIBE_My_Online_Journal_Europe_Login"					}else if(pID=='0_0114'){						sourceCode="SUBSCRIBE_My_Online_Journal_Asia_Login"					}else if(pID=='0_0800'){						sourceCode="SUBSCRIBE_Public_RT_Login"					}					document.write('<a href="/reg/promo/'+sourceCode+'">Subscribe</a>');										</script><a href="http://online.wsj.com/reg/promo/FVS05_0107">Subscribe</a>					</div>				</div>			</div>		</div>	</div></div><script type="text/javascript">document.login_form.url.value='http://'+gcDomain+(pID.indexOf('2_3')==-1?'/home':'/mdc/page/marketsdata.html?mod=mdc_hdr_login');document.login_form.action=gcLFU;</script></td>
	</tr>
</tbody></table>






<table class="p11" style="padding: 3px 0px 5px; color: rgb(255, 255, 255);" bgcolor="#336699" border="0" cellpadding="0" cellspacing="0" width="100%">
  <tbody><tr>
	<td style="padding-left: 25px;" width="162"><span class="nobr"><a href="http://online.wsj.com/public/page/0,,other_wsj_sites,00.html" style="color: rgb(255, 255, 255);" onmouseover="closeMenuHN(openHNtabIndex);OverBar=true;OpenMenu('OtherJrnlSite')" onmouseout="OverBar=false">Free Dow Jones Sites</a> <img src="us_files/b.gif" name="OtherJrnlSiteIMG" alt="" border="0" height="11" width="1"></span></td>
	<td width="433"><span class="nobr">As&nbsp;of&nbsp;<span id="pageTimeStamp">2:36&nbsp;a.m.&nbsp;EDT&nbsp;Tuesday,&nbsp;July&nbsp;24,&nbsp;2007</span></span></td>
	<td width="202"><span class="nobr"><a href="http://online.wsj.com/login" onclick="if(loggedIn){;OpenWin('/setup/select_edition_popup','Warning',310,280,'st',1,300,100);return false;}else{;return true;}" style="color: rgb(255, 255, 255);">Set My Home Page</a></span></td>
	<td style="padding-right: 7px;" align="right"> 
	<script language="JavaScript" type="text/javascript">
	<!--
		var printUrl = ((pID=='0_0013'||pID=='0_0003'||pID=='2_0003')?'http://www.europesubs.wsj.com/?mod=header_'+pID:((pID=='0_0014'||pID=='0_0004'||pID=='2_0004')?'https://www.awsj.com.hk/awsj2/?source=PWSHE4ECHR1N&mod=header_'+pID:'http://services.wsj.com?mod=header_'+pID));
		var onlineUrl = nSP+((loggedIn)?'':'/public')+'/page/0,,0_0809,00.html?page=0_0809&mod=header_'+pID;

		document.write("<a style='color:#fff;white-space:nowrap;' href='"+onlineUrl+"'>Customer&nbsp;Service</a>");  
	//-->
	</script><a style="color: rgb(255, 255, 255); white-space: nowrap;" href="http://online.wsj.com/public/page/0,,0_0809,00.html?page=0_0809&amp;mod=header_0_0002_public">Customer&nbsp;Service</a>
	</td>
  </tr>
</tbody></table>
<script type="text/javascript" language="javascript" src="us_files/HorizontalNavigationData.js" charset="ISO-8859-1"></script>
<script type="text/javascript" language="javascript" src="us_files/HorizontalNavigation.js" charset="ISO-8859-1"></script><script type="text/javascript" language="javascript" src="us_files/HorizontalNavigationFunctions.js" charset="ISO-8859-1"></script><table bgcolor="#efefce" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td style="background-image: url(/img/hnav_middle_seperator_bg.gif); background-position: -5px 0px; background-repeat: no-repeat;" height="6" width="6"><img src="us_files/b.gif" alt="" height="6" width="1"></td><td style="border-top: 1px solid rgb(142, 151, 185);" rowspan="2"><div id="hntab0" style="padding: 3px 0px 2px; font-family: Arial,Helvetica,sans-serif; font-size: 12px; font-weight: bold; text-align: center; width: 186px; color: rgb(153, 0, 0); cursor: pointer;" onmouseover="status='http://online.wsj.com/public/us?mod=topnav_0_0002_public';OverBar=false;HideNav();openMenuHN(0);overHNTab=true" onmouseout="status='';closeMenuHN(0);overHNTab=false;this.style.color='#990000';" onclick="window.location='http://online.wsj.com/public/us?mod=topnav_0_0002_public'">NEWS</div></td><td style="background-image: url(/img/hnav_middle_seperator_bg.gif); background-position: 0px; background-repeat: no-repeat;" height="6" width="11"><img src="us_files/b.gif" alt="" height="6" width="1"></td><td style="border-top: 1px solid rgb(142, 151, 185);" rowspan="2"><div id="hntab1" style="padding: 3px 0px 2px; font-family: Arial,Helvetica,sans-serif; font-size: 12px; font-weight: bold; text-align: center; width: 187px; color: rgb(0, 0, 0); cursor: pointer;" onmouseover="status='http://online.wsj.com/public/page/us_in_todays_paper.html?mod=topnav_0_0002_public';OverBar=false;HideNav();openMenuHN(1);overHNTab=true" onmouseout="status='';closeMenuHN(1);overHNTab=false" onclick="window.location='http://online.wsj.com/public/page/us_in_todays_paper.html?mod=topnav_0_0002_public'">TODAY'S NEWSPAPER</div></td><td style="background-image: url(/img/hnav_middle_seperator_bg.gif); background-position: 0px; background-repeat: no-repeat;" height="6" width="11"><img src="us_files/b.gif" alt="" height="6" width="1"></td><td style="border-top: 1px solid rgb(142, 151, 185);" rowspan="2"><div id="hntab2" style="padding: 3px 0px 2px; font-family: Arial,Helvetica,sans-serif; font-size: 12px; font-weight: bold; text-align: center; width: 187px; color: rgb(0, 0, 0); cursor: pointer;" onmouseover="status='http://online.wsj.com/myonlinejournal/public/us?mod=topnav_0_0002_public';OverBar=false;HideNav();openMenuHN(2);overHNTab=true" onmouseout="status='';closeMenuHN(2);overHNTab=false" onclick="window.location='http://online.wsj.com/myonlinejournal/public/us?mod=topnav_0_0002_public'">MY ONLINE JOURNAL</div></td><td style="background-image: url(/img/hnav_middle_seperator_bg.gif); background-position: 0px; background-repeat: no-repeat;" height="6" width="11"><img src="us_files/b.gif" alt="" height="6" width="1"></td><td style="border-top: 1px solid rgb(142, 151, 185);" rowspan="2"><div id="hntab3" style="padding: 3px 0px 2px; font-family: Arial,Helvetica,sans-serif; font-size: 12px; font-weight: bold; text-align: center; width: 187px; color: rgb(0, 0, 0); cursor: pointer;" onmouseover="status='http://online.wsj.com/page/1_0100.html?mod=topnav_0_0002_public';OverBar=false;HideNav();openMenuHN(3);overHNTab=true" onmouseout="status='';closeMenuHN(3);overHNTab=false" onclick="window.location='http://online.wsj.com/page/1_0100.html?mod=topnav_0_0002_public'">MULTIMEDIA &amp; ONLINE EXTRAS</div></td><td style="background-image: url(/img/hnav_middle_seperator_bg.gif); background-position: 0px; background-repeat: no-repeat;" height="6" width="11"><img src="us_files/b.gif" alt="" height="6" width="1"></td><td style="border-top: 1px solid rgb(142, 151, 185);" rowspan="2"><div id="hntab4" style="padding: 3px 0px 2px; font-family: Arial,Helvetica,sans-serif; font-size: 12px; font-weight: bold; text-align: center; width: 187px; color: rgb(0, 0, 0); cursor: pointer;" onmouseover="status='http://online.wsj.com/marketsdata?mod=topnav_0_0002_public';OverBar=false;HideNav();openMenuHN(4);overHNTab=true" onmouseout="status='';closeMenuHN(4);overHNTab=false" onclick="window.location='http://online.wsj.com/marketsdata?mod=topnav_0_0002_public'">MARKETS DATA &amp; TOOLS</div></td><td style="background-image: url(/img/hnav_middle_seperator_bg.gif); background-position: 0px; background-repeat: no-repeat;" height="6" width="6"><img src="us_files/b.gif" alt="" height="6" width="1"></td></tr><tr><td style="background-image: url(/img/hnav_middle_seperator_line_bg.gif); background-position: -5px 0px; background-repeat: repeat-y;" width="6"><img src="us_files/b.gif" alt="" height="15" width="1"></td><td style="background-image: url(/img/hnav_middle_seperator_line_bg.gif); background-position: 0px; background-repeat: repeat-y;" width="11"><img src="us_files/b.gif" alt="" height="15" width="1"></td><td style="background-image: url(/img/hnav_middle_seperator_line_bg.gif); background-position: 0px; background-repeat: repeat-y;" width="11"><img src="us_files/b.gif" alt="" height="15" width="1"></td><td style="background-image: url(/img/hnav_middle_seperator_line_bg.gif); background-position: 0px; background-repeat: repeat-y;" width="11"><img src="us_files/b.gif" alt="" height="15" width="1"></td><td style="background-image: url(/img/hnav_middle_seperator_line_bg.gif); background-position: 0px; background-repeat: repeat-y;" width="11"><img src="us_files/b.gif" alt="" height="15" width="1"></td><td style="background-image: url(/img/hnav_middle_seperator_line_bg.gif); background-position: 0px; background-repeat: repeat-y;" width="6"><img src="us_files/b.gif" alt="" height="15" width="1"></td></tr><tr><td colspan="99" bgcolor="#ffffff" height="1"></td></tr><tr><td colspan="99" bgcolor="#666666" height="1"></td></tr><tr><td colspan="99" bgcolor="#999999" height="1"></td></tr><tr><td colspan="99" bgcolor="#cccccc" height="1"></td></tr><tr><td colspan="99" bgcolor="#efefef" height="1"></td></tr></tbody></table><div id="hnpopup" style="display: none; position: absolute; width: 1px; height: 1px; z-index: 1; left: 300px; top: 300px; visibility: hidden;" onmouseover="overHNOpen=true" onmouseout="overHNOpen=false"></div>

	</div>
</div>
<!-- End header -->



<!-- Begin content -->
<div class="main" style="border: 0px none ; margin: 18px 0px 0px; padding: 0px; width: 990px;">


<!-- Begin nav -->
  <div style="margin: 0px; float: left; width: 131px;">
	<div style="margin: 0px; clear: left; width: 131px;">
     





	<script type="text/javascript">
	<!-- OM = "";
	// --></script>
	<div style="border: 0px none ; margin: 0px; padding: 0px; width: 131px; background-color: rgb(255, 255, 255);">
  <div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(255, 0, 0);" class="b11"><script type="text/javascript"><!--
  document.write('<a href="' + nSP + '/home" onclick="document.location.href=nSP+\'/home\';return false;" onmouseover="MyImg=new Image;MyImg.src=document.HOMEIMG.src;document.HOMEIMG.src=\'/img/Home_over.gif\'" onmouseout="document.HOMEIMG.src=MyImg.src"><img name="HOMEIMG" src="/img/Home_normal.gif" border="0" width="131" height="18" alt="" /></a>'); // --></script><a href="http://online.wsj.com/home" onclick="document.location.href=nSP+'/home';return false;" onmouseover="MyImg=new Image;MyImg.src=document.HOMEIMG.src;document.HOMEIMG.src='/img/Home_over.gif'" onmouseout="document.HOMEIMG.src=MyImg.src"><img name="HOMEIMG" src="us_files/Home_normal.gif" alt="" border="0" height="18" width="131"></a></div>

<div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(255, 0, 0);" class="b11"><img src="us_files/News_selected.gif" alt="" border="0"></div>

<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(255, 153, 51);" class="p12">News Main</div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/news/us_business?mod=2_0002" onclick="document.location.href=nSP+'/news/us_business?mod=2_0002';return false;">U.S. Business</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/redirect/europe.html?mod=0_0003" onclick="document.location.href=nSP+'/redirect/europe.html?mod=0_0003';return false;">Europe</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/redirect/asia.html?mod=0_0004" onclick="document.location.href=nSP+'/redirect/asia.html?mod=0_0004';return false;">Asia</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/news/world_news?mod=2_0006" onclick="document.location.href=nSP+'/news/world_news?mod=2_0006';return false;">World News</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/news/economy?mod=2_0007" onclick="document.location.href=nSP+'/news/economy?mod=2_0007';return false;">Economy</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/page/politics_policy.html?mod=2_0008" onclick="document.location.href=nSP+'/page/politics_policy.html?mod=2_0008';return false;">Politics &amp; Policy</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/news/earnings?mod=2_0009" onclick="document.location.href=nSP+'/news/earnings?mod=2_0009';return false;">Earnings</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/health?mod=0_0005" onclick="document.location.href=nSP+'/health?mod=0_0005';return false;">Health</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/law?mod=2_0079" onclick="document.location.href=nSP+'/law?mod=2_0079';return false;">Law</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/media?mod=0_0006" onclick="document.location.href=nSP+'/media?mod=0_0006';return false;">Media &amp; Marketing</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/news/industry?mod=2_0010" onclick="document.location.href=nSP+'/news/industry?mod=2_0010';return false;">News by Industry</a></div>

						<div style="border-bottom: 1px solid rgb(255, 255, 255); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(239, 239, 239); color: rgb(0, 0, 0);" class="p12"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/page/columnists.html?mod=2_0140" onclick="document.location.href=nSP+'/page/columnists.html?mod=2_0140';return false;">Columnists</a></div>

<div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(2, 83, 183);" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/technology.html?mod=1_0013" onclick="document.location.href=nSP+\'/redirect/technology.html?mod=1_0013\';return false;" onmouseover="OverBar=true;OpenMenu(\'Technology\')" onmouseout="OverBar=false;"><img src="/img/Technology_normal.gif" name="TechnologyIMG" border="0" alt=""/></a>'); // --></script><a href="http://online.wsj.com/redirect/technology.html?mod=1_0013" onclick="document.location.href=nSP+'/redirect/technology.html?mod=1_0013';return false;" onmouseover="OverBar=true;OpenMenu('Technology')" onmouseout="OverBar=false;"><img src="us_files/Technology_normal.gif" name="TechnologyIMG" alt="" border="0"></a></div>

<noscript><a href="/redirect/technology.html">Technology Main</a></noscript>

<noscript><a href="/page/tech_stocks.html">Tech Stocks</a></noscript>

<noscript><a href="/page/gadgets.html">Gadgets</a></noscript>

<noscript><a href="/technology/telecommunications">Telecommunications</a></noscript>

<noscript><a href="/technology/e_commerce">E-Commerce/Media</a></noscript>

<noscript><a href="/page/asia_tech.html">Asia Technology</a></noscript>

<noscript><a href="/technology/europe">Europe Technology</a></noscript>

<noscript><a href="/technology/columns">Technology Columns</a></noscript>

<div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(2, 83, 183);" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/markets.html?mod=1_0021" onclick="document.location.href=nSP+\'/redirect/markets.html?mod=1_0021\';return false;" onmouseover="OverBar=true;OpenMenu(\'Markets\')" onmouseout="OverBar=false;"><img src="/img/Markets_normal.gif" name="MarketsIMG" border="0" alt=""/></a>'); // --></script><a href="http://online.wsj.com/redirect/markets.html?mod=1_0021" onclick="document.location.href=nSP+'/redirect/markets.html?mod=1_0021';return false;" onmouseover="OverBar=true;OpenMenu('Markets')" onmouseout="OverBar=false;"><img src="us_files/Markets_normal.gif" name="MarketsIMG" alt="" border="0"></a></div>

<noscript><a href="/redirect/markets.html">Markets Main</a></noscript>

<noscript><a href="/page/todays_market.html">Today&#39;s Markets</a></noscript>

<noscript><a href="/marketsdata">Markets Data Center</a></noscript>

<noscript><a href="/page/market_movers.html">Market Movers</a></noscript>

<noscript><a href="/articles/heard_on_the_street">Heard on the Street</a></noscript>

<noscript><a href="/page/commodities.html">Commodities</a></noscript>

<noscript><a href="/page/credit_markets.html">Credit Markets</a></noscript>

<noscript><a href="/page/foreign_exchange.html">Foreign Exchange</a></noscript>

<noscript><a href="/public/page/deals.html">Deals &amp; Deal Makers</a></noscript>

<noscript><a href="/page/hedge_funds.html">Hedge Funds</a></noscript>

<noscript><a href="/page/tech_stocks.html">Tech Stocks</a></noscript>

<noscript><a href="/page/asia_markets.html">Asia Markets</a></noscript>

<noscript><a href="/page/europe_markets.html">Europe Markets</a></noscript>

<noscript><a href="/page/americas_markets.html">Americas Markets</a></noscript>

<div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(2, 83, 183);" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/personaljournal?mod=1_0028" onclick="document.location.href=nSP+\'/personaljournal?mod=1_0028\';return false;" onmouseover="OverBar=true;OpenMenu(\'PersonalJournal\')" onmouseout="OverBar=false;"><img src="/img/PersonalJournal_normal.gif" name="PersonalJournalIMG" border="0" alt=""/></a>'); // --></script><a href="http://online.wsj.com/personaljournal?mod=1_0028" onclick="document.location.href=nSP+'/personaljournal?mod=1_0028';return false;" onmouseover="OverBar=true;OpenMenu('PersonalJournal')" onmouseout="OverBar=false;"><img src="us_files/PersonalJournal_normal.gif" name="PersonalJournalIMG" alt="" border="0"></a></div>

<noscript><a href="/personaljournal">PJ Main</a></noscript>

<noscript><a href="/redirect/personalfinance.html">Personal Finance</a></noscript>

<noscript><a href="/health">Health</a></noscript>

<noscript><a href="/public/page/autos_main.html">Autos Main</a></noscript>

<noscript><a href="/personal_journal/homes">Homes</a></noscript>

<noscript><a href="/personal_journal/travel">Travel</a></noscript>

<noscript><a href="/personal_journal/careers">Careers</a></noscript>

<noscript><a href="/page/gadgets.html">Gadgets</a></noscript>

<noscript><a href="/personal_journal/tools">Tools</a></noscript>

<noscript><a href="/personal_journal/columns">PJ Columns</a></noscript>

<div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(2, 83, 183);" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/opinion.html?mod=1_0045" onclick="document.location.href=nSP+\'/redirect/opinion.html?mod=1_0045\';return false;" onmouseover="OverBar=true;OpenMenu(\'Opinion\')" onmouseout="OverBar=false;"><img src="/img/Opinion_normal.gif" name="OpinionIMG" border="0" alt=""/></a>'); // --></script><a href="http://online.wsj.com/redirect/opinion.html?mod=1_0045" onclick="document.location.href=nSP+'/redirect/opinion.html?mod=1_0045';return false;" onmouseover="OverBar=true;OpenMenu('Opinion')" onmouseout="OverBar=false;"><img src="us_files/Opinion_normal.gif" name="OpinionIMG" alt="" border="0"></a></div>

<noscript><a href="/redirect/opinion.html">Opinion Main</a></noscript>

<noscript><a href="/page/letters.html">Letters</a></noscript>

<noscript><a href="/opinion/discussions">Forums</a></noscript>

<noscript><a href="/page/opinion_columns.html">Opinion Columns</a></noscript>

<div style="border-bottom: 1px solid rgb(239, 239, 239); margin: 0px; padding: 0px; background-color: rgb(51, 102, 153); color: rgb(2, 83, 183);" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/leisure.html?mod=1_0051" onclick="document.location.href=nSP+\'/redirect/leisure.html?mod=1_0051\';return false;" onmouseover="OverBar=true;OpenMenu(\'Leisure\')" onmouseout="OverBar=false;"><img src="/img/Leisure_normal.gif" name="LeisureIMG" border="0" alt=""/></a>'); // --></script><a href="http://online.wsj.com/redirect/leisure.html?mod=1_0051" onclick="document.location.href=nSP+'/redirect/leisure.html?mod=1_0051';return false;" onmouseover="OverBar=true;OpenMenu('Leisure')" onmouseout="OverBar=false;"><img src="us_files/Leisure_normal.gif" name="LeisureIMG" alt="" border="0"></a></div>

<noscript><a href="/redirect/leisure.html">Main Page</a></noscript>

<noscript><a href="/at_leisure/weekend_journal">Weekend Journal</a></noscript>

<noscript><a href="/page/pursuits.html">Pursuits</a></noscript>

<noscript><a href="/page/2_1168.html">Arts &amp; Entertainment</a></noscript>

<noscript><a href="/page/books.html">Books</a></noscript>

<noscript><a href="/personal_journal/travel">Travel</a></noscript>

<noscript><a href="/public/page/autos_main.html">Autos Main</a></noscript>

<noscript><a href="/at_leisure/sports">Sports</a></noscript>

	</div>




	<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--

function addUrlPrefix(theUrl) {
  if (theUrl.substr(0,10) == 'javascript')
	return theUrl
  else
	return nSP + theUrl
}

var editionType = "us"
var publicPath = (loggedIn)?"":"/public"
if (pID=="0_0002") {
  editionType = "us"
  publicPath = ""
} else if ((pID=="0_0013") || (pID == "0_0003_public")) {
  editionType = "europe"
  publicPath = "/public"
} else if (pID=="0_0003") {
  editionType = "europe"
  publicPath = ""
} else if ((pID=="0_0014") || (pID == "0_0004_public")) {
  editionType = "asia"
  publicPath = "/public"
} else if (pID=="0_0004") {
  editionType = "asia"
  publicPath = ""
}
var mojURL = "/myonlinejournal"+publicPath+"/"+editionType

var newSection = new Array("TodaysNewspaper","MyOnlineJournal","MultimediaOnlineExtras","MarketDataTools")
for(var s=0;s<newSection.length;s++){
  if(typeof SectionArray != 'undefined'&&SectionArray.length>0){
    SectionArray[SectionArray.length] = newSection[s]
  }
  eval('var '+newSection[s]+'_normal_img=new Image(131,20)')
  eval(newSection[s]+'_normal_img.src="/img/'+newSection[s]+'_normal.gif"')
  eval('var '+newSection[s]+'_over_img=new Image(131,20)')
  eval(newSection[s]+'_over_img.src="/img/'+newSection[s]+'_over.gif"')
}

MyOnlineJournalArray=new Array("My News|"+mojURL,"My Email|/email","My Desktop Alerts|/page/alerts.html","My Account|/my_account")

MarketDataToolsArray=new Array("Markets Data Center|/marketsdata","Portfolio|"+gcPH,"Company Research|/redirect/companyresearch.html","ETF Research|/redirect/etfresearch.html","Mutual Fund Research|/redirect/mutualfundresearch.html","ETF Screener|/public/quotes/etf_screener.html", "Mutual Fund Screener|/public/quotes/mutualfund_screener.html",
"Price & Volume Alerts|/pznsetup/sub/pvemail/setup.html","Worksheets/Calculators|/page/2_0036.html?mod=2_0036")

MultimediaOnlineExtrasArray=new Array("Video Center|javascript:OpenWin('/public/page/8_0004.html?mod=8_0004','videoplayer',993,540,'off',true,0,0,true);void('')","Blogs|/redirect/blogslanding.html","Interactive Features|/public/page/interactive_features.html?mod=2_1077","Podcasts|"+((loggedIn)?"":"/public")+"/page/podcast.html?mod=8_0018","RSS News Feeds|"+((loggedIn)?"":"/public")+"/page/0_0813.html?mod=0_0813","WSJ NewsReader|/newsreader","Columnists|/page/columnists.html?mod=2_0140","Forums|http://forums.wsj.com","Email Alerts/Newsletters|/email","Mobile|http://mobile.wsj.com","Most Popular|/page/most_popular.html","Online Today|/redirect/onlineexclusives.html","WSJ Labs|"+((loggedIn)?"":"/public")+"/page/wsj_labs.html?mod=0_0834")

TodaysNewspaperArray=new Array("U.S.|"+((loggedIn)?"/page/us_in_todays_paper.html?mod=2_0133":"/public/page/us_in_todays_paper.html?mod=2_0433"),"Europe|"+((loggedIn)?"/page/europe_in_todays_paper.html?mod=2_0134":"/public/page/europe_in_todays_paper.html?mod=2_0434"),"Asia|"+((loggedIn)?"/page/asia_in_todays_paper.html?mod=2_0135":"/public/page/asia_in_todays_paper.html?mod=2_0435"),"Past Editions|"+((pID=='2_0234')?'2_0234':((pID=='2_0235')?'2_0235':'2_0233')),"Index to Businesses|/page/index_to_business.html?mod=2_0156","Index to People|/page/index_to_people.html?mod=2_0155","Journal Reports|"+((loggedIn)?"/page/journal_reports.html":"/public/page/journal_reports.html")+"?mod=2_0102","Columnists|2_0140","Letters|2_0048","Corrections|/public/corrections?mod=2_0102")

FreeFeaturesArray=new Array("Today's Free Features|/public/page/2_0323.html?mod=2_0323","Video Center|javascript:OpenWin('/public/page/8_0004.html?mod=8_0004','videoplayer',993,540,'off',true,0,0,true);void('')",
"Markets Data Center|/marketsdata","Blogs|/redirect/blogslanding.html","Forums|http://forums.wsj.com","Email Alerts/Newsletters|/email", "RSS News Feeds|/public/page/0_0813.html","Podcasts|/public/page/8_0018.html","Interactive Features|/public/page/2_1077.html")

var altURLs=new Array()
altURLs[altURLs.length]=new Array("/myonlinejournal/us|/myonlinejournal/public/us|/myonlinejournal/asia|/myonlinejournal/public/asia|/myonlinejournal/europe|/myonlinejournal/public/europe",mojURL)
altURLs[altURLs.length]=new Array("/pznsetup/sub/email/setup.html","/email")
altURLs[altURLs.length]=new Array("/search/aggregate.html|/search/date.html|/search/advanced.html|/search/full.html|/search/relevance.html|/search|/public/page/search.html",((loggedIn)?"/search":"/public/page/search.html"))
var disablePages=new Array("2_0036","2_0048")
var toploc = "";
try {
  toploc = new String(window.top.location);
} catch(e) {
  //window.top.location is in another domain
  toploc = new String(window.location);
}
function isOpen(thisURL){
  var tempLoc = ("".concat(toploc).substring("".concat(toploc).indexOf("/",8)))
  if(tempLoc.indexOf("?")>-1){
    tempLoc=tempLoc.substring(0,tempLoc.indexOf("?"))
  }
  for(a=0;a<altURLs.length;a++){
    if(thisURL==altURLs[a][1]){
      if(("|"+altURLs[a][0]+"|").indexOf("|"+tempLoc+"|")>-1){
        return true
      }
    }
  }
  return false
}
document.write('<div style="margin:1px 0px 1px 0px;border-top:1px solid #8E99B6;border-left:1px solid #8E99B6;border-right:1px solid #8E99B6;">')
var encounteredOpenSection = -1;
for(var s=0;s<newSection.length;s++){
  var isSectionOpen = false;
  var selectedPage = 0;
  var tempSecArray = eval(newSection[s]+"Array")
  var tempHTML = "";
  var isMainPage = false
  for(var p=0;p<tempSecArray.length;p++){
    tempHTML+='<div style="padding:1px 0px 2px 7px;background-color:#F8F9EF;border-bottom:1px solid #8E99B6;margin:0px;color:';
    var thisURL = tempSecArray[p].split("|")[1]
    if(thisURL){
      var tempLoc = ("".concat(toploc).substring("".concat(toploc).indexOf("/",8)))
      if(tempLoc.indexOf("?")>-1){
        tempLoc=tempLoc.substring(0,tempLoc.indexOf("?"))
      }
      if(("|"+disablePages.join("|")+"|").indexOf("|"+pID+"|")==-1&&encounteredOpenSection==-1&&(isOpen(thisURL)||thisURL==pID||tempLoc==thisURL||thisURL.indexOf(tempLoc)>-1||thisURL.indexOf("/"+pID+".")>-1)){
        thisURL=(thisURL.indexOf(".")==-1&&thisURL.indexOf("\/")==-1)?(((loggedIn)?"/page/":"/public/page/")+thisURL+".html"):thisURL
        isSectionOpen = true
        encounteredOpenSection = s
        tempHTML+='#9B0805;" class="p11">'+tempSecArray[p].split("|")[0]+'</div>'
        if(p==0)
          isMainPage=true
      } else {
        thisURL=(thisURL.indexOf(".")==-1&&thisURL.indexOf("\/")==-1)?(((loggedIn)?"/page/":"/public/page/")+thisURL+".html"):thisURL
        tempHTML+='#000;" class="p11"><a style="color: #000;" class="unvisited" href="'+addUrlPrefix(thisURL)+'">'+tempSecArray[p].split("|")[0]+'</a></div>'
      }
    }
  }
  if(tempSecArray.length>1){
    var thisURL = tempSecArray[0].split("|")[1]
    thisURL=(thisURL.indexOf(".")==-1&&thisURL.indexOf("\/")==-1)?(((loggedIn)?"/page/":"/public/page/")+thisURL+".html"):thisURL
    if(isSectionOpen&&encounteredOpenSection==s){
      var temp='<div>';
      if(!isMainPage)
        temp+='<a href="'+addUrlPrefix(thisURL)+'">';
      temp+='<img src="/img/'+newSection[s]+'_over.gif" name="'+newSection[s]+'IMG" border="0" alt="" style="border-bottom:1px solid #8E99B6;"/>'
      if(!isMainPage)
        temp+= '</a>'
      tempHTML=temp+'</div>'+tempHTML
    } else {
      tempHTML='<div><a href="'+addUrlPrefix(thisURL)+'" onmouseover="OverBar=true;OpenMenuNew(\''+newSection[s]+'\',\'#8E99B6\',\'#8E99B6\',\'#F8F9EF\')" onmouseout="OverBar=false;"><img src="/img/'+newSection[s]+'_normal.gif" name="'+newSection[s]+'IMG" border="0" alt="" style="border-bottom:1px solid #8E99B6;"/></a></div>'
    }
  } else {
    tempHTML='<div><a href="'+addUrlPrefix(tempSecArray[0])+'" ><img '
    if(typeof SectionArray != 'undefined'&&SectionArray.length>0){
      tempHTML+='onmouseover="this.src='+newSection[s]+'_over_img.src" onmouseout="this.src='+newSection[s]+'_normal_img.src" '
    }
    tempHTML+='src="/img/'+newSection[s]+'_normal.gif" name="'+newSection[s]+'IMG" border="0" alt="" style="border-bottom:1px solid #8E99B6;"/></a></div>'
  }
  document.write(tempHTML)
}
tempHTML='</div>'
tempHTML+='<div style="border-bottom:1px solid #FFF;"><a href="http://online.wsj.com/public/page/autos_main.html" target="_blank"><img src="/img/findacar_nav_btn.gif" width="131" height="20" alt="" border="0" /></a></div>'
tempHTML+='<div style="border-bottom:1px solid #FFF;"><a href="http://www.careerjournal.com/" target="_blank"><img src="/img/findajob_nav_btn.gif" width="131" height="20" alt="" border="0" /></a></div>'
tempHTML+='<div style="border-bottom:1px solid #FFF;"><a href="http://www.realestatejournal.com/marketplace/homesforsale/" target="_blank"><img src="/img/findahome_nav_btn.gif" width="131" height="20" alt="" border="0" /></a></div>'
document.write(tempHTML)
//-->
</script><div style="border-top: 1px solid rgb(142, 153, 182); border-left: 1px solid rgb(142, 153, 182); border-right: 1px solid rgb(142, 153, 182); margin: 1px 0px;"><div><a href="http://online.wsj.com/public/page/us_in_todays_paper.html?mod=2_0433" onmouseover="OverBar=true;OpenMenuNew('TodaysNewspaper','#8E99B6','#8E99B6','#F8F9EF')" onmouseout="OverBar=false;"><img src="us_files/TodaysNewspaper_normal.gif" name="TodaysNewspaperIMG" alt="" style="border-bottom: 1px solid rgb(142, 153, 182);" border="0"></a></div><div><img src="us_files/MyOnlineJournal_over.gif" name="MyOnlineJournalIMG" alt="" style="border-bottom: 1px solid rgb(142, 153, 182);" border="0"></div><div style="border-bottom: 1px solid rgb(142, 153, 182); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(248, 249, 239); color: rgb(155, 8, 5);" class="p11">My News</div><div style="border-bottom: 1px solid rgb(142, 153, 182); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(248, 249, 239); color: rgb(0, 0, 0);" class="p11"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/email">My Email</a></div><div style="border-bottom: 1px solid rgb(142, 153, 182); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(248, 249, 239); color: rgb(0, 0, 0);" class="p11"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/page/alerts.html">My Desktop Alerts</a></div><div style="border-bottom: 1px solid rgb(142, 153, 182); margin: 0px; padding: 1px 0px 2px 7px; background-color: rgb(248, 249, 239); color: rgb(0, 0, 0);" class="p11"><a style="color: rgb(0, 0, 0);" class="unvisited" href="http://online.wsj.com/my_account">My Account</a></div><div><a href="javascript:OpenWin('/public/page/8_0004.html?mod=8_0004','videoplayer',993,540,'off',true,0,0,true);void('')" onmouseover="OverBar=true;OpenMenuNew('MultimediaOnlineExtras','#8E99B6','#8E99B6','#F8F9EF')" onmouseout="OverBar=false;"><img src="us_files/MultimediaOnlineExtras_normal.gif" name="MultimediaOnlineExtrasIMG" alt="" style="border-bottom: 1px solid rgb(142, 153, 182);" border="0"></a></div><div><a href="http://online.wsj.com/marketsdata" onmouseover="OverBar=true;OpenMenuNew('MarketDataTools','#8E99B6','#8E99B6','#F8F9EF')" onmouseout="OverBar=false;"><img src="us_files/MarketDataTools_normal.gif" name="MarketDataToolsIMG" alt="" style="border-bottom: 1px solid rgb(142, 153, 182);" border="0"></a></div></div><div style="border-bottom: 1px solid rgb(255, 255, 255);"><a href="http://online.wsj.com/public/page/autos_main.html" target="_blank"><img src="us_files/findacar_nav_btn.gif" alt="" border="0" height="20" width="131"></a></div><div style="border-bottom: 1px solid rgb(255, 255, 255);"><a href="http://www.careerjournal.com/" target="_blank"><img src="us_files/findajob_nav_btn.gif" alt="" border="0" height="20" width="131"></a></div><div style="border-bottom: 1px solid rgb(255, 255, 255);"><a href="http://www.realestatejournal.com/marketplace/homesforsale/" target="_blank"><img src="us_files/findahome_nav_btn.gif" alt="" border="0" height="20" width="131"></a></div>








<table class="" style="border-right: 1px solid rgb(51, 102, 153); height: 100%;" border="0" cellpadding="0" cellspacing="0">
  
  <tbody><tr>
  
    <td style="">



	<div class="pb12" style="padding: 5px 0px 5px 5px; background: rgb(94, 129, 171) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; color: rgb(226, 226, 188);">Site Highlights</div>
<div style="padding-left: 5px;">
	<span class="p11darkRed">
		NEW!<br> The Deal Journal Blog:<br>Updated throughout<br> the market day with exclusive commentary, news flashes, profiles, data and more, <b>The Deal Journal</b> provides you<br> with the up-to-the-minute take on deals and deal-makers.<br>
		<a class="pb11" href="http://blogs.wsj.com/deals/?mod=djm_shdealblog">Visit Now &gt;&gt;</a>
	</span>
</div>




<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr>
<td height="10"><img src="us_files/b.gif" alt="" border="0" height="10" width="1"></td>
</tr></tbody></table>



	<!-- adType: C -->
	
<div style="margin: 14px 0px;"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';sz=125x125;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="C1" src="'+adURL+'" width="125" height="125" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:125">';
} else {
  tempHTML += '<iframe id="C1" src="/static_html_files/blank.htm" width="125" height="125" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:125px;">';
  ListOfIframes.C1= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';sz=125x125;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';sz=125x125;ord=4844484448444844;" border="0" width="125" height="125" vspace="0" alt="Advertisement" /></'+'a><br /></'+'iframe>';
document.write(tempHTML);
// -->
</script><iframe id="C1" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 125px;" frameborder="0" height="125" scrolling="no" width="125">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us1;!category=;msrc=null;null;sz=125x125;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us1;!category=;msrc=null;null;sz=125x125;ord=4844484448444844;"
border="0" width="125" height="125" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</div>
	




	<!-- adType: C -->	
<div style="margin: 0px 0px 15px;"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=120x240;ord=9287928792879287;';
if ( isSafari ) {
  tempHTML += '<iframe id="adN120x240" src="'+adURL+'" width="120" height="240" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:120">';
} else {
  tempHTML += '<iframe id="adN120x240" src="/static_html_files/blank.htm" width="120" height="240" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:120px;">';
  ListOfIframes.adN120x240= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=120x240;ord=9287928792879287;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=120x240;ord=9287928792879287;" border="0" width="120" height="240" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="adN120x240" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 120px;" frameborder="0" height="240" scrolling="no" width="120">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us_subscriber;!category=;msrc=null;null;ptile=2;sz=120x240;ord=9287928792879287;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us_subscriber;!category=;msrc=null;null;ptile=2;sz=120x240;ord=9287928792879287;"
border="0" width="120" height="240" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</div>




	<div class="pb12" style="padding: 5px 0px 5px 5px; background: rgb(94, 129, 171) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; color: rgb(226, 226, 188);">Dow Jones Sites</div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://www.startupjournal.com/" target="_blank" class="unvisited">StartupJournal</a></div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://www.opinionjournal.com/" target="_blank" class="unvisited">OpinionJournal</a></div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://www.collegejournal.com/" target="_blank" class="unvisited">CollegeJournal</a></div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://www.careerjournal.com/" target="_blank" class="unvisited">CareerJournal</a></div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://www.realestatejournal.com/" target="_blank" class="unvisited">RealEstateJournal</a></div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://www.marketwatch.com/news/default.asp?siteid=wsj&amp;dist=frontpglink" target="_blank" class="unvisited">MarketWatch</a></div>
<div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px; overflow: hidden;">&nbsp;&#8226;&nbsp;<a href="http://online.barrons.com/" target="_blank" class="unvisited">Barron's Online</a></div> 




	<!-- adType:  -->
	




	<!-- adType:  -->
	




	<script type="text/javascript">
<!--
    document.write('<div class="pb12" style="background:#5E81AB;color:#E2E2BC;padding:5px 0px 5px 5px;">Customer Service</div>')
    document.write('<div class="p11darkRed" style="padding:4px 0px 4px 5px;border-bottom:1px solid #CDDFF5;">&nbsp;&#149;&nbsp;<a href="'+nSP+((loggedIn)?"":"/public")+'/page/0_0809.html?page=0_0809" class="unvisited">The Online Journal</a></div>')
    document.write('<div class="p11darkRed" style="padding:4px 0px 4px 5px;border-bottom:1px solid #CDDFF5;">&nbsp;&#149;&nbsp;<a href="https://services.wsj.com/Gryphon/index.dj" target="offering" onclick="OpenWin(this.href,\'offering\',\'\',\'\',\'on\',true);return false" class="unvisited">The Print Edition</a></div>')
    document.write('<div class="p11darkRed" style="padding:4px 0px 4px 5px;border-bottom:1px solid #CDDFF5;">&nbsp;&#149;&nbsp;<a href="'+nSP+((loggedIn)?"":"/public")+'/page/contact_us.html?page=Contact+Us" class="unvisited">Contact Us</a></div>')
    document.write('<div class="p11darkRed" style="padding:4px 0px 4px 5px;border-bottom:1px solid #CDDFF5;">&nbsp;&#149;&nbsp;<a href="'+nSP+'/public/page/sitemap.html?page=Site+Map" class="unvisited">Site Map</a></div>')
    document.write('<div class="p11darkRed" style="padding:4px 0px 4px 5px;border-bottom:1px solid #CDDFF5;">&nbsp;&#149;&nbsp;<a href="'+nSP+'/wsjhelp/center" class="unvisited" onclick="OpenWin(this.href,\'help\',610,510,\'tool,scroll,resize\',true,153,40);return false;" class="unvisited">Help</a></div>')
    if(!loggedIn)
	document.write('<div class="p11darkRed" style="padding:4px 0px 4px 5px;border-bottom:1px solid #CDDFF5;">&nbsp;&#149;&nbsp;<a href="'+nSP+'/reg/promo/HPLNV10_0107" class="unvisited">Subscribe</a></div>')
//-->
</script><div class="pb12" style="padding: 5px 0px 5px 5px; background: rgb(94, 129, 171) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; color: rgb(226, 226, 188);">Customer Service</div><div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px;">&nbsp;&#8226;&nbsp;<a href="http://online.wsj.com/public/page/0_0809.html?page=0_0809" class="unvisited">The Online Journal</a></div><div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px;">&nbsp;&#8226;&nbsp;<a href="https://services.wsj.com/Gryphon/index.dj" target="offering" onclick="OpenWin(this.href,'offering','','','on',true);return false" class="unvisited">The Print Edition</a></div><div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px;">&nbsp;&#8226;&nbsp;<a href="http://online.wsj.com/public/page/contact_us.html?page=Contact+Us" class="unvisited">Contact Us</a></div><div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px;">&nbsp;&#8226;&nbsp;<a href="http://online.wsj.com/public/page/sitemap.html?page=Site+Map" class="unvisited">Site Map</a></div><div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px;">&nbsp;&#8226;&nbsp;<a href="http://online.wsj.com/wsjhelp/center" onclick="OpenWin(this.href,'help',610,510,'tool,scroll,resize',true,153,40);return false;" class="unvisited">Help</a></div><div class="p11darkRed" style="border-bottom: 1px solid rgb(205, 223, 245); padding: 4px 0px 4px 5px;">&nbsp;&#8226;&nbsp;<a href="http://online.wsj.com/reg/promo/HPLNV10_0107" class="unvisited">Subscribe</a></div>





	<!-- adType:  -->
	




	<div class="adl">
	<div class="pb12" style="padding: 5px 0px 5px 5px; background: rgb(94, 129, 171) none repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; color: rgb(226, 226, 188);">Advertiser Links</div>
	<div style="border: 1px solid rgb(204, 204, 204); margin: 4px 0px 0px; padding: 1px; background-color: rgb(239, 239, 239);">
		<div style="width: 100%; text-align: center; padding-top: 4px;"><span class="p11">Featured Advertiser </span></div>
		<div style="margin: 1px 0px; overflow: hidden; width: 100%; height: 1px; background-color: rgb(207, 207, 207);"></div>
		<div style="width: 100%; text-align: center; padding-top: 4px;"><span class="p11">RBS and WSJ.com present<br><a class="b11" href="http://ad.doubleclick.net/clk;73205474;11024269;a?http://online.wsj.com/ad/rbs" target="_new">"Make it Happen"</a><br>find out how RBS and WSJ.com can help you "Make it Happen". </span></div>
		<div style="width: 100%; text-align: center; padding-top: 6px;"><span class="p11"><a class="p11" href="javascript:%20window.open('http://ad.doubleclick.net/clk;73205474;11024269;a?http://online.wsj.com/ad/rbs','LM','toolbar=yes,scrollbars=yes,location=no,resizable=yes,width=760,height=525,left=20,top=15');void('');">Click Here ...</a> </span></div>
	</div>
</div>






	
<!--Begin Commerce Center MODULE-->
<div class="adl">




	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;114269922;11024269;a?http://www.america.htc.com/products/8525/promo.html?utm_source=WallStreetJournal&amp;utm_medium=text&amp;utm_content=text&amp;utm_campaign=frontpage" onclick="OpenWin(this.href,'service','','','on',true);return false;">Get your AT&amp;T 8525 by HTC now!</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;112723212;11024269;l?http://blmkt.dsi-enews.net/hp/?dsid=39716&amp;typ=C" onclick="OpenWin(this.href,'service','','','on',true);return false;">HP Workstations for Finance</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;120584137;6853491;k?http://online.wsj.com/ad/behindthescreens" onclick="OpenWin(this.href,'service','','','on',true);return false;">Find out what's Behind the Screens. Presented by SHARP®</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;106127237;17315380;w" onclick="OpenWin(this.href,'service','','','on',true);return false;">New 2007 Jaguar XKR with 420hp</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;118402403;11024269;n?http://online.wsj.com/ad/accenture/" onclick="OpenWin(this.href,'service','','','on',true);return false;">A special section on Scientific Marketing by Accenture</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;85870630;11024269;f?http://online.wsj.com/ad/ups" onclick="OpenWin(this.href,'service','','','on',true);return false;">Submit your business challenge. Visit Delivering Insight. </a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;93710319;13094939;o?http://ad.doubleclick.net/clk;92489388;15993054;e?http://www.hp.com/sbso/wireless/verizon-ownhotspot.html" onclick="OpenWin(this.href,'service','','','on',true);return false;">A notebook PC that's a wi-fi hotspot.</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;100099507;11024269;v?http://ad.doubleclick.net/clk;100017218;16885521;v?http://hpliveeng.feedroom.com/?ex_ev04_w1%7Cbst%7Cus%7CDowJones_TextlinkText" onclick="OpenWin(this.href,'service','','','on',true);return false;">Turn Information Technology into Business Technology with HP.</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;112660735;16891239;j?http://s0b.bluestreak.com/ix.e?hy&amp;s=4296600&amp;a=5167675" onclick="OpenWin(this.href,'service','','','on',true);return false;">See what&#8217;s new at AA.com</a>
	</div>
  
<div style="border-top: 0px solid rgb(255, 255, 255); margin: 0pt; padding: 0pt; height: 11px; font-size: 2px;"></div>
</div>
<!--End Commerce Center MODULE-->





	<!-- adType:  -->
	




	<img src="us_files/b.gif" alt="" id="navExtenderIMAGE" border="0" height="1" width="1">
<div style="height: 1974px;" id="navExtender"></div>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var navTimeOut = null
function adjustNavExtender(){
	if (document.body.scrollHeight) {
		window.clearTimeout(navTimeOut)
		var navExtenderObj = document.getElementById("navExtenderIMAGE");
		var spaceLeftInNav = ((document.body.scrollHeight-getDist(navExtenderObj,true))+15)
		navExtenderObj.height=spaceLeftInNav
	}
}

if (window.document.body.onload) {
	window.document.body.onload = function() {
		adjustNavExtender()
		onLoadAction();
		window.document.body.onresize = function() {
			window.clearTimeout(navTimeOut)
			document.getElementById("navExtenderIMAGE").style.height='1'
			navTimeOut = window.setTimeout("adjustNavExtender()",1000)
		}
	}
	
} else if (onload) {
	onload = function() {
		if (document.body.scrollHeight) {
			var navExtenderObj = document.getElementById("navExtender");
			var spaceLeftInNav = Math.abs( document.body.scrollHeight-getDist(navExtenderObj,true));
			if(navigator.userAgent.indexOf("Firefox")==-1&&navigator.userAgent.indexOf("Netscape")==-1){
				document.getElementById("navExtenderIMAGE").height=spaceLeftInNav;
			}
			navExtenderObj.style.height=spaceLeftInNav+"px";
		}
		onLoadAction();
	}
}
//-->
</script>
</td>
      
  
  </tr>
  
</tbody></table>








	</div>	
  </div>
<!-- End nav -->


<!-- Begin body -->
  <div style="float: left; width: 854px;">
	
  
	
<!-- Begin column 3 -->
  		<div style="border: 0px none ; margin: 0px 0px 0px 14px; padding: 0px;">
  		












  		</div>
 <!-- End column 3 --> 		
  	

<!-- Begin left column -->
	<div style="float: left; width: 333px;">
		<div style="margin: 0px 0px 0px 14px; clear: left; width: 319px;">




	   




	<div style="border-top: 2px solid rgb(51, 102, 153); background-color: rgb(239, 239, 206); height: 18px;">
	<div style="padding-top: 2px;">
			<div class="b12" style="float: left; padding-left: 10px; vertical-align: middle; text-align: center;">FOR SUBSCRIBERS ONLY</div>
			<div class="p11" style="float: right; padding-right: 10px; vertical-align: middle; text-align: center; color: rgb(2, 83, 183);">
			<a href="http://online.wsj.com/login" class="unvisited" style="text-decoration: none;">Login</a><span style="color: rgb(0, 0, 0);"> | </span> <a href="https://online.wsj.com/reg/promo/6LJWFN_0607" class="unvisited" style="text-decoration: none;">Subscribe</a>
			</div>
	</div>
</div>
<div style="font-size: 4px; line-height: 4px; height: 4px; background-image: url(http://idev.online.wsj.com/img/subBarShadowPixelSlice.gif); background-repeat: repeat-x; margin-bottom: 18px;"></div>





	    <div align="center">
			<img id="image" src="us_files/hp_whats_news.gif" alt="" border="0" height="52" vspace="0" width="214">
        </div>
		



 
<div class="plnNine" style="border-top: 1px solid rgb(203, 211, 224); border-bottom: 1px solid rgb(203, 211, 224); margin: 2px 0px 0px; padding: 3px 0px 2px; color: rgb(102, 102, 102); text-align: center;"><span class="nobr">As of <span id="collectionTimeStamp">2:36:00 AM EDT Tue, July 24, 2007</span> </span></div>



<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr>
<td height="9"><img src="us_files/b.gif" alt="" border="0" height="9" width="1"></td>
</tr></tbody></table>







<!-- Start Breaking News -->
<span id="breakingNewsContent">
	<!--ContentStart//-->
	<!--DivID:breakingNewsContent://-->

<!--ContentEnd//-->
</span>
<!-- End Breaking News -->





<!-- begin what's news module --><div style="padding: 6px 0px 14px;"><div id="whatsNewsContent"><!--ContentStart//--><!--DivID:whatsNewsContent://--><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118523825903875664.html?mod=home_whats_news_us" class="arial">FOREIGN GOVERNMENTS ARE INVESTING</a></b>
aggressively in U.S. and European companies. The deals could prompt
political backlash and may bid up global prices for speculative
assets.&nbsp; <span class="red arial" style="white-space: nowrap;">12:10 a.m.</span></div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/economics/2007/07/23/a-code-of-conduct-for-sovereign-wealth-funds/"><b>Econ Blog:</b> Code of Conduct for Sovereign Wealth Funds </a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/article/SB118523399554775532.html?mod=home_whats_news_us"><b>Qatar, in U.K. Play, Shows Its Deal Thirst</b></a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/article/SB118517110670774773.html?mod=home_whats_news_us"><b>Barclays Bulks Up for Bank Fight</b></a></div>
</div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118522569482475410.html?mod=home_whats_news_us" class="arial">Wall Street firms postponed</a></b> a $3.1 billion debt sale to pay for the LBO of GM's Allison unit. <a class="arial" href="http://online.wsj.com/article/SB118520355569274958.html?mod=home_whats_news_us"><b>Expedia scaled back</b></a> a share buyback amid investor resistance.&nbsp; <span class="red arial" style="white-space: nowrap;">12:02 a.m.</span></div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/article/SB118520470399375024.html?mod=home_whats_news_us"><b>GM, UAW Can't Ignore Health Care</b></a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/deals/2007/07/23/allison-transmission-debt-sale-stalls-whither-chrysler/"><b>Deal Journal:</b> Whither Chrysler?</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/public/resources/documents/info-frmiss-070718-uaw.html" onclick="OpenWin('http://online.wsj.com/public/resources/documents/info-frmiss-070718-uaw.html','frameissue','790','607','off','true',20,0);return false;"><b>Issue Briefing:</b> UAW Labor Talks</a></div>
</div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118523524401475573.html?mod=home_whats_news_us" class="arial">A public pension-fund group</a></b> has begun pressuring foreign energy companies to reconsider doing business in Iran.&nbsp; <span class="red arial" style="white-space: nowrap;">10:53 p.m.</span></div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118522326046475319.html?mod=home_whats_news_us" class="arial">The Bancrofts met</a></b> in Boston to weigh whether to sell Dow Jones to News Corp. as a key member signaled her opposition.&nbsp; <span class="red arial" style="white-space: nowrap;">12:08 a.m.</span></div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/public/resources/documents/info-dowjonesdeal0607.html" onclick="OpenWin('/public/resources/documents/info-flash07.html?project=dowjonesdeal0607&h=530&w=978&hasAd=1&settings=dowjonesdeal0607','dowjonesdeal0607','978','700','off','true',40,10);void('');return false;"><b>Key Players:</b> Board, Bancrofts, executives</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://wsj.com/djbid"><b>Complete Coverage:</b> A Deal for Dow Jones?</a></div>
</div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118523114073575473.html?mod=home_whats_news_us" class="arial">Iraqi exiles face</a></b>
a passport Catch-22. Outdated papers force a furtive life, but
traveling abroad to get new ones could leave them stranded.&nbsp; <span class="red arial" style="white-space: nowrap;">11:58 p.m.</span></div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118523916542475669.html?mod=home_whats_news_us" class="arial">Clinton drove home</a></b>
her readiness to be commander-in-chief, while trading tweaks with Obama
and Edwards in a Democratic presidential debate with queries taken from
video submissions.&nbsp; <span class="red arial" style="white-space: nowrap;">12:32 a.m.</span></div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118519036883474849.html?mod=home_whats_news_us" class="arial">Stocks advanced</a></b>, buoyed by a major deal in the oil-drilling sector. <a class="arial" href="http://online.wsj.com/article/SB118520465256875032.html?mod=home_whats_news_us"><b>Natural-gas futures fell</b></a> amid cool weather, while oil slid below $75.</div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/mdc/public/page/marketsdata.html"><b>Data: </b> Markets Overview</a> | <a class="arial" href="http://online.wsj.com/mdc/public/page/mdc_bonds.html">Treasurys</a> | <a class="arial" href="http://online.wsj.com/mdc/public/page/mdc_currencies.html">Forex</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/marketbeat/"><b>MarketBeat:</b> When Bond Vigilantes Attack</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/economics/2007/07/23/subprime-vs-stocks-fundamental-divergence/"><b>Real Time Economics:</b> Fundamental Divergence</a></div>
</div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118519063590174865.html?mod=home_whats_news_us" class="arial">Oil drillers Transocean</a></b> and GlobalSantaFe agreed to an $18 billion combination that could herald more deals in the sector.&nbsp; <span class="red arial" style="white-space: nowrap;">10:54 p.m.</span></div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://wsj.com/email/outset_subscribe?checklist=138" onclick="OpenWin('http://wsj.com/email/outset_subscribe?checklist=138','','500','250','off',true,0,0,true);void('');return false;"><b>Deals News Alerts:</b> Sign up</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/deals/2007/07/23/weekend-roundup-deal-bears-hibernate/"><b>Deal Journal:</b> Deal Bears Hibernate</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/energy/"><b>Energy Roundup:</b> Drilling for Deals</a></div>
</div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118519295201274875.html?mod=home_whats_news_us" class="arial">Merck's profit rose</a></b> 12%, helped by strong sales of drugs for allergies and cholesterol. Schering-Plough's net more than doubled.&nbsp; <span class="red arial" style="white-space: nowrap;">12:03 a.m.</span></div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/health/2007/07/23/gardasil-gives-merck-shot-in-the-arm/"><b>Health Blog:</b> Gardasil Gives Merck Shot in the Arm</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/public/resources/documents/info-pp-070723-garda.html" onclick="OpenWin('http://online.wsj.com/public/resources/documents/info-pp-070723-garda.html','pp','740','628','off','true',20,0);return false;"><b>Products &amp; Profits:</b> Merck's Gardasil</a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/public/resources/documents/info-cheatsheets07.html" onclick="OpenWin('/public/resources/documents/info-flash07a.html?project=cheatsheets07&h=530&w=978&hasAd=1&settings=cheatsheets07','cheatsheets07','978','700','off','true',40,10);void('');return false;"><b>Cheat Sheets:</b> Countrywide, AT&amp;T, UAL</a></div>
</div>
</div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="padding: 3px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;" class="arialResize"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12"><div class="arial"><b><a href="http://online.wsj.com/article/SB118520370393574960.html?mod=home_whats_news_us" class="arial">A merged Sirius and XM</a></b> would offer a-la-carte pricing options, the satellite-radio firms said in a statement aimed at regulators.&nbsp; <span class="red arial" style="white-space: nowrap;">10:55 p.m.</span></div>
<div style="padding: 4px 0pt 5px;">
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/article/SB118519245607574873.html?mod=home_whats_news_us"><b>H-P Makes Move Into Data Centers</b></a></div>
<div class="wnlistitem p11"><span class="p11">&#8226;</span>&nbsp;<a class="arial" href="http://online.wsj.com/article/SB118522778257175434.html?mod=home_whats_news_us"><b>Nokia Buys Twango in Web Push</b></a></div>
</div>
</div><div style="line-height: 6px; font-size: 2px;"></div><div align="center"><img src="us_files/hp_whats_news_stars.gif" alt="" border="0" height="9" width="30"></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118523015456675462.html?mod=home_whats_news_us" class="arialResize"><b>American Express Earnings Rise 12%</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118519920959374938.html?mod=home_whats_news_us" class="arialResize"><b>American Standard in Deal</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118524459651375852.html?mod=home_whats_news_us" class="arialResize"><b>FDA Declines to Approve Wyeth Drug</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118519730742474885.html?mod=home_whats_news_us" class="arialResize"><b>Cumulus Media Agrees to Buyout</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118520481522475025.html?mod=home_whats_news_us" class="arialResize"><b>TI Revenue Slips 7.4% on Soft Demand</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118522358318575300.html?mod=home_whats_news_us" class="arialResize"><b>Netflix's Net Income Rises 50%</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118522376228575330.html?mod=home_whats_news_us" class="arialResize"><b>Investor Prods Midwest Air</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118517511755074768.html?mod=home_whats_news_us" class="arialResize"><b>TomTom to Make Bid for Tele Atlas</b></a></div><div style="background: transparent url(/img/hp_whats_news_round_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial; padding-bottom: 3px;"><img src="us_files/b.gif" alt="" border="0" height="1" hspace="0" vspace="0" width="12"><a href="http://online.wsj.com/article/SB118518000701874802.html?mod=home_whats_news_us" class="arialResize"><b>Toyota Keeps Sales Targets Despite Delays</b></a></div><!--ContentEnd//--></div><table border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr><!-- whats news Footer -->
<td colspan="2" style="padding-top: 10px;" class="p12">
<script type="text/javascript">
<!--
var WhatsNewsFooterMod="hps_us_whats_news_more";
if(pID=="0_0013") {WhatsNewsFooterMod = "hpp_europe_whats_news_more";}
if(pID=="0_0003_public") {WhatsNewsFooterMod = "hpp_europe_whats_news_more";}
if(pID=="0_0003") {WhatsNewsFooterMod = "hps_europe_whats_news_more";}
if(pID=="0_0012") {WhatsNewsFooterMod = "hpp_us_whats_news_more";}
if(pID=="0_0014") {WhatsNewsFooterMod = "hpp_asia_whats_news_more";}
if(pID=="0_0004_public") {WhatsNewsFooterMod = "hpp_asia_whats_news_more";}
if(pID=="0_0004") {WhatsNewsFooterMod = "hps_asia_whats_news_more";}

document.write('<table cellpadding="0" cellspacing="0" border="0" width="100%">')
document.write('<tr><td class="p12" valign="bottom">Business: <a href="'+((loggedIn)?"":"/public")+'/page/2_0002.html?mod='+WhatsNewsFooterMod+'" class="unvisited">U.S.</a>')
document.write('&nbsp;|&nbsp;')
document.write('<a href="'+((loggedIn)?"/home":"/public")+'/europe?mod='+WhatsNewsFooterMod+'" class="unvisited">Europe</a>')
document.write('&nbsp;|&nbsp;')
document.write('<a href="'+((loggedIn)?"/home":"/public")+'/asia?mod='+WhatsNewsFooterMod+'" class="unvisited">Asia</a>')
document.write('&nbsp;|&nbsp;')
document.write('<a href="/page/2_0005.html?mod='+WhatsNewsFooterMod+'" class="unvisited">Americas</a>')
document.write('</td><td class="p12" valign="bottom" align="right"><a href="/news/world_news?mod='+WhatsNewsFooterMod+'" class="unvisited">World News</a></td>')
document.write('</tr></table>')
if(!loggedIn) {
	document.write('<div class="p12"><a href="/news/us_business?mod='+WhatsNewsFooterMod+'"><img src="/img/loginArrow.gif" border="0"> LOG IN to see complete coverage</a></div>')
}
//-->
</script><table border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr><td class="p12" valign="bottom">Business: <a href="http://online.wsj.com/public/page/2_0002.html?mod=hps_us_whats_news_more" class="unvisited">U.S.</a>&nbsp;|&nbsp;<a href="http://online.wsj.com/public/europe?mod=hps_us_whats_news_more" class="unvisited">Europe</a>&nbsp;|&nbsp;<a href="http://online.wsj.com/public/asia?mod=hps_us_whats_news_more" class="unvisited">Asia</a>&nbsp;|&nbsp;<a href="http://online.wsj.com/page/2_0005.html?mod=hps_us_whats_news_more" class="unvisited">Americas</a></td><td class="p12" align="right" valign="bottom"><a href="http://online.wsj.com/news/world_news?mod=hps_us_whats_news_more" class="unvisited">World News</a></td></tr></tbody></table><div class="p12"><a href="http://online.wsj.com/news/us_business?mod=hps_us_whats_news_more"><img src="us_files/loginArrow.gif" border="0"> LOG IN to see complete coverage</a></div>
</td>
</tr></tbody></table></div>
<!-- end what's news module -->


<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr>
<td height="7"><img src="us_files/b.gif" alt="" border="0" height="7" width="1"></td>
</tr></tbody></table>



	<script>
var modVal=(loggedIn)?"hps_us_pageone_more":"hpp_us_pageone_more";
var itpPath=(loggedIn)?"/page/2_0133.html":"/public/page/2_0433.html"
document.write('<map name="itpImgMap">')
 document.write(' <area shape="rect" coords="166,42,272,58" href="/page/2_0233.html?mod=' + modVal +' " target="_top" alt="Go to Past Editions">')
  document.write('<area shape="rect" coords="49,42,165,58" href="' + itpPath + '?mod=' + modVal +' " target="_top" alt="Go to Todays Newspaper">')
document.write('</map>')
document.write('<img width="316" height="65" border="0" src="/img/hp_itp_page_one_2.gif" usemap="#itpImgMap" alt="Todays Newspaper"  />')
</script><map name="itpImgMap"><area shape="rect" coords="166,42,272,58" href="http://online.wsj.com/page/2_0233.html?mod=hpp_us_pageone_more" target="_top" alt="Go to Past Editions"><area shape="rect" coords="49,42,165,58" href="http://online.wsj.com/public/page/2_0433.html?mod=hpp_us_pageone_more" target="_top" alt="Go to Todays Newspaper"> </map><img src="us_files/hp_itp_page_one_2.gif" usemap="#itpImgMap" alt="Todays Newspaper" border="0" height="65" width="316">



<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr>
<td height="8"><img src="us_files/b.gif" alt="" border="0" height="8" width="1"></td>
</tr></tbody></table>




<a name="ITPWSJ_1"></a>
<table border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr valign="top"><td valign="top"><div style="padding: 3px 0px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12">
			<!-- Summary article type=Leader (U.S.) Page=U.S. Home--><a href="http://online.wsj.com/article/SB118523289611175502.html?mod=hpp_us_pageone" class="bold80">Copter Contract Gives Lockheed Choppy Ride</a></div><div class="arialResize"><div>Lockheed's
effort to meet its schedule in a program to update the presidential
fleet of Marine One choppers illustrates some of the problems that
persistently bog down big defense contracts.</div>
</div><div class="clearer">&nbsp;</div><span style="line-height: 7px; font-size: 7px;"><br>&nbsp;<br></span><div style="padding: 3px 0px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12">
			<!-- Summary article type=Leader (U.S.) Page=U.S. Home--><a href="http://online.wsj.com/article/SB118523825903875664.html?mod=hpp_us_pageone" class="bold80">Governments Get Bolder With Equity Stakes</a></div><div class="arialResize"><div>Foreign
governments are investing aggressively in U.S. and European companies.
The deals could prompt political backlash and may bid up global prices
for speculative assets.</div>
<div style="padding: 4px 0pt 5px;">
<div class=""><span class="p11">&#8226;</span>&nbsp;<a class="" href="http://blogs.wsj.com/economics/2007/07/23/a-code-of-conduct-for-sovereign-wealth-funds/"><b>Econ Blog:</b> Code of Conduct for Sovereign Wealth Funds </a></div>
<div class=""><span class="p11">&#8226;</span>&nbsp;<a class="" href="http://online.wsj.com/article/SB118523399554775532.html?mod=ITPWSJ_1"><b>Qatar, in U.K. Play, Shows Its Deal Thirst</b></a></div>
<div class=""><span class="p11">&#8226;</span>&nbsp;<a class="" href="http://online.wsj.com/article/SB118517110670774773.html?mod=ITPWSJ_1"><b>Barclays Bulks Up for Bank Fight</b></a></div>
</div>
</div><div class="clearer">&nbsp;</div><span style="line-height: 7px; font-size: 7px;"><br>&nbsp;<br></span><div style="padding: 3px 0px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12">
			<!-- Summary article type=A-hed Page=U.S. Home--><a href="http://online.wsj.com/article/SB118521616798775228.html?mod=hpp_us_pageone" class="bold80">Germans Hack at Forest of Road Signs</a></div><div class="arialResize"><div>Many
Germans believe the country's road signage has become so dense that
it's a safety hazard. But efforts to eliminate as much as half of the
estimated 20 million traffic signs isn't proving easy.</div>
<div style="padding: 4px 0pt 5px;">
<div class=""><span class="p11">&#8226;</span>&nbsp;<a class="" href="http://online.wsj.com/article/SB118520612925375066.html" onclick="OpenWin('/article/SB118520612925375066.html','wsjpopup','760','524','off',true,0,0,true);void('');return false;"><b>Photos:</b> Reading the Signs</a></div>
</div>
</div><div class="clearer">&nbsp;</div><span style="line-height: 7px; font-size: 7px;"><br>&nbsp;<br></span><div style="padding: 3px 0px 0px; background: transparent url(/img/hp_whats_news_square_bullet.gif) no-repeat scroll 0%; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;"><img src="us_files/b.gif" alt="" align="left" border="0" height="1" hspace="0" vspace="0" width="12">
			<!-- Summary article type=Leader (U.S.) Page=U.S. Home--><a href="http://online.wsj.com/article/SB118524665215575918.html?mod=hpp_us_pageone" class="bold80">Schools Beat Back Demands for Special-Ed</a></div><div class="arialResize"><div>Many
parents and advocates for disabled children say administrative reviews
in many parts of the U.S. overwhelmingly back school districts in
disputes over paying for special-education services. (<a class="" href="http://wsj.com/mainstreaming">More on mainstreaming</a>)</div>
</div><div class="clearer">&nbsp;</div></td></tr></tbody></table>



<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr>
<td height="9"><img src="us_files/b.gif" alt="" border="0" height="9" width="1"></td>
</tr></tbody></table>



	<!-- Page One footer -->
<script type="text/javascript">
 var usPageID, europePageID, asiaPageID, urlPrefix, modPrefix, logInMod;
 if (loggedIn) {
	usPageID = "2_0133";
	europePageID = "2_0134";
	asiaPageID = "2_0135";
        urlPrefix = "/";
        modPrefix = "hps_";
 } else {
	usPageID = "2_0433";
	europePageID = "2_0434";
	asiaPageID = "2_0435";
        urlPrefix = "/public/";
        modPrefix = "hpp_";
 }
 document.write('<table width="100%" cellpadding="0" cellspacing="0" border="0"><tr>')
 if("|0_0003|0_0013|".indexOf("|"+pID+"|")>-1) {
 	logInMod = ""+modPrefix+"europe_pageone_more"
 	document.write('<td align="left" class="p11"><a href="'+urlPrefix+'page/0,,'+europePageID+',00.html?mod='+modPrefix+'europe_pageone_more" class="unvisited">MORE From Today\'s European Print Edition</a></td>')
 	document.write('<td align="right" class="p11"><a href="'+urlPrefix+'page/0,,'+usPageID+',00.html?mod='+modPrefix+'europe_pageone_more" class="unvisited">U.S.</a> | <a href="'+urlPrefix+'page/0,,'+asiaPageID+',00.html?mod='+modPrefix+'us_pageone_more" class="unvisited">Asia</a></td>')
 } else if("|0_0004|0_0014|".indexOf("|"+pID+"|")>-1) {
 	logInMod = ""+modPrefix+"asia_pageone_more"
 	document.write('<td align="left" class="p11"><a href="'+urlPrefix+'page/0,,'+asiaPageID+',00.html?mod='+modPrefix+'asia_pageone_more" class="unvisited">MORE From Today\'s Asian Print Edition</a></td>')
 	document.write('<td align="right" class="p11"><a href="'+urlPrefix+'page/0,,'+usPageID+',00.html?mod='+modPrefix+'asia_pageone_more" class="unvisited">U.S.</a> | <a href="'+urlPrefix+'page/0,,'+europePageID+',00.html?mod='+modPrefix+'us_pageone_more" class="unvisited">Europe</a></td>')
 } else {
 	logInMod = ""+modPrefix+"us_pageone_more"
 	document.write('<td align="left" class="p11"><a href="'+urlPrefix+'page/0,,'+usPageID+',00.html?mod='+modPrefix+'us_pageone_more" class="unvisited">MORE From Today\'s Print Edition</a></td>')
 	document.write('<td align="right" class="p11"><a href="'+urlPrefix+'page/0,,'+europePageID+',00.html?mod='+modPrefix+'us_pageone_more" class="unvisited">Europe</a> | <a href="'+urlPrefix+'page/0,,'+asiaPageID+',00.html?mod='+modPrefix+'us_pageone_more" class="unvisited">Asia</a></td>')
 }
 document.write('</tr>')
 if (!loggedIn) { 
 	document.write('<tr><td class="p11"><a href="/login?mod='+logInMod+'" class="unvisited"><img src="/img/loginArrow.gif" border="0"> LOG IN to access Today\'s Print Edition</a></td></tr>')
 }  
 document.write('</table>')
</script><table border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr><td class="p11" align="left"><a href="http://online.wsj.com/public/page/0,,2_0433,00.html?mod=hpp_us_pageone_more" class="unvisited">MORE From Today's Print Edition</a></td><td class="p11" align="right"><a href="http://online.wsj.com/public/page/0,,2_0434,00.html?mod=hpp_us_pageone_more" class="unvisited">Europe</a> | <a href="http://online.wsj.com/public/page/0,,2_0435,00.html?mod=hpp_us_pageone_more" class="unvisited">Asia</a></td></tr><tr><td class="p11"><a href="http://online.wsj.com/login?mod=hpp_us_pageone_more" class="unvisited"><img src="us_files/loginArrow.gif" border="0"> LOG IN to access Today's Print Edition</a></td></tr></tbody></table>



<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr>
<td height="27"><img src="us_files/b.gif" alt="" border="0" height="27" width="1"></td>
</tr></tbody></table>



  <!-- OVERTURE SPONSORED LINKS BEGIN -->
  <script type="text/javascript">
  <!--
	  if ("" == "dynamic") {	
	    var ctxtAdURL = parent.location;	  
	    var ctxt_ad_url_encoded = escape(ctxtAdURL);
	    ctxt_ad_url_encoded = ctxt_ad_url_encoded.substring(0,1023);	    
	    ctxt_ad_url_encoded = ctxt_ad_url_encoded.replace(/%[0-9]?$/, '');
	    var ctxtAdURL = "&amp;ctxtUrl=" + ctxt_ad_url_encoded;	
	  } else {	
	    var ctxtAdURL = "";	
	  }	
	  ListOfIframes.kanoodleIframe314 = "/static_html_files/sponsored_links_new.html?Partner=general network:premium&amp;ctxtId=news&amp;adwd=314&amp;adht=218" + ctxtAdURL + "&amp;css_url=&amp;tg=1&amp;cb=" + (new Date()).getTime()+"&numresults=3";
  //-->
  </script>


  <div class="adWrapper" style="width: 314px;">	
		 
		  <div class="adTitleWrapper">
				<div style="padding: 4px 4px 4px 0px; float: right;">
				<a href="#" onclick="window.open('http://context3.kanoodle.com/wsj_whats_this_popup.html', 'Warning','toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=yes,resizable=no,width=310,height=280'); return false;" class="adExplanation">What's This?</a><span class="adExplanation"> | </span>
				<a href="#" onclick="window.open('http://www.kanoodle.com/signup/contact_information.html?refid=86272606'); return false;" class="adExplanation">Get Listed</a>
				</div>			
				<div class="adTitleBox">ADVERTISERS LINKS</div>
			</div>
	     
    <iframe id="kanoodleIframe314" src="us_files/blank_015.html" marginwidth="0" marginheight="0" style="margin: 0px;" frameborder="0" height="218" scrolling="no" width="314"></iframe>
  </div>


  <!-- OVERTURE SPONSORED LINKS END -->


		</div>
	</div> 
<!-- End left column -->

	
<!-- Begin right column -->
	<div style="float: left; width: 521px;">
		<div style="margin: 0px 0px 0px 13px; clear: left; width: 508px;">





















<!-- Begin body -->
  <div style="border: 1px solid rgb(102, 102, 102); clear: left; width: 506px;">
	
  
	
<!-- Begin column 3 -->
  		<div style="border: 0px none ; margin: 0px; padding: 0px;">
  		



	<div style="border-bottom: 1px solid rgb(153, 153, 153); background-color: rgb(255, 255, 255); background-image: url(/img/hpFTbg0.gif); background-repeat: repeat-x; background-position: left bottom;">
	<!-- Start of Free Today Header -->
	<div style="height: 49px;">
		<!-- Start Free Today Text -->
		<div style="border: 0px none ; padding: 10px 16px 0px 13px; float: left; font-family: Georgia,Times,serif; font-size: 26px; color: rgb(0, 0, 0);">Free Today</div>
		<!-- End Free Today Text -->
		<div style="border: 0px none ; padding: 7px 16px 0pt 0pt; float: left;"><img src="us_files/header2pxBars.gif" alt="" height="34" width="2"></div>
		<!-- Start Search Text and Form -->
		<div class="p11" style="border: 0px none ; padding: 18px 3px 0pt 0pt; float: left;">Search</div>
		<div>
			<script type="text/javascript">
  			<!--
      			if (!loggedIn) {
  	 				document.write('<' + 'form name="article_search" action="/public/search/page/3_0466.html" method="get" style="margin:0px;" onsubmit="suppress_popup=true;return true;">');
      			} else {
	 				document.write('<' + 'form name="main_article_search" action="/search" method="get" style="margin:0px;padding:0px" onsubmit="suppress_popup=true;return true;">');
      			}
  			// -->
			</script><form name="article_search" action="/public/search/page/3_0466.html" method="get" style="margin: 0px;" onsubmit="suppress_popup=true;return true;">
			<div style="padding: 16px 0pt 0pt; float: left;" class="p10">
				<input class="p11" style="padding: 0px; width: 71px;" name="KEYWORDS" value="" type="text">
				<input style="padding: 0pt 0pt 0pt 0px;" name="imageField" src="us_files/hprightarrow.gif" type="image" border="0" height="10" width="5">
			</div>
			<script type="text/javascript">
			<!--
				document.write('</form>')
			// -->
			</script></form>
		</div>
		<!-- End Search Text and Form -->
		<div style="border: 0px none ; padding: 7px 17px 0pt 16px; float: left;"><img src="us_files/header2pxBars.gif" alt="" height="34" width="2"></div>
		<div style="border: 0px none ; padding: 9px 0px 0px; float: left;" class="p10">
		
			<form name="fund_search" id="fund_search" action="/public/fund/page/fund_snapshot.html" method="get">
				<input name="sym" size="8" type="hidden">
			</form>
			<form name="US_search" id="US_search" action="/public/quotes/main.html?symbol=sym" method="get" onsubmit="return checkCRSymbol('US_search','fund_search');">	
			<table style="margin: 0px; padding: 0px;" border="0" cellpadding="0" cellspacing="0">
				<tbody><tr>
					<td rowspan="2" class="p11" valign="top">Company<br>Research</td>
					<td colspan="4" style="padding-left: 5px;"><input class="p11" style="padding: 0px; width: 90px;" name="symbol_or_name" type="text"><input style="margin-left: 3px;" name="imageField" src="us_files/hprightarrow.gif" type="image" border="0" height="10" width="5"></td>
				</tr>
				<tr>
					<td><input name="sym_name_switch" value="symbol" checked="checked" type="radio"></td>
					<td>Symbol(s)</td>

					<td><input name="sym_name_switch" value="name" type="radio"></td>
					<td>Name</td>
				</tr>
			</tbody></table>
			<input name="type" value="usstock usfund" type="hidden"> 
			</form>
		</div>		
	</div>
</div>

<div class="p11" style="border-top: 0px solid; border-bottom: 1px solid rgb(153, 153, 153); padding: 4px 0px 3px 10px; background-color: rgb(255, 255, 255); background-image: url(/img/hpFTbg2.gif); background-repeat: repeat-x; background-position: left bottom; font-style: italic; margin-bottom: 1px;">From The Wall Street Journal and other Dow Jones Publications</div>





	<script type="text/javascript" language="javascript" charset="ISO-8859-1">
	<!--
	$import('com.dowjones.carousel')
	//-->
	</script><script type="text/javascript" src="us_files/carousel.js"></script>

	<div style="border-top: 2px solid rgb(94, 142, 182); border-bottom: 0px solid rgb(102, 102, 102); padding: 12px 0px 14px; background-color: rgb(242, 247, 251);" class="p11"><div style="overflow: hidden; height: 68px;"><span style="padding: 15px 0px 0px; float: left; width: 44px; height: 68px; text-align: center;"><img class="carouseldisable" id="carouselLBtn" onclick="carouselObject.scroll(0)" alt="Left" src="us_files/hpCarouselLeft.gif" border="0" height="30" width="31"></span><div style="border-left: 1px solid rgb(153, 153, 153); overflow: hidden; line-height: 13px; float: left; width: 414px; height: 68px;" id="carouselContainer"><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: block;"><a class="bold" href="http://online.wsj.com/article/SB118523245975475487.html?mod=hpp_us_editors_picks"><img src="us_files/it_middleseat09142004171604.gif" alt="Go to Story" class="imgitboxLEFT" align="left" border="0" height="48" width="44"></a><a class="bold" href="http://online.wsj.com/article/SB118523245975475487.html?mod=hpp_us_editors_picks">The Middle Seat:</a> Bumped fliers may get a better deal.</div><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: block;"><a class="bold" href="http://podcast.mktw.net/wsj/audio/20070723/pod-wsjhome/pod-wsjhome.mp3"><img src="us_files/it_podcast-home-front11032006161956.gif" alt="Listen to podcast" class="imgitboxLEFT" align="left" border="0" height="48" width="44"></a><a class="bold" href="http://podcast.mktw.net/wsj/audio/20070723/pod-wsjhome/pod-wsjhome.mp3">Podcast:</a> Cracking down on lawn watering.</div><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: block;"><a class="bold" href="http://blogs.wsj.com/washwire/"><img src="us_files/it_capitol-dome09142004171604.gif" alt="Washington Wire" class="imgitboxLEFT" align="left" border="0" height="48" width="44"></a><a class="bold" href="http://blogs.wsj.com/washwire/">Washington Wire:</a> No ballot-box stuffing allowed in the debate.</div><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: none;"><a class="bold" href="http://forums.wsj.com/viewtopic.php?t=650"><img src="us_files/it_qod09142004171604.gif" alt="Question of the Day" class="imgitboxLEFT" align="left" border="0" height="48" width="44"></a><a class="bold" href="http://forums.wsj.com/viewtopic.php?t=650">Vote:</a> Are you in the career you envisioned when you were in college?</div><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: none;"><a class="bold" href="javascript:OpenWin('http://online.wsj.com/public/resources/documents/info-flash07a.html?project=checkup07&h=530&w=978&hasAd=1&settings=checkup07&xmlFileToLoad=info-checkup07_072007.xml','checkup07','978','700','off','true',40,10)"><img src="us_files/it_checkup09142004171604.gif" alt="Go to Checkup" class="imgitboxLEFT" align="left" border="0" height="48" width="44"></a><a class="bold" href="javascript:OpenWin('http://online.wsj.com/public/resources/documents/info-flash07a.html?project=checkup07&h=530&w=978&hasAd=1&settings=checkup07&xmlFileToLoad=info-checkup07_072007.xml','checkup07','978','700','off','true',40,10)">Checkup:</a> A look at drugs to treat chronic obstructive pulmonary disease.</div><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: none;"><a class="bold" href="javascript:OpenWin('http://online.wsj.com/public/resources/documents/info-flash07a.html?project=cheatsheets07&h=530&w=978&hasAd=1&settings=cheatsheets07','cheatsheets07','978','700','off','true',40,10)"><img src="us_files/it_earnings-cheat-sheet09142004171604.gif" alt="Cheat Sheets" class="imgitboxLEFT" align="left" border="0" height="48" width="44"></a><a class="bold" href="javascript:OpenWin('http://online.wsj.com/public/resources/documents/info-flash07a.html?project=cheatsheets07&h=530&w=978&hasAd=1&settings=cheatsheets07','cheatsheets07','978','700','off','true',40,10)">Cheat Sheets:</a> See what to expect as companies report quarterly earnings.</div><div style="border-right: 1px solid rgb(153, 153, 153); padding: 0px 5px; float: left; width: 127px; height: 68px; display: none;"><a class="bold" href="http://wsj.com/onlinetoday">Online Today</a> | <a class="bold" href="http://blogs.wsj.com/law">Law</a><br><a class="bold" href="http://blogs.wsj.com/deals/">Deal Journal</a> | <a class="bold" href="http://blogs.wsj.com/economics">Econ</a><br><br>
More <a class="bold" href="http://online.wsj.com/public/page/2_1186_public.html">free features</a>, <a class="bold" href="http://online.wsj.com/page/8_0019.html">WSJ blogs</a> and <a class="bold" href="http://online.wsj.com/mdc/public/page/marketsdata.html">data</a>.</div></div><span style="padding: 15px 0px 0px; float: left; width: 44px; height: 68px; text-align: center;"><img class="carouselenable" id="carouselRBtn" onclick="carouselObject.scroll(1)" alt="Right" src="us_files/hpCarouselRight.gif" border="0" height="30" width="31"></span></div></div>
	<script type="text/javascript" language="javascript" charset="ISO-8859-1">

	<!--
	var carouselObject = new com.dowjones.carousel()
	carouselObject.init('carouselContainer','carouselLBtn','carouselRBtn')
	//-->
	</script>
	





















<!-- Begin body -->
  <div style="background-color: rgb(242, 247, 251);">
	
  
	

<!-- Begin left column -->
	<div style="float: left; width: 187px; background-color: rgb(242, 247, 251);">
		<div style="margin-left: 10px; margin-bottom: 15px; height: 250px; background-color: rgb(242, 247, 251);">



<div style="border-style: solid; border-color: rgb(170, 151, 85) rgb(170, 151, 85) rgb(255, 255, 255); border-width: 1px 1px 0px;" class="p11"><div style="padding: 2px 0pt 0pt 5px; background-image: url(/img/hpMDCbg0.gif); background-repeat: repeat-x; background-position: left bottom; height: 16px;"><a style="color: rgb(0, 0, 0);" class="bold" href="http://online.wsj.com/marketsdata?mod=hpp_us_indexes">
				MARKETS DATA CENTER
			</a>&nbsp;|&nbsp;<a class="p10 unvisited" href="http://online.wsj.com/marketsdata?mod=hpp_us_indexes">more</a></div></div><div class="p11" style="border-style: solid; border-color: rgb(255, 255, 255) rgb(0, 0, 0) rgb(0, 0, 0); border-width: 0px 1px 1px; background-color: rgb(255, 255, 255); height: 230px;" id="mdcContainer"><div style="width: 165px; margin-left: 6px; margin-right: 4px;"><div id="mdcIMGcontainer" style="padding-top: 6px;"><img src="us_files/wsjie-nshsm-frontpage-indxchart.gif" alt="Chart" border="0" height="47" width="165"></div><div style="height: 127px;"><div id="mdcIndexContainer" class="p11" style="border: 0px none ; padding: 0px; height: 48px;"><div style="border-top: 2px solid rgb(203, 211, 224); border-bottom: 1px solid rgb(203, 211, 224); margin-top: 2px;"><table padding="0" cellpadding="0" cellspacing="0" width="100%"><tbody><tr style="background-color: rgb(241, 237, 225);"><td align="left" height="15"><a id="indexlnk0" class="pumpkinIndex" href="http://chart.bigcharts.com/custom/wsjie/wsjie-nshsm-frontpage-indxchart.img?sid=1643" onclick="com.dowjones.nonSubHPMarketsBox.ApplyLinkStyle(0);com.dowjones.nonSubHPMarketsBox.drawChart(0);return false;">DJIA*</a></td><td align="right" height="15">13943.42</td><td align="right" height="15"><span style="color: rgb(0, 153, 102);">92.34</span></td><td align="right" height="15"><span style="color: rgb(0, 153, 102);">0.67</span></td></tr><tr style="background-color: rgb(255, 255, 255);"><td align="left" height="15"><a id="indexlnk1" class="unvisited" href="http://chart.bigcharts.com/custom/wsjie/wsjie-nshsm-frontpage-indxchart.img?sid=3291" onclick="com.dowjones.nonSubHPMarketsBox.ApplyLinkStyle(1);com.dowjones.nonSubHPMarketsBox.drawChart(1);return false;">Nasdaq*</a></td><td align="right" height="15">2690.58</td><td align="right" height="15"><span style="color: rgb(0, 153, 102);">2.98</span></td><td align="right" height="15"><span style="color: rgb(0, 153, 102);">0.11</span></td></tr><tr style="background-color: rgb(241, 237, 225);"><td align="left" height="15"><a id="indexlnk2" class="unvisited" href="http://chart.bigcharts.com/custom/wsjie/wsjie-nshsm-frontpage-indxchart.img?sid=3377" onclick="com.dowjones.nonSubHPMarketsBox.ApplyLinkStyle(2);com.dowjones.nonSubHPMarketsBox.drawChart(2);return false;">S&amp;P 500*</a></td><td align="right" height="15">1541.57</td><td align="right" height="15"><span style="color: rgb(0, 153, 102);">7.47</span></td><td align="right" height="15"><span style="color: rgb(0, 153, 102);">0.49</span></td></tr></tbody></table></div></div><div style="border: 0px none ; padding: 0px; height: 17px;" class="p9"><div style="height: 8px;"><span style="float: right;">Source:Dow Jones,
							<a class="unvisited" onclick="OpenWin(this.href,'Reuters_Disclaimer',290,240,'off',true);return false;" href="http://online.wsj.com/public/page/reuters_popup.html?mod=hpp_us_indexes">
							Reuters</a></span><span style="float: left;">* at close</span></div></div><div style="border: 0pt none ; padding: 0pt; clear: both; height: 12px;" class="decoClearer"><div style="padding: 0pt; float: left; height: 8px;"><img class="carouseldisable" style="float: left; margin-top: 3px; margin-right: 3px;" onclick="mdcCarouselObject.scroll(0)" id="mdcCarouselLBtn" alt="" src="us_files/hpmdcleftarrow.gif" border="0" height="8" width="4"></div><div style="float: left; width: 151px; height: 8px;" id="stock_headers"><div style="display: block;" id="stock_header_1"><span style="float: left;" class="bold">NYSE 
								<a style="color: rgb(204, 102, 51);" href="http://online.wsj.com/mdc/public/page/2_3021-activnyse-actives.html?mod=hpp_us_indexes">
									Most Actives
								</a>&nbsp;
							</span><span style="float: left;" class="p10"><a href="http://online.wsj.com/mdc/public/page/2_3021-activnyse-actives.html?mod=hpp_us_indexes">
							 		more
								</a></span></div><div style="display: none;" id="stock_header_2"><span style="float: left;" class="bold">NASDAQ 
								<a style="color: rgb(204, 102, 51);" href="http://online.wsj.com/mdc/public/page/2_3021-activnnm-actives.html?mod=hpp_us_indexes">
									Most Actives
								</a>&nbsp;
							</span><span style="float: left;" class="p10"><a href="http://online.wsj.com/mdc/public/page/2_3021-activnnm-actives.html?mod=hpp_us_indexes">
							 		more
								</a></span></div><div style="display: none;" id="stock_header_3"><span style="float: left;" class="bold">NYSE 
								<a style="color: rgb(204, 102, 51);" href="http://online.wsj.com/mdc/public/page/2_3021-gainnyse-gainer.html?mod=hpp_us_indexes">
									Gainers
								</a>&nbsp;
							</span><span style="float: left;" class="p10"><a href="http://online.wsj.com/mdc/public/page/2_3021-gainnyse-gainer.html?mod=hpp_us_indexes">
							 		more
								</a></span></div><div style="display: none;" id="stock_header_4"><span style="float: left;" class="bold">NASDAQ 
								<a style="color: rgb(204, 102, 51);" href="http://online.wsj.com/mdc/public/page/2_3021-gainnnm-gainer.html?mod=hpp_us_indexes">
									Gainers
								</a>&nbsp;
							</span><span style="float: left;" class="p10"><a href="http://online.wsj.com/mdc/public/page/2_3021-gainnnm-gainer.html?mod=hpp_us_indexes">
									more
								</a></span></div><div style="display: none;" id="stock_header_5"><span style="float: left;" class="bold">NYSE 
								<a style="color: rgb(204, 102, 51);" href="http://online.wsj.com/mdc/public/page/2_3021-losenyse-loser.html?mod=hpp_us_indexes">
									Decliners
								</a>&nbsp;
							</span><span style="float: left;" class="p10"><a href="http://online.wsj.com/mdc/public/page/2_3021-losenyse-loser.html?mod=hpp_us_indexes">
							 		more
								</a></span></div><div style="display: none;" id="stock_header_6"><span style="float: left;" class="bold">NASDAQ 
								<a style="color: rgb(204, 102, 51);" href="http://online.wsj.com/mdc/public/page/2_3021-losennm-loser.html?mod=hpp_us_indexes">
									Decliners
								</a>&nbsp;
							</span><span style="float: left;" class="p10"><a href="http://online.wsj.com/mdc/public/page/2_3021-losennm-loser.html?mod=hpp_us_indexes">
							 		more
								</a></span></div></div><div style="padding: 0px; float: left; height: 8px;"><img class="carouselenable" style="margin-top: 3px; margin-left: 3px;" onclick="mdcCarouselObject.scroll(1)" id="mdcCarouselRBtn" alt="" src="us_files/hpmdcrightarrow.gif" border="0" height="8" width="4"></div></div><div style="margin: 0pt; padding: 0px; clear: both; height: 48px;" id="stocks"><!--ContentStart//--><!--DivID:stocks://-->
	
	 
	<div style="display: block;" id="stocks_1"><div style="border-top: 2px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=IWM">iShrRu2000</a></div><div style="float: right;">67,726,466</div></div><div style="background-color: rgb(255, 255, 255); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=PFE">Pfizer</a></div><div style="float: right;">40,050,002</div></div><div style="border-bottom: 1px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=MRK">Merck</a></div><div style="float: right;">39,948,580</div></div></div>

	
	 
	

	 
	<div id="stocks_2" style="display: none;"><div style="border-top: 2px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=QQQQ">PwrShrs QQQ</a></div><div style="float: right;">107,449,286</div></div><div style="background-color: rgb(255, 255, 255); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=OPSW">Opsware</a></div><div style="float: right;">78,796,808</div></div><div style="border-bottom: 1px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=CSCO">CiscoSys</a></div><div style="float: right;">63,473,294</div></div></div>
	
	
	
	
	 
	<div id="stocks_3" style="display: none;"><div style="border-top: 2px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=NVT%3E">Navteq</a></div><div style="float: right;"><span class="changePos">18.50%</span></div></div><div style="background-color: rgb(255, 255, 255); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=SR%3E">StdRegstr</a></div><div style="float: right;"><span class="changePos">16.47%</span></div></div><div style="border-bottom: 1px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=SRI%3E">Stoneridge</a></div><div style="float: right;"><span class="changePos">11.60%</span></div></div></div>
	
	 
	
	
	
	 
	<div id="stocks_4" style="display: none;"><div style="border-top: 2px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=OPSW">Opsware</a></div><div style="float: right;"><span class="changePos">36.19%</span></div></div><div style="background-color: rgb(255, 255, 255); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=CMLS">CumulusMda</a></div><div style="float: right;"><span class="changePos">32.86%</span></div></div><div style="border-bottom: 1px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=ARRO">ArrowInt</a></div><div style="float: right;"><span class="changePos">16.72%</span></div></div></div>
	



   
	 
	<div id="stocks_5" style="display: none;"><div style="border-top: 2px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=NHPB">NatwdHlth pfB</a></div><div style="float: right;"><span class="changeNeg">-17.15%</span></div></div><div style="background-color: rgb(255, 255, 255); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=MZ">Milacron</a></div><div style="float: right;"><span class="changeNeg">-12.48%</span></div></div><div style="border-bottom: 1px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=ACA">ACA CapHldgs</a></div><div style="float: right;"><span class="changeNeg">-11.25%</span></div></div></div>

   
   
        


   
        <div id="stocks_6" style="display: none;"><div style="border-top: 2px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=NCST">NucrystPharm</a></div><div style="float: right;"><span class="changeNeg">-29.79%</span></div></div><div style="background-color: rgb(255, 255, 255); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=TGIS">ThomasGp</a></div><div style="float: right;"><span class="changeNeg">-18.30%</span></div></div><div style="border-bottom: 1px solid rgb(203, 211, 224); background-color: rgb(241, 237, 225); height: 15px;"><div style="float: left;"><a href="http://online.wsj.com/public/quotes/main.html?type=usstock+usfund&amp;mod=hpp_us_indexes&amp;symbol=LPNT">LifePoint</a></div><div style="float: right;"><span class="changeNeg">-17.54%</span></div></div></div>

        	
<!--ContentEnd//--></div></div></div><div style="height: 44px; display: block;" id="mdcSponsership"><center>
<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=165x45;ord=4309430943094309;';
if ( isSafari ) {
  tempHTML += '<iframe id="market_sponsor" src="'+adURL+'" width="165" height="45" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:165">';
} else {
  tempHTML += '<iframe id="market_sponsor" src="/static_html_files/blank.htm" width="165" height="45" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:165px;">';
  ListOfIframes.market_sponsor= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=165x45;ord=4309430943094309;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=165x45;ord=4309430943094309;" border="0" width="165" height="45" vspace="0" alt="Advertisement" /></'+'a><br /></'+'iframe>';
document.write(tempHTML);
// -->
</script><iframe id="market_sponsor" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 165px;" frameborder="0" height="45" scrolling="no" width="165">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us;!category=;msrc=null;null;sz=165x45;ord=4309430943094309;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us;!category=;msrc=null;null;sz=165x45;ord=4309430943094309;"
border="0" width="165" height="45" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
			</center></div></div>


<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--

	var sponsership = new Object();
	sponsership.src = "/adimg/samsung-88x25.gif";
	sponsership.width = "88";
	sponsership.height = "25";
	sponsership.href = "http://wsj.com";

-->
</script>



	<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
document.write('<'+'s'+'c'+'r'+'i'+'p'+'t s'+'r'+'c'+'="/public/resources/live/0_0024_JSON.'+'j'+'s'+'?a='+GenRandomNum()+'"'+'>'+'<'+'/'+'s'+'c'+'r'+'i'+'p'+'t'+'>')
// -->
</script><script src="us_files/0_0024_JSON.html"></script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var indexes = ['DJI', 'NCM', 'SPX']
//-->
</script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
$import("com.dowjones.mdccarousel")
$import("com.dowjones.nonSubHPMarketsBox")
//-->
</script><script type="text/javascript" src="us_files/mdccarousel.js"></script><script type="text/javascript" src="us_files/nonSubHPMarketsBox.js"></script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
com.dowjones.nonSubHPMarketsBox.init(sponsership, indexes)
//-->
</script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var mdcCarouselObject = new com.dowjones.mdccarousel()
mdcCarouselObject.init('mdcCarouselLBtn','mdcCarouselRBtn')
//-->
</script>

		</div>
	</div> 
<!-- End left column -->

	
<!-- Begin right column -->
	<div style="float: left; width: 319px; background-color: rgb(242, 247, 251);">
		<div style="margin-left: 10px; margin-right: 9px; margin-bottom: 15px; background-color: rgb(242, 247, 251); height: 250px;">











<div style="padding: 0px;">
<center>



	
<div style="float: left; width: 300px;">
	 
 	
<span id="adv300x250"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=300x250;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="adR" src="'+adURL+'" width="300" height="250" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:300">';
} else {
  tempHTML += '<iframe id="adR" src="/static_html_files/blank.htm" width="300" height="250" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:300px;">';
  ListOfIframes.adR= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=300x250;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=300x250;ord=4844484448444844;" border="0" width="300" height="250" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="adR" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 300px;" frameborder="0" height="250" scrolling="no" width="300">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us;!category=;msrc=null;null;ptile=2;sz=300x250;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us;!category=;msrc=null;null;ptile=2;sz=300x250;ord=4844484448444844;"
border="0" width="300" height="250" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</span>
</div>

</center>
</div>

		</div>
	</div> 
<!-- End right column -->
	

	

	
  </div>	  
<!-- End body -->  


  		</div>
 <!-- End column 3 --> 		
  	

<!-- Begin left column -->
	<div id="left_rr" style="border-right: 1px solid rgb(153, 153, 153); overflow: hidden; float: left; width: 252px; background-color: rgb(242, 247, 251); height: 2057px;">
		<div style="margin: 0px; clear: left; width: 252px; background-color: rgb(242, 247, 251);">




	<div style="border-top: 1px solid rgb(154, 155, 155); border-bottom: 2px solid rgb(154, 155, 155); height: 20px; width: 252px;">
	<div class="f2dayColHedNew" style="border-bottom: 1px solid rgb(154, 155, 155); padding-top: 2px; height: 16px; width: 252px;">
		<span style="padding-left: 10px; vertical-align: middle;">WALL STREET JOURNAL ARTICLES</span>&nbsp;&nbsp;<img src="us_files/hpdownarrow.gif" alt="" border="0" height="4" width="7">
	</div>
</div>



<div id="pjHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 10px; width: 232px;"><div style="margin: 0px 0px 8px;"><span class="onlinestrap"><a href="http://online.wsj.com/personaljournal?mod=hpp_us_personal_journal">PERSONAL JOURNAL</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/personaljournal?mod=hpp_us_personal_journal">
								more
							</a></span></div><div style="margin-bottom: 6px;"><div style="float: left; padding-right: 4px;"><img src="us_files/it_mortgage_tool.gif" style="width: 44px; height: 48px;"></div><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118523686276375626.html?mod=hpp_us_personal_journal">Sipping Vitamins</a><p>The
explosion of nutrient-laced drinks reflects consumers' desire for more
healthful choices than soda, and frenzied competition is fueling bold
marketing claims. But many experts say there is little evidence to
suggest that fortified beverages make a significant difference in
health. Plus, a surprising link between <a class="bold" href="http://online.wsj.com/article/SB118523105635575469.html?mod=hpp_us_personal_journal">obesity and diet soda</a>.</p></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118523973305375695.html?mod=hpp_us_personal_journal">The $200 Tire</a></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118523245975475487.html?mod=hpp_us_personal_journal">The Middle Seat</a></div></div><div style="margin-bottom: 18px;"><span class="onlinehmore"><a href="http://online.wsj.com/personaljournal?mod=hpp_us_personal_journal">
							MORE
						</a></span></div></div>



<div id="pfHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 0px 10px; width: 232px;"><div style="margin: 0px 0px 8px;"><span class="onlinestrap"><a href="http://online.wsj.com/redirect/personalfinance.html?mod=hpp_us_personal_finance">PERSONAL FINANCE</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/redirect/personalfinance.html?mod=hpp_us_personal_finance">
								more
							</a></span></div><div style="margin-bottom: 6px;"><div style="float: left; padding-right: 4px;"><img src="us_files/it_wallet.gif" style="width: 44px; height: 48px;"></div><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118498237089473748.html?mod=hpp_us_personal_finance">Readers' Turn: The Home Front and Cars</a><p>Readers
offer their input this week on the home-upkeep tasks we too often put
off; paying kids for chores around the house; and the fact that so many
teens these days are driving such nice cars.</p></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118498132532773712.html?mod=hpp_us_personal_finance">Nursing Homes, Medicaid and Your Assets</a></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118480800383271110.html?mod=hpp_us_personal_finance">Three IPOs Make Splash; MF Global on Tap</a></div></div><div style="margin-bottom: 18px;"><span class="onlinehmore"><a href="http://online.wsj.com/redirect/personalfinance.html?mod=hpp_us_personal_finance">
							MORE
						</a></span></div></div>



<div id="wlHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 8px;"><span class="onlinestrap"><a href="http://online.wsj.com/redirect/leisure.html?mod=hpp_us_leisure">LEISURE</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/redirect/leisure.html?mod=hpp_us_leisure">
								more
							</a></span></div><div style="margin-bottom: 6px;"><div style="float: left; padding-right: 4px;"><img src="us_files/it_deck-chair.gif" style="width: 44px; height: 48px;"></div><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118523218924275494.html?mod=hpp_us_leisure">The Finale Is Magical, Even for Muggles</a><p>Given
the fever of anticipation and the drama of a sales embargo -- broken,
at last, at 12:01 on Saturday morning -- the wait for "Harry Potter and
the Deathly Hallows" felt endless, even if the waiting-ordeal really
lasted only a matter of months. But the big questions about this
culminating piece of J.K. Rowling's imaginary world have been bubbling
for years.</p></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118522872953475448.html?mod=hpp_us_leisure">Wagoner Takes a Victory Lap</a></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118524368791475827.html?mod=hpp_us_leisure">Hopper in a New Light?
Well, Up to a Point</a></div></div><div style="margin-bottom: 18px;"><span class="onlinehmore"><a href="http://online.wsj.com/redirect/leisure.html?mod=hpp_us_leisure">
							MORE
						</a></span></div></div>



<div id="autoHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 8px;"><span class="onlinestrap"><a href="http://online.wsj.com/autos?mod=hpp_us_autos">AUTOS</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/autos?mod=hpp_us_autos">
								more
							</a></span></div><div style="margin-bottom: 6px;"><div style="float: left; padding-right: 4px;"><img src="us_files/it_auto-sedan.gif" style="width: 44px; height: 48px;"></div><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118495061500773150.html?mod=hpp_us_autos">Ford, Honda Cross Paths on SUV Sales</a><p>The
Honda CR-V recently became the best-selling SUV in the U.S., and its
ascent, along with the Ford Explorer's sales decline, reveals a lot
about why the American auto industry is in the shape it's in right now.</p></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118407591387562091.html?mod=hpp_us_autos">Comparing Ford's Small SUVs</a></div></div><div style="margin-bottom: 6px;"><div>
												&#8226;&nbsp;<a href="http://online.wsj.com/article/SB118479691781170823.html?mod=hpp_us_autos">Race-Worthy Laptops</a></div></div><div style="margin-bottom: 18px;"><span class="onlinehmore"><a href="http://online.wsj.com/autos?mod=hpp_us_autos">
							MORE
						</a></span></div></div>




<center>
	 
<div style="padding: 14px 0px 20px; text-align: center;">
 	
 	
<div style="text-align: center;" class="boldGreyNine">advertisement</div>
	
<span id="adSpanE"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';sz=230x192;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="adE" src="'+adURL+'" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230">';
} else {
  tempHTML += '<iframe id="adE" src="/static_html_files/blank.htm" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230px;">';
  ListOfIframes.adE= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';sz=230x192;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';sz=230x192;ord=4844484448444844;" border="0" width="230" height="192" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="adE" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 230px;" frameborder="0" height="192" scrolling="no" width="230">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us1;!category=;msrc=null;null;sz=230x192;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us1;!category=;msrc=null;null;sz=230x192;ord=4844484448444844;"
border="0" width="230" height="192" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</span>
</div>
</center>




<div id="cjHeadlines" style="border-top: 1px solid rgb(90, 135, 176); border-bottom: 1px solid rgb(90, 135, 176); margin: 0px 10px; width: 232px; padding-top: 8px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://www.careerjournal.com/?cjpartner=wsj_hpp" onclick="OpenWin('http://www.careerjournal.com?cjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">CareerJournal.com</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://www.careerjournal.com/?cjpartner=wsj_hpp" onclick="OpenWin('http://www.careerjournal.com?cjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
                  go to site
                </a></span></div><div style="float: left; padding-right: 4px;"><img src="us_files/it_briefcase2.gif" style="width: 44px; height: 48px;"></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.careerjournal.com/columnists/qanda/salaryissues/20070723-qandasalaryissues.html?mod=RSS_Career_Journal&amp;cjrss=frontpage&amp;cjpartner=wsj_hpp" onclick="OpenWin('http://www.careerjournal.com/columnists/qanda/salaryissues/20070723-qandasalaryissues.html?mod=RSS_Career_Journal&cjrss=frontpage&cjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">How Do You Tell Your Boss A Pay Raise Wasn't Adequate?</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.careerjournal.com/hrcenter/articles/20070723-wegert.html?mod=RSS_Career_Journal&amp;cjrss=frontpage&amp;cjpartner=wsj_hpp" onclick="OpenWin('http://www.careerjournal.com/hrcenter/articles/20070723-wegert.html?mod=RSS_Career_Journal&cjrss=frontpage&cjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Companies Beef Up Tech Security To Protect Against Internal Threats</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.careerjournal.com/jobhunting/change/20070723-gerencher.html?mod=RSS_Career_Journal&amp;cjrss=frontpage&amp;cjpartner=wsj_hpp" onclick="OpenWin('http://www.careerjournal.com/jobhunting/change/20070723-gerencher.html?mod=RSS_Career_Journal&cjrss=frontpage&cjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">The Pros and Cons of Launching A Home-Based Family Business</a><p></p></div><div style="margin-bottom: 15px;"><span class="onlinehmore"><a href="http://www.careerjournal.com/?cjpartner=wsj_hpp" onclick="OpenWin('http://www.careerjournal.com?cjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
              MORE
            </a></span></div><div style="margin-bottom: 20px;"><form id="jobSearchForm" target="jobSearchFormtarget" method="get" action="http://cj.careers.adicio.com/careers/jobsearch/results" onsubmit="return OpenWin('http://cj.careers.adicio.com/careers/jobsearch/results', 'jobSearchFormtarget');"><span style="padding-right: 3px;" class="searchheader">FIND A JOB</span><input name="kAndEntire" value="" size="15" max="75" class="p11" type="text"><input style="padding-left: 3px;" src="us_files/hprightarrow.gif" name="imageField" type="image" border="0" height="10" width="5"></form></div></div>



<div id="rjHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://www.realestatejournal.com/?rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com?rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">RealEstateJournal.com</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://www.realestatejournal.com/?rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com?rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
                  go to site
                </a></span></div><div style="float: left; padding-right: 4px;"><img src="us_files/it_cullen_home.gif" style="width: 44px; height: 48px;"></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.realestatejournal.com/buysell/taxesandinsurance/20070720-herman.html?mod=RSS_Real_Estate_Journal&amp;rejrss=frontpage&amp;rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com/buysell/taxesandinsurance/20070720-herman.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Why the IRS Is Showing Mercy To Some Home Sellers</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.realestatejournal.com/buysell/tactics/20070720-loeb.html?mod=RSS_Real_Estate_Journal&amp;rejrss=frontpage&amp;rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com/buysell/tactics/20070720-loeb.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">How to Save by Selling Your House Online</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.realestatejournal.com/buysell/markettrends/20070719-carrns.html?mod=RSS_Real_Estate_Journal&amp;rejrss=frontpage&amp;rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com/buysell/markettrends/20070719-carrns.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Investors Left Holding the Bag In a Land Project Gone Wrong</a><p></p></div><div style="margin-bottom: 15px;"><span class="onlinehmore"><a href="http://www.realestatejournal.com/?rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com?rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
              MORE
            </a></span></div><div style="margin-bottom: 20px;"><form id="homeSearchForm" target="homeSearchFormtarget" method="get" action="http://rej.careercast.com/properties/search/results.php" onsubmit="return OpenWin('http://rej.careercast.com/properties/search/results.php', 'homeSearchFormtarget');"><span style="padding-right: 3px;" class="searchheader">FIND A HOME</span><input name="qKeywords" value="" size="15" max="75" class="p11" type="text"><input style="padding-left: 3px;" src="us_files/hprightarrow.gif" name="imageField" type="image" border="0" height="10" width="5"><input name="qAction" value="search" type="hidden"><input name="qTerms" value="sell" type="hidden"></form></div></div>



<div id="ojHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://www.opinionjournal.com/?ojpartner=wsj_hpp" onclick="OpenWin('http://www.opinionjournal.com?ojpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">OpinionJournal.com</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://www.opinionjournal.com/?ojpartner=wsj_hpp" onclick="OpenWin('http://www.opinionjournal.com?ojpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
                  go to site
                </a></span></div><div style="float: left; padding-right: 4px;"><img src="us_files/it_q_a.gif" style="width: 44px; height: 48px;"></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.opinionjournal.com/editorial/?id=110010374&amp;mod=RSS_Opinion_Journal&amp;ojrss=frontpage&amp;ojpartner=wsj_hpp" onclick="OpenWin('http://www.opinionjournal.com/editorial/?id=110010374&mod=RSS_Opinion_Journal&ojrss=frontpage&ojpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Cheese Headcases</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.opinionjournal.com/columnists/bstephens/?id=110010375&amp;mod=RSS_Opinion_Journal&amp;ojrss=frontpage&amp;ojpartner=wsj_hpp" onclick="OpenWin('http://www.opinionjournal.com/columnists/bstephens/?id=110010375&mod=RSS_Opinion_Journal&ojrss=frontpage&ojpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Syria Occupies Lebanon. Again.</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.opinionjournal.com/la/?id=110010373&amp;mod=RSS_Opinion_Journal&amp;ojrss=frontpage&amp;ojpartner=wsj_hpp" onclick="OpenWin('http://www.opinionjournal.com/la/?id=110010373&mod=RSS_Opinion_Journal&ojrss=frontpage&ojpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Rowling Pulls It Off</a><p></p></div><div style="margin-bottom: 20px;"><span class="onlinehmore"><a href="http://www.opinionjournal.com/?ojpartner=wsj_hpp" onclick="OpenWin('http://www.opinionjournal.com?ojpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
              MORE
            </a></span></div></div>



<div id="sjHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://www.startupjournal.com/?sjpartner=wsj_hpp" onclick="OpenWin('http://www.startupjournal.com?sjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">StartupJournal.com</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://www.startupjournal.com/?sjpartner=wsj_hpp" onclick="OpenWin('http://www.startupjournal.com?sjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
                  go to site
                </a></span></div><div style="float: left; padding-right: 4px;"><img src="us_files/it_budget-shoestring.gif" style="width: 44px; height: 48px;"></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.startupjournal.com/franchising/franchising/20070723-debaise.html?mod=RSS_Startup_Journal&amp;sjrss=frontpage&amp;sjpartner=wsj_hpp" onclick="OpenWin('http://www.startupjournal.com/franchising/franchising/20070723-debaise.html?mod=RSS_Startup_Journal&sjrss=frontpage&sjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Profits on the Side: Charities and Franchises</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.startupjournal.com/runbusiness/survival/20070723-chernova.html?mod=RSS_Startup_Journal&amp;sjrss=frontpage&amp;sjpartner=wsj_hpp" onclick="OpenWin('http://www.startupjournal.com/runbusiness/survival/20070723-chernova.html?mod=RSS_Startup_Journal&sjrss=frontpage&sjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">When Disaster Strikes A Family Business</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.startupjournal.com/ideas/hitechonline/20070720-vascellaro.html?mod=RSS_Startup_Journal&amp;sjrss=frontpage&amp;sjpartner=wsj_hpp" onclick="OpenWin('http://www.startupjournal.com/ideas/hitechonline/20070720-vascellaro.html?mod=RSS_Startup_Journal&sjrss=frontpage&sjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Calling All Videos: New Cellphone Services</a><p></p></div><div style="margin-bottom: 20px;"><span class="onlinehmore"><a href="http://www.startupjournal.com/?sjpartner=wsj_hpp" onclick="OpenWin('http://www.startupjournal.com?sjpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
              MORE
            </a></span></div></div>



<div id="atdHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://www.allthingsd.com/?siteid=wsj_hpp_atd" onclick="OpenWin('http://www.allthingsd.com?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">AllThingsDigital.com</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://www.allthingsd.com/?siteid=wsj_hpp_atd" onclick="OpenWin('http://www.allthingsd.com?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">
                  go to site
                </a></span></div><div style="float: left; padding-right: 4px;"><img src="us_files/it_flatscreen.gif" style="width: 44px; height: 48px;"></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://feeds.allthingsd.com/%7Er/atd-feed/%7E3/136627947/?siteid=wsj_hpp_atd" onclick="OpenWin('http://feeds.allthingsd.com/~r/atd-feed/~3/136627947/?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">Tell Me Again How Third-party Apps Will &#8216;Extend iPhone&#8217;s Capabilities Without Compromising Its Reliability or Security&#8217; </a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://feeds.allthingsd.com/%7Er/atd-feed/%7E3/136618186/?siteid=wsj_hpp_atd" onclick="OpenWin('http://feeds.allthingsd.com/~r/atd-feed/~3/136618186/?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">iPhone to Support Third-Party Security Exploit Applications </a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://feeds.allthingsd.com/%7Er/atd-feed/%7E3/136526393/?siteid=wsj_hpp_atd" onclick="OpenWin('http://feeds.allthingsd.com/~r/atd-feed/~3/136526393/?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">A Talk With VCMike </a><p></p></div><div style="margin-bottom: 20px;"><span class="onlinehmore"><a href="http://www.allthingsd.com/?siteid=wsj_hpp_atd" onclick="OpenWin('http://www.allthingsd.com?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">
              MORE
            </a></span></div></div>



<div id="mwHeadlines" style="margin: 8px 10px 0px; width: 232px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp" onclick="OpenWin('http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">MarketWatch.com</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp" onclick="OpenWin('http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
                  go to site
                </a></span></div><div style="float: left; padding-right: 4px;"><img src="us_files/it_marketbeat.gif" style="width: 44px; height: 48px;"></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.marketwatch.com/enf/rss.asp?guid=%7BC90AB17A-BF68-42FE-BFEC-B5B27802D3DD%7D&amp;siteid=rss_wsj_hpp&amp;rss=1&amp;" onclick="OpenWin('http://www.marketwatch.com/enf/rss.asp?guid=%7BC90AB17A-BF68-42FE-BFEC-B5B27802D3DD%7D&siteid=rss_wsj_hpp&rss=1&', '', '911', '656', '', '', '59', '45', '');return false;">China, Hong Kong rise on earnings hopes</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.marketwatch.com/enf/rss.asp?guid=%7B9D9ACC6E-7675-4B87-8F83-03467F600984%7D&amp;siteid=rss_wsj_hpp&amp;rss=1&amp;" onclick="OpenWin('http://www.marketwatch.com/enf/rss.asp?guid=%7B9D9ACC6E-7675-4B87-8F83-03467F600984%7D&siteid=rss_wsj_hpp&rss=1&', '', '911', '656', '', '', '59', '45', '');return false;">Do you need long-term-care insurance?</a><p></p></div><div style="margin-bottom: 8px;">
                  &#8226;
				  <a href="http://www.marketwatch.com/enf/rss.asp?guid=%7BECAA3B5E-946C-4766-BF26-73E1EF8081BA%7D&amp;siteid=rss_wsj_hpp&amp;rss=1&amp;" onclick="OpenWin('http://www.marketwatch.com/enf/rss.asp?guid=%7BECAA3B5E-946C-4766-BF26-73E1EF8081BA%7D&siteid=rss_wsj_hpp&rss=1&', '', '911', '656', '', '', '59', '45', '');return false;">The stock market is acting tired</a><p></p></div><div style="margin-bottom: 20px;"><span class="onlinehmore"><a href="http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp" onclick="OpenWin('http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">
              MORE
            </a></span></div></div>

		</div>
	</div> 
<!-- End left column -->

	
<!-- Begin right column -->
	<div id="right_rr" style="float: left; width: 253px; background-color: rgb(242, 247, 251); height: 2057px;">
		<div style="margin: 0px; clear: left; width: 253px; background-color: rgb(242, 247, 251);">




	<div style="border-top: 1px solid rgb(154, 155, 155); border-bottom: 2px solid rgb(154, 155, 155); height: 20px; width: 253px;">
	<div class="f2dayColHedNew" style="border-bottom: 1px solid rgb(154, 155, 155); padding-top: 2px; height: 16px; width: 253px;">
		<span style="padding-left: 10px; vertical-align: middle;">ONLINE EXCLUSIVES</span>&nbsp;&nbsp;<img src="us_files/hpdownarrow.gif" alt="" border="0" height="4" width="7">
	</div>
</div>



<div xmlns:content="http://purl.org/rss/1.0/modules/content/" id="otprHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px; width: 233px;"><div class="onlinestrap"><a href="http://blogs.wsj.com/onlinetoday?mod=hpp_us_online_today">ONLINE TODAY FOR PRINT READERS</a></div><div style="margin-top: 10px;"><div style="padding: 0px; margin-top: 8px;">
									&#8226;&nbsp;<span class="p11"><a href="http://feeds.wsjonline.com/%7Er/wsj/onlinetoday/feed/%7E3/136727720/?mod=hpp_us_online_today">Links for Tuesday&#8217;s paper, July 24</a></span></div><div style="padding: 0px; margin-top: 8px;">
									&#8226;&nbsp;<span class="p11"><a href="http://feeds.wsjonline.com/%7Er/wsj/onlinetoday/feed/%7E3/136727721/?mod=hpp_us_online_today">Page One Extras for Tuesday&#8217;s paper, July 24</a></span></div><div style="padding: 0px; margin-top: 8px;">
									&#8226;&nbsp;<span class="p11"><a href="http://feeds.wsjonline.com/%7Er/wsj/onlinetoday/feed/%7E3/136727722/?mod=hpp_us_online_today">Online Exclusives for Tuesday, July 24</a></span></div><div style="padding: 0px; margin-top: 8px;"></div><div style="padding: 0px; margin-top: 8px;"></div><div style="padding: 0px; margin-top: 8px;"></div><div style="padding: 0px; margin-top: 8px;"></div><div style="padding: 0px; margin-top: 8px;"></div><div style="padding: 0px; margin-top: 8px;"></div><div style="padding: 0px; margin-top: 8px;"></div></div><div class="regtext">View 
						<span class="p11"><a href="http://online.wsj.com/public/page/us_in_todays_paper.html?mod=hpp_us_online_today">
							Today's Print Headlines
						</a></span></div><div style="margin-bottom: 20px;" class="regtext">View 
						<span class="p11"><a href="http://online.wsj.com/public/article/SB116716548881759827.html?mod=hpp_us_online_today">
							Tables from the Print Edition
						</a></span></div></div>




	

<div style="border-bottom: 1px solid rgb(90, 135, 176); margin: 0px 6px; width: 233px;">
	<div style="margin: 0px 0px 10px;">
		<span class="onlinestrap"><a href="javascript:OpenWin('/video?mod=hpp_us_video_promo','videoplayer',993,529,'off',true,0,0,true);void('')">VIDEO CENTER</a></span>
		<span class="onlinepipe">&nbsp;|&nbsp;</span>
		<span class="onlinehmore"><a href="javascript:OpenWin('/video?mod=hpp_us_video_promo','videoplayer',993,529,'off',true,0,0,true);void('')">more</a></span>					
	</div>
	<div id="vTabC" style="height: 17px;"><a onmouseover="com.dowjones.videoPlayer.scrollTab(false)" onmouseout="window.clearTimeout(com.dowjones.videoPlayer.myTimer)" style="float: left;" class="vTabN"><img style="margin: 3px 3px 2px 0px; cursor: pointer;" src="us_files/hpmdcleftarrow.gif" alt="" border="0" height="8" width="4"></a><div id="vTabList" style="margin: 0px; padding: 0px; overflow: hidden; float: left; width: 194px; height: 17px;"><table border="0" cellpadding="0" cellspacing="0"><tbody><tr><td id="vTabListContainer" height="17" nowrap="nowrap" valign="middle"><a href="http://online.wsj.com/public/page/8_0006.html?bclid=86272812&amp;mod=hpp_us_video_promo" onclick="com.dowjones.videoPlayer.changeTab(this,0);return false" class="vTabS">News/Analysis</a><a href="http://online.wsj.com/public/page/8_0006.html?bclid=132209461&amp;mod=hpp_us_video_promo" onclick="com.dowjones.videoPlayer.changeTab(this,1);return false" class="vTabN">Pursuits</a><a href="http://online.wsj.com/public/page/8_0006.html?bclid=212338097&amp;mod=hpp_us_video_promo" onclick="com.dowjones.videoPlayer.changeTab(this,2);return false" class="vTabN">Opinion</a><a href="http://online.wsj.com/public/page/8_0006.html?bclid=1078608424&amp;mod=hpp_us_video_promo" onclick="com.dowjones.videoPlayer.changeTab(this,3);return false" class="vTabN">Deals Conference</a><a href="http://online.wsj.com/public/page/8_0006.html?bclid=823355447&amp;mod=hpp_us_video_promo" onclick="com.dowjones.videoPlayer.changeTab(this,4);return false" class="vTabN">Most Popular </a></td></tr></tbody></table></div><a style="float: left;" class="vTabN" onmouseover="com.dowjones.videoPlayer.scrollTab(true)" onmouseout="window.clearTimeout(com.dowjones.videoPlayer.myTimer)"><img style="margin: 3px 3px 2px 0px; cursor: pointer;" src="us_files/hpmdcrightarrow.gif" alt="" border="0" height="8" width="4"></a></div>
	<div style="border-left: 1px solid rgb(204, 204, 204); border-right: 1px solid rgb(204, 204, 204); border-bottom: 0px solid rgb(204, 204, 204); background: rgb(255, 255, 255) none repeat scroll 0%; width: 231px; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;">
		<iframe id="videoPlayer" src="us_files/hpBrightcovePlayer.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#b6b6b8" style="border: 1px solid rgb(182, 182, 184); margin: 6px 6px 0px; overflow: hidden; width: 217px; height: 263px;" frameborder="0" height="263" scrolling="no" width="217"></iframe>
	</div>
	<div style="border-left: 1px solid rgb(204, 204, 204); border-right: 1px solid rgb(204, 204, 204); border-bottom: 1px solid rgb(204, 204, 204); background: rgb(255, 255, 255) none repeat scroll 0%; width: 231px; margin-bottom: 20px; -moz-background-clip: -moz-initial; -moz-background-origin: -moz-initial; -moz-background-inline-policy: -moz-initial;">
		<div style="margin: 0px 10px;">
			<div class="p11" id="vTitle" style="padding-top: 18px;"><a class="unvisited bold" href="http://online.wsj.com/public/page/8_0006.html?bclid=86272812&amp;bctid=1121359175&amp;mod=hpp_us_video_promo" onclick="OpenWin('/public/page/8_0006.html?bclid=86272812&bctid=1121359175&mod=hpp_us_video_promo','videoplayer',993,540,'off',true,0,0,true);return false">Barclays Receives Funding for ...</a></div>
			<div class="p11" id="vText" style="margin: 0px 0px 12px;">Robert Diamond, president of Barclays, discusses the cash infusion the bank...</div>
			<div class="p10" style="margin: 0px 0px 10px;"><a href="javascript:OpenWin('/video?mod=hpp_us_video_promo','videoplayer',993,529,'off',true,0,0,true);void('')" class="unvisited">SEE ALL VIDEO OFFERINGS</a></div>

		</div>
	</div>
</div>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
com.dowjones.videoPlayer={
	lineups:[],
	oldLineup:null,
	myTimer:null,
	scrollTab:function(forward){
		window.clearTimeout(this.myTimer)
		if(forward){
			$('vTabList').scrollLeft+=1
			if($('vTabList').scrollLeft+$('vTabList').offsetWidth<$('vTabList').scrollWidth){
				this.myTimer=window.setTimeout("com.dowjones.videoPlayer.scrollTab(true)", 5);
			}
		} else {
			$('vTabList').scrollLeft-=1
			if($('vTabList').scrollLeft>0){
				this.myTimer=window.setTimeout("com.dowjones.videoPlayer.scrollTab(false)", 5);
			}
		}
	},
	drawLineups:function(){
		var o='<a onmouseover="com.dowjones.videoPlayer.scrollTab(false)" onmouseout="window.clearTimeout(com.dowjones.videoPlayer.myTimer)" style="float:left;" class="vTabN"><img style="margin:3px 3px 2px 0px; cursor:pointer;" src="/img/hpmdcleftarrow.gif" width="4" height="8" alt="" border="0"/></a>'
		o+='<div id="vTabList" style="overflow:hidden;margin:0px;padding:0px;float:left;width:194px;height:17px;"><table border="0" cellpadding="0" cellspacing="0"><tr><td nowrap="nowrap" valign="middle" height="17" id="vTabListContainer">'
		for(var l=0;l<this.lineups.length;l++){
			var bclid=""
			try{
				bclid=this.lineups[l].id
			} catch(ex) {}
			var href=((loggedIn)?'':'/public')+'/page/8_0006.html?bclid='+bclid+'&mod=hpp_us_video_promo'
			o+='<a href="'+href+'" onclick="com.dowjones.videoPlayer.changeTab(this,'+l+');return false" class="vTab'+((l==0)?'S':'N')+'">'+com.dowjones.videoPlayer.lineups[l].title+'</a>'
		}
		o+='</td></tr></table></div><a style="float:left;" class="vTabN" onmouseover="com.dowjones.videoPlayer.scrollTab(true)" onmouseout="window.clearTimeout(com.dowjones.videoPlayer.myTimer)"><img style="margin:3px 3px 2px 0px;cursor:pointer;" src="/img/hpmdcrightarrow.gif" width="4" height="8" alt="" border="0" /></a>'
		$('vTabC').innerHTML=o
	},
	changeTab:function(n,i){
		if(this.oldLineup!=null){
			this.oldLineup.className='vTabN'
		}
		
		if(n!=null){
			this.oldLineup=n
			n.className='vTabS'
		}
		var bclid="",bctid=""
		try{
			bclid=this.lineups[i].id
			bctid=this.lineups[i].list[0].id
		} catch(ex) {}
		var href=((loggedIn)?'':'/public')+'/page/8_0006.html?bclid='+bclid+'&bctid='+bctid+'&mod=hpp_us_video_promo'
		var onclick='OpenWin(\''+((loggedIn)?'':'/public')+'/page/8_0006.html?bclid='+bclid+'&bctid='+bctid+'&mod=hpp_us_video_promo'+'\',\'videoplayer\',993,540,\'off\',true,0,0,true);return false'
$('vTitle').innerHTML='<a class="unvisited bold" href="'+href+'" onclick="'+onclick+'">'+((this.lineups[i].list[0].title.length>30)?this.lineups[i].list[0].title.substring(0,30).concat('...'):this.lineups[i].list[0].title)+'</a>'	
$('vText').innerHTML=(this.lineups[i].list[0].description.length>75)?this.lineups[i].list[0].description.substring(0,75).concat('...'):this.lineups[i].list[0].description	
$('videoPlayer').src="/static_html_files/hpBrightcovePlayer.htm?bctid="+this.lineups[i].list[0].id
	},
	init:function(){
		this.drawLineups()
		this.changeTab($('vTabListContainer').childNodes[0],0)
	}

}
//-->
</script>

<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
document.write('<'+'s'+'c'+'r'+'i'+'p'+'t s'+'r'+'c'+'="/public/resources/documents/hpVideoLineups.'+'j'+'s'+'?a='+GenRandomNum()+'"'+'>'+'<'+'/'+'s'+'c'+'r'+'i'+'p'+'t'+'>')
// -->
</script><script src="us_files/hpVideoLineups.js"></script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
com.dowjones.videoPlayer.init()
//-->
</script>




<div id="mpbHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 10px; width: 233px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://online.wsj.com/public/page/8_0019.html?mod=hpp_us_blogs">BLOGS</a></span><span style="">&nbsp;|&nbsp;</span><span class="onlinemore"><a href="http://online.wsj.com/public/page/8_0019.html?mod=hpp_us_blogs">more</a></span></div><div><div style="padding-bottom: 1px;"><span style="text-transform: uppercase;" class="blogtitle">Economics Blog </span><span class="blogdate"> 10:53 pm</span></div><div style="padding-bottom: 14px;" class="p11"><a href="http://blogs.wsj.com/economics/2007/07/23/a-code-of-conduct-for-sovereign-wealth-funds/?mod=hpp_us_blogs"> A Code of Conduct for Sovereign Wealth Funds</a></div></div><div><div style="padding-bottom: 1px;"><span style="text-transform: uppercase;" class="blogtitle">Washington Wire </span><span class="blogdate"> 9:54 pm</span></div><div style="padding-bottom: 14px;" class="p11"><a href="http://blogs.wsj.com/washwire/2007/07/23/what-i-like-about-you/?mod=hpp_us_blogs"> What I Like About You</a></div></div><div><div style="padding-bottom: 1px;"><span style="text-transform: uppercase;" class="blogtitle">Whosnews Blog </span><span class="blogdate"> 7:27 pm</span></div><div style="padding-bottom: 14px;" class="p11"><a href="http://blogs.wsj.com/whosnews/2007/07/23/wilmer-cutler-pickering-hale-dorr-llp-5/?mod=hpp_us_blogs"> Wilmer Cutler Pickering Hale &amp; Dorr LLP</a></div></div><div><div style="padding-bottom: 1px;"><span style="text-transform: uppercase;" class="blogtitle">Business Technology </span><span class="blogdate"> 7:20 pm</span></div><div style="padding-bottom: 14px;" class="p11"><a href="http://blogs.wsj.com/biztech/2007/07/23/a-lesson-from-the-harry-potter-leakers-mistake-2/?mod=hpp_us_blogs"> Learn from the Harry Potter Leaker&#8217;s Mistake</a></div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div></div><div style="margin-bottom: 18px;"><span style="padding-right: 3px;" class="p11">GO TO</span><select class="p11" onchange="(this.options[this.options.selectedIndex].value!='')?window.location='http://blogs.wsj.com/'+this.options[this.options.selectedIndex].value+'?mod=hpp_us_blogs':void('')"><option value="">- Choose a Blog -</option><option value="deals">Deal Journal</option><option value="energy">Energy Roundup</option><option value="health">Health Blog</option><option value="informedreader">Informed Reader</option><option value="juggle">Juggle</option><option value="law">Law Blog</option><option value="marketbeat">Market Beat</option><option value="numbersguy">The Numbers Guy</option><option value="washwire">Washington Wire</option><option value="wealth">Wealth Report</option><option value="whosnews">Who's News</option></select></div></div>



<div id="intHeadlines" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 8px 10px 0px; width: 233px;"><div style="margin: 0px 0px 8px;"><span class="onlinestrap"><a href="http://online.wsj.com/public/page/2_1077.html?mod=hpp_us_interactives">INTERACTIVES</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/public/page/2_1077.html?mod=hpp_us_interactives">
								more
							</a></span></div><div style="margin: 0px 0px 8px;" class="substrap">ANALYSIS OF NEWS AND TRENDS</div><div style="margin-bottom: 6px;"><div style="float: left; padding-right: 4px;"><img src="us_files/it_interactives.gif" style="width: 44px; height: 48px;"></div><div>
													&#8226;&nbsp;
												<a class="bold" href="javascript:OpenG('/public/resources/documents/info-flash08.html?project=POTTER07');void('')">Harry Potter and the Fantastic Franchise:</a>
The stories of Harry Potter spawned a world-wide sales juggernaut. Read
more on the business, see film clips and read reviews. Plus, see <a class="bold" href="javascript:OpenWin('/article/SB118494499893273109.html?mod=us_business_big_story_hs','infogrfx',760,524,'off',1,0,0,1);void('')">photos of fans</a> waiting to buy "Harry Potter and the Deathly Hallows." <i>07/20/2007</i></div></div><div style="margin-bottom: 6px;"><div></div></div><div style="margin-bottom: 6px;"><div></div></div><div style="margin-bottom: 18px;"><span class="onlinehmore"><a href="http://online.wsj.com/public/page/2_1077.html?mod=hpp_us_interactives">
							MORE
						</a></span></div></div>



<div xmlns:content="http://purl.org/rss/1.0/modules/content/" id="" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 10px 10px 0px; width: 233px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://online.wsj.com/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos" onclick="OpenWin('/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos','infogrfx',760,524,'off',1,0,0,1);return false;">
					TODAY'S WSJ IN PHOTOS
				</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos" onclick="OpenWin('/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos','infogrfx',760,524,'off',1,0,0,1);return false;">				
			    	more
				</a></span></div><div style="border: 1px solid rgb(204, 204, 204); width: 231px; background-color: rgb(255, 255, 255); margin-bottom: 20px;"><div style="margin: 10px 10px 2px; overflow: hidden; width: 211px;"><a class="bold" href="javascript:OpenWin('/article/SB118524096951275757.html','infogrfx',760,524,'off',1,0,0,1);void('')" onclick="JavaScript:OpenWin('/article/SB118524096951275757.html','infogrfx',760,524,'off',1,0,0,1);void('');return false;"><img src="us_files/OB-AN286_FREETO_20070723215939.jpg" alt="photos" class="imgitboxLEFT" padding="0px" align="left" border="0" height="158" width="211"></a></div><div style="border-top: 1px solid rgb(0, 0, 0); margin: 0px 10px 10px; width: 211px; font-size: 11px; padding-top: 2px;"><span class="phototext">Lockheed was besieged with requests to add features to Marine One...
						</span><span class="pb11"><a href="http://online.wsj.com/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos" onclick="OpenWin('/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos','infogrfx',760,524,'off',1,0,0,1);return false;">
						more
					</a></span></div></div></div>



<script>
<!--
var FORMSJSON ={data:{d:"",t:"",p:"",s:""},callback:function(){}};
FORMSJSON.data={d:"http://forums.wsj.com",p:"26891",t:"650",s:"Are you doing the kind of work you envisioned as your career when you were in college?"};FORMSJSON.callback();
//-->
</script>




	<div id="qodForums" style="border-bottom: 1px solid rgb(90, 135, 176); margin: 0px 10px 10px; width: 233px;">
	<div style="margin: 10px 0pt 10px 0px;">
		<span class="onlinestrap">
			<a href="http://forums.wsj.com/?mod=hpp_us_forums" class="onlinestrap">FORUMS</a>
		</span>
		<span class="onlinepipe">&nbsp;|&nbsp;</span>
		<span class="onlinehmore">
			<a href="http://forums.wsj.com/?mod=hpp_us_forums">more</a>
		</span>
	</div>
	<div class="bsubstrap" style="margin: 0px 0pt 10px 0px; clear: both;">Question of the Day:</div>
	<div id="qodForumsContent"><div style="margin: 0px 10px 0px 0px;"><a href="http://forums.wsj.com/viewtopic.php?mod=hpp_us_forums&amp;t=650" target="wsjDiscussions">Are you doing the kind of work you envisioned as your career when you were in college?</a></div><div style="margin: 0px 0px 0px 19px;"><form name="pollForm2" action="" method=""><table border="0" cellpadding="0" cellspacing="0"><tbody><tr><td><input value="1" name="pollChoices" id="pollChoice1" type="radio"></td><td><label for="pollChoice1">Yes</label></td></tr><tr><td><input value="2" name="pollChoices" id="pollChoice2" type="radio"></td><td><label for="pollChoice2">No</label></td></tr><tr><td><input value="3" name="pollChoices" id="pollChoice3" type="radio"></td><td><label for="pollChoice3">I didn't know what I wanted to do when I was in college.</label></td></tr></tbody></table></form></div><div style="margin: 17px 0px 0px;" align="center"><form action="" method="" onsubmit="submitPoll();return false" name="pollForm"><input class="p11" style="margin: 0px 15px 0px 0px;" value="Submit" type="submit"><input class="p11" value="View Results" onclick="OpenWin('http://forums.wsj.com/viewpoll_result.php?t=650&postdays=0&postorder=asc&vote=viewresult', '_blank')" type="button"></form></div></div>
	<div style="margin-top: 17px; margin-bottom: 20px;">
	<span class="p11">GO TO</span> 
	<select class="p11" onchange="(this.options[this.options.selectedIndex].value!='')?window.location='http://forums.wsj.com/viewforum.php?mod=hpp_us_forums&f='+this.options[this.options.selectedIndex].value:void('')">
		<option value="">- Choose a Forum -</option>

		<option value="2">Question of the Day</option>
		<option value="12">Act One</option>
		<option value="17">Business Insight</option>
		<option value="9">Capital Exchange</option>
		<option value="6">The Doctor's Office</option>
		<option value="11">The Expat Life</option>

		<option value="4">Fiscally Fit</option>
		<option value="14">Health Journal</option>
		<option value="13">In The Lead</option>
		<option value="16">Lifelines</option>
		<option value="7">Making the Grade</option>
		<option value="15">Middle Seat</option>

		<option value="10">The Outbox</option>
		<option value="19">Small Business Link</option>
		<option value="8">Talking Business</option>
		<option value="5">Special Features</option>
		<option value="3">Numbers Guy</option>
	</select>

	</div>

</div>
<script>
var forumsCookieName = ""
if(loggedIn){
	forumsCookieName+=userName
}
forumsCookieName+="FORUMSPOST"
function submitPoll(){
  if(PollJSON.postingAllowed){
    var answer = 0;
    for(var a=0;a<document.pollForm2.pollChoices.length;a++){
      if(document.pollForm2.pollChoices[a].checked){
        answer=(a+1);
      }
    }
    if(answer>0){
      SetCookie(forumsCookieName+FORMSJSON.data.t,answer,'12m+','/','.wsj.com');
      PollJSON.postingAllowed=false;
      var u =''+FORMSJSON.data.d+'/votenview.php?t='+FORMSJSON.data.t+'&topic_id='+FORMSJSON.data.t+'&mode=vote&vote_id='+answer;
      OpenWin(u,'pollWin');
      forumsTimer=setTimeout('$import(\''+FORMSJSON.data.d+'/pollinfo.php?topic_id='+FORMSJSON.data.t+'\',\'poll\')',3*1000);
    } else {
      alert("Select one of the choices before casting your vote.");
    }
  } else {
    alert("You have already submitted your vote!");
  }
}
var forumsTimer = null
var PollJSON={
	postingAllowed:(GetCookie(forumsCookieName+FORMSJSON.data.t)?false:true),
	data:null,
	callback:function(){
		window.clearTimeout(forumsTimer);
		var tempHTML='';
		var vurl = '';
		if(this.postingAllowed){
			vurl += FORMSJSON.data.d+'/viewpoll_result.php?t='+FORMSJSON.data.t+'&postdays=0&postorder=asc&vote=viewresult';
			tempHTML+='<div style="margin:0px 10px 0px 0px"><a href="'+FORMSJSON.data.d+'/viewtopic.php?mod=hpp_us_forums&t='+FORMSJSON.data.t+'" target="wsjDiscussions">'+this.data.headline+'</a></div>'
			tempHTML+='<div style="margin:0px 0px 0px 19px"><form name="pollForm2" action="" method=""><table border="0px" cellpadding="0px" cellspacing="0px">'
			for(var c=0;c<this.data.choices.length;c++){
				tempHTML+='<tr><td><input type="radio" value="'+(c+1)+'" name="pollChoices" id="pollChoice'+(c+1)+'"></td><td><label for="pollChoice'+(c+1)+'">'+this.data.choices[c]+'</label></td></tr>'
			}
			tempHTML+='</table></form></div>'
			tempHTML+='<div style="margin:17px 0px 0px 0px" align="center"><form action="" method="" onsubmit="submitPoll();return false" name="pollForm"><input class="p11" type="submit" style="margin:0px 15px 0px 0px" value="Submit"/><input class="p11" type="button" value="View Results" onclick="OpenWin(\''+vurl+'\', \'_blank\')"/></form></div>'
		} else {
			tempHTML+='<div><a href="'+FORMSJSON.data.d+'/viewtopic.php?t='+FORMSJSON.data.t+'" target="wsjDiscussions">'+this.data.headline+'</a></div>'
			tempHTML+='<table border="0" cellpadding="0" cellspacing="0">'
			
			for(var c=0;c<this.data.choices.length;c++){
				tempHTML+='<tr><td style="padding-left:15px;" align="right" valign="top">'+this.data.vote[c][0]+' vote'+((this.data.vote[c][0]>1)?'s':'')+'</td><td style="padding-left:3px;" align="right" valign="top">('+this.data.vote[c][1]+'%)</td><td valign="top">&nbsp;&nbsp;</td><td><label for="pollChoice'+(c+1)+'">'+this.data.choices[c]+'</label></td></tr>'
			}
			tempHTML+='</table>'
		}
		$('qodForumsContent').innerHTML=tempHTML
	}
}
</script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
document.write('<'+'script src="'+FORMSJSON.data.d+'/pollinfo.php?topic_id='+FORMSJSON.data.t+'"'+'>'+'<'+'/script'+'>')
//-->
</script><script src="us_files/pollinfo.html"></script>



<div id="podcasts" style="margin: 8px 10px 0px; width: 233px;"><div style="margin: 0px 0px 10px;"><span class="onlinestrap"><a href="http://online.wsj.com/public/page/0_0813.html?mod=hpp_us_podcasts">
				PODCASTS &amp; RSS
			</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/public/page/0_0813.html?mod=hpp_us_podcasts">
				more
			</a></span></div><div class="bsubstrap" style="margin: 10px 0px;">
				FEATURED PODCAST
		</div><div style="float: left;"><img src="us_files/it_podcast.gif" style="width: 44px; height: 48px;"></div><div><div class="regtext"><div>&#8226;&nbsp;<a class="bold" href="http://podcast.mktw.net/wsj/audio/20070723/pod-wsjhome/pod-wsjhome.mp3"><span style="">Home Front:</span></a> Cracking down on lawn watering. Plus, WSJ's Jared Sandberg discusses what our kids think we do for a living.</div></div></div><div style="margin: 15px 0px 4px;"><span class="bsubstrap"><a href="http://online.wsj.com/public/page/0_0813.html?mod=hpp_us_podcasts">
				RSS NEWS FEEDS
			</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="http://online.wsj.com/public/page/0_0813.html?mod=hpp_us_podcasts">
				MORE
			</a></span></div><script charset="ISO-8859-1" src="us_files/rssSelector.js" language="javascript" type="text/javascript"></script><div class="p11" style="padding-bottom: 3px;"><img alt="Get RSS" src="us_files/feed-icon.gif" style="vertical-align: middle;" border="0"><span class="black">&nbsp;Get Feed U.S.:&nbsp;</span><a onclick="com.dowjones.utils.rssSelector.show(this);return false" href="http://online.wsj.com/xml/rss/3_7011.xml" class="unvisited">What's News</a></div><div class="p11" style="margin-bottom: 20px;"><img alt="Get RSS" src="us_files/feed-icon.gif" style="vertical-align: middle;" border="0"><span class="black">&nbsp;Get Feed U.S.:&nbsp;</span><a onclick="com.dowjones.utils.rssSelector.show(this);return false" href="http://online.wsj.com/xml/rss/3_7014.xml" class="unvisited">Business</a></div></div>




<center>
	 
<div style="padding: 0px 0px 14px; text-align: center;">
 	
 	
<div style="text-align: center;" class="boldGreyNine">advertisement</div>
	
<span id="adSpanF"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us2;!category=;msrc=' + msrc + ';' + segQS + ';sz=230x192;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="adF" src="'+adURL+'" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230">';
} else {
  tempHTML += '<iframe id="adF" src="/static_html_files/blank.htm" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230px;">';
  ListOfIframes.adF= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us2;!category=;msrc=' + msrc + ';' + segQS + ';sz=230x192;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us2;!category=;msrc=' + msrc + ';' + segQS + ';sz=230x192;ord=4844484448444844;" border="0" width="230" height="192" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="adF" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 230px;" frameborder="0" height="192" scrolling="no" width="230">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us2;!category=;msrc=null;null;sz=230x192;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us2;!category=;msrc=null;null;sz=230x192;ord=4844484448444844;"
border="0" width="230" height="192" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</span>
</div>
</center>


		</div>
	</div> 
<!-- End right column -->
	

	
<!-- Begin column 4 -->
	<div style="clear: both; text-align: center;">
		







	</div>
<!-- End column 4 -->
	

	
  </div>	  
<!-- End body -->  









<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%">
	<tbody><tr><td height="20"><img src="us_files/b.gif" alt="" border="0" height="20" width="1"></td></tr>
</tbody></table>
<table style="border: 1px solid rgb(207, 199, 183); margin-bottom: 5px;" align="center" bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="0" width="507">
<tbody><tr>
<td colspan="2" class="b12" style="padding: 3px 0px;" bgcolor="#e9e7e0"><span class="p10" style="color: rgb(0, 0, 0); float: right;">An Advertising Feature&nbsp;&nbsp;</span>&nbsp;&nbsp;TRADING CENTER</td>
</tr>

<tr>
<td class="p10" style="border-right: 1px solid rgb(207, 199, 183); padding: 10px 0px 5px;" align="center" valign="top">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=1;sz=170x67;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter1" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter1" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter1= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=1;sz=170x67;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=1;sz=170x67;ord=4844484448444844;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="tradingcenter1" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 170px;" frameborder="0" height="67" scrolling="no" width="170">&lt;a
href="http://ad.doubleclick.net/jump/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=1;sz=170x67;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=1;sz=170x67;ord=4844484448444844;"
border="0" width="170" height="67" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</td>

<td class="p10" style="padding: 10px 0px 5px;" align="center" valign="top">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=2;sz=170x67;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter2" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter2" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter2= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=2;sz=170x67;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=2;sz=170x67;ord=4844484448444844;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="tradingcenter2" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 170px;" frameborder="0" height="67" scrolling="no" width="170">&lt;a
href="http://ad.doubleclick.net/jump/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=2;sz=170x67;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=2;sz=170x67;ord=4844484448444844;"
border="0" width="170" height="67" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</td>

</tr>

<tr>
<td class="p10" style="border-top: 1px solid rgb(207, 199, 183); border-right: 1px solid rgb(207, 199, 183); padding: 10px 0px 5px;" align="center" valign="top">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=3;sz=170x67;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter3" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter3" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter3= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=3;sz=170x67;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=3;sz=170x67;ord=4844484448444844;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="tradingcenter3" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 170px;" frameborder="0" height="67" scrolling="no" width="170">&lt;a
href="http://ad.doubleclick.net/jump/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=3;sz=170x67;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=3;sz=170x67;ord=4844484448444844;"
border="0" width="170" height="67" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</td>

<td class="p10" style="border-top: 1px solid rgb(207, 199, 183); padding: 10px 0px 5px;" align="center" valign="top">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=4;sz=170x67;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter4" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter4" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter4= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=4;sz=170x67;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=4;sz=170x67;ord=4844484448444844;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="tradingcenter4" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 170px;" frameborder="0" height="67" scrolling="no" width="170">&lt;a
href="http://ad.doubleclick.net/jump/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=4;sz=170x67;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=4;sz=170x67;ord=4844484448444844;"
border="0" width="170" height="67" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</td>

</tr>

<tr>
<td class="p10" style="border-top: 1px solid rgb(207, 199, 183); border-right: 1px solid rgb(207, 199, 183); padding: 10px 0px 5px;" align="center" valign="top">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=5;sz=170x67;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter5" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter5" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter5= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=5;sz=170x67;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=5;sz=170x67;ord=4844484448444844;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="tradingcenter5" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 170px;" frameborder="0" height="67" scrolling="no" width="170">&lt;a
href="http://ad.doubleclick.net/jump/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=5;sz=170x67;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=5;sz=170x67;ord=4844484448444844;"
border="0" width="170" height="67" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</td>

<td class="p10" style="border-top: 1px solid rgb(207, 199, 183); padding: 10px 0px 5px;" align="center" valign="top">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=6;sz=170x67;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter6" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter6" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter6= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=6;sz=170x67;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';tile=6;sz=170x67;ord=4844484448444844;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="tradingcenter6" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 170px;" frameborder="0" height="67" scrolling="no" width="170">&lt;a
href="http://ad.doubleclick.net/jump/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=6;sz=170x67;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/brokerbuttons.wsj.com/us_subscriber;!category=;msrc=null;null;tile=6;sz=170x67;ord=4844484448444844;"
border="0" width="170" height="67" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>
</td>

</tr>

</tbody></table>
<table bgcolor="" border="0" cellpadding="0" cellspacing="0" width="100%">
	<tbody><tr><td height="20"><img src="us_files/b.gif" alt="" border="0" height="20" width="1"></td></tr>
</tbody></table>

		</div>
	</div> 
<!-- End right column -->
	

	
<!-- Begin column 4 -->
	<div style="clear: both; text-align: center;">
		



	<img src="us_files/lb.gif" alt="" border="0" height="1" width="1">

	</div>
<!-- End column 4 -->
	

	
<!-- Begin footer -->
	<div class="p12" style="padding: 17px 0px 10px; clear: both; text-align: center;">

  		<a href="#top" class="unvisited">Return To Top</a>

  	 </div>
	<div style="border-top: 1px solid rgb(204, 204, 204); margin: 0pt 0pt 0pt 12px;">




<img src="us_files/b.gif" alt="" border="0" height="1" width="581">
<div class="pln75" style="padding-top: 19px; text-align: center;">
    <script type="text/javascript">
    <!--
    var tempHTML=''
    if(loggedIn){
      tempHTML+='<a href="'+nSP+'/logout" class="unvisited">Log Out</a>\n'
    } else {
      tempHTML+='<a href="http://online.wsj.com/reg/promo/text1_0107"  class="unvisited">Subscribe</a>\n'
      tempHTML+='&nbsp;\n'
      tempHTML+='<a href="'+nSP+'/login" class="unvisited">Log In</a>\n'
      tempHTML+='&nbsp;\n'
      tempHTML+='<a href="'+nSP+'/wsjgate?source=j2tourp&URI=/j2tour/welcome.html" onClick="OpenWin(this.href,\'mediatourpopup\',765,515,\'off\',true,18,23);return false" class="unvisited">Take a Tour</a>\n'
    }
    document.write(tempHTML)
    // -->
    </script><a href="http://online.wsj.com/reg/promo/text1_0107" class="unvisited">Subscribe</a>
&nbsp;
<a href="http://online.wsj.com/login" class="unvisited">Log In</a>
&nbsp;
<a href="http://online.wsj.com/wsjgate?source=j2tourp&amp;URI=/j2tour/welcome.html" onclick="OpenWin(this.href,'mediatourpopup',765,515,'off',true,18,23);return false" class="unvisited">Take a Tour</a>

    &nbsp;
    <script type="text/javascript">
    <!--
    document.write('<a href="'+nSP+((loggedIn)?"":"/public")+'/page/contact_us.html" class="unvisited">Contact Us</a>')
    //--></script><a href="http://online.wsj.com/public/page/contact_us.html" class="unvisited">Contact Us</a>
    &nbsp;
    <script type="text/javascript">
    <!--
    document.write('<a href="'+nSP+'/wsjhelp/center" class="unvisited" onclick="OpenWin(this.href,\'help\',610,510,\'tool,scroll,resize\',true,153,40);return false;">Help</a>')
    // --></script><a href="http://online.wsj.com/wsjhelp/center" class="unvisited" onclick="OpenWin(this.href,'help',610,510,'tool,scroll,resize',true,153,40);return false;">Help</a>
    &nbsp;
    <script type="text/javascript">
    <!--
    document.write('<a href="'+nSP+'/email" class="unvisited">Email Setup</a>')
    // --></script><a href="http://online.wsj.com/email" class="unvisited">Email Setup</a>
    &nbsp;
    <script type="text/javascript">
    <!--
    if(loggedIn){;document.write('<a href="'+nSP+'/acct/setup_account" class="unvisited">My Account/Billing</a>&nbsp;')}
    // --></script>
    <span class="p12" style="color: rgb(51, 51, 51);">Customer Service:</span>
    <script type="text/javascript"><!--
		document.write('<a href="'+nSP+((loggedIn)?"":"/public")+'/page/0_0809.html?page=0_0809" class="unvisited">Online</a>')
		// --></script><a href="http://online.wsj.com/public/page/0_0809.html?page=0_0809" class="unvisited">Online</a>
    <span class="p12">|</span>
    <script type="text/javascript">
    <!--
    document.write('<a href="'+((pID=="0_0013"||pID=="0_0003"||pID=="2_0003")?"http://www.europesubs.wsj.com/":((pID=="0_0014"||pID=="0_0004"||pID=="2_0004")?"https://www.awsj.com.hk/awsj2/?source=PWSHE4ECHR1N":"http://services.wsj.com"))+'" class="unvisited">Print</a>')
    // --></script><a href="http://services.wsj.com/" class="unvisited">Print</a>
</div>
<div class="pln75" style="padding-top: 8px; text-align: center;">
    <script type="text/javascript">
    <!--
      document.write('<a href="'+nSP+'/public/page/privacy_policy.html" class="unvisited">Privacy Policy</a>')
    // --></script><a href="http://online.wsj.com/public/page/privacy_policy.html" class="unvisited">Privacy Policy</a>
    &nbsp;
    <script type="text/javascript">
    <!--
      document.write('<a href="'+nSP+'/public/page/subscriber_agreement.html" class="unvisited">Subscriber Agreement & Terms of Use</a>')
    // --></script><a href="http://online.wsj.com/public/page/subscriber_agreement.html" class="unvisited">Subscriber Agreement &amp; Terms of Use</a>
    &nbsp;
    <script type="text/javascript">
    <!--
      document.write('<a href="http://mobile.wsj.com" class="unvisited">Mobile Devices</a>')
    // --></script><a href="http://mobile.wsj.com/" class="unvisited">Mobile Devices</a>
    &nbsp;
    <script type="text/javascript">
     <!--  
       document.write('<a href="'+nSP+((loggedIn)?"":"/public")+'/page/0_0813.html" class="unvisited">RSS Feeds</a>')
    // --></script><a href="http://online.wsj.com/public/page/0_0813.html" class="unvisited">RSS Feeds</a>
</div>
<div class="pln75" style="padding-top: 8px; text-align: center;">   
    &nbsp;
    <a href="http://public.wsj.com/partner" class="unvisited">News Licensing</a>
    &nbsp;
    <a href="http://www.dowjonesonline.com/" class="unvisited">Advertising</a>
    &nbsp;
    <a href="http://www.dj.com/" class="unvisited">About Dow Jones</a>
</div>
<div class="pln75" style="padding-top: 8px; text-align: center;">
    <script type="text/javascript">
    <!--
    var dO=new Date()
    if(pStl.substring(0,2)=="3_"||pStl.indexOf("article")>-1){
      document.write('<a class="unvisited" href="#" onclick="CopyrightPopUp();return false">Copyright &#169; '+((dO.getYear()>1900)?dO.getYear():(dO.getYear()+1900))+' Dow Jones & Company, Inc. All Rights Reserved</a></font>')
    } else {
      document.write('<a class="unvisited" href="http://www.djreprints.com">Copyright &#169; '+((dO.getYear()>1900)?dO.getYear():(dO.getYear()+1900))+' Dow Jones & Company, Inc. All Rights Reserved</A></font>')
    }
    // -->
    </script><a class="unvisited" href="http://www.djreprints.com/">Copyright © 2007 Dow Jones &amp; Company, Inc. All Rights Reserved</a>
</div>
<div style="padding-top: 8px; text-align: center;"><img src="us_files/wj00g18.gif" alt="DowJones" border="0" height="19" width="78"></div>

</div>
<!-- End footer -->
	
  </div>	  
<!-- End body -->  

</div>
<!-- End content -->











<!-- Begin 1x1 Code -->
<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=1x1;ord=4844484448444844;';
if ( isSafari ) {
  tempHTML += '<iframe id="adO" src="'+adURL+'" width="1" height="1" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:1">';
} else {
  tempHTML += '<iframe id="adO" src="/static_html_files/blank.htm" width="1" height="1" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:1px;">';
  ListOfIframes.adO= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=1x1;ord=4844484448444844;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';sz=1x1;ord=4844484448444844;" border="0" width="1" height="1" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script><iframe id="adO" src="us_files/blank_015.html" marginwidth="0" marginheight="0" hspace="0" vspace="0" bordercolor="#000000" style="width: 1px;" frameborder="0" height="1" scrolling="no" width="1">&lt;a
href="http://ad.doubleclick.net/jump/interactive.wsj.com/us;!category=;msrc=null;null;sz=1x1;ord=4844484448444844;"
target="_new"&gt;&lt;img
src="http://ad.doubleclick.net/ad/interactive.wsj.com/us;!category=;msrc=null;null;sz=1x1;ord=4844484448444844;"
border="0" width="1" height="1" vspace="0" alt="Advertisement"
/&gt;&lt;/a&gt;&lt;br /&gt;</iframe>

<!-- End 1x1 Code -->









<script type="text/javascript">
<!-- 
LoadIframes()
// -->
</script>





	  		<!-- START omniture_snippet_wsj_1.htm -->
<script type="text/javascript" src="us_files/s_code_wsj.js"></script><img src="us_files/s67084194444935.gif" name="s_i_djglobal" alt="" border="0" height="1" width="1">
<script type="text/javascript">
<!--
    s.channel = "Online Journal";

    var refresh = s.getQueryParam('refresh');
    if(!refresh){refresh = 'off'};
    var link = s.getQueryParam('mod');
    var reflink = s.getQueryParam('reflink');
    var targeturl = s.getQueryParam('url'); 
    if (reflink){
       link = "";
    }else if(link){
       reflink = "";
    }
    var fullurl = document.location.href;
    var baseurl = document.location.protocol+'//'+document.location.host+document.location.pathname;
    var caccess;
    caccess = "open";
    try {
      if(loggedIn){caccess = "subscriber";}
    } catch(err){}
    if(fullurl.indexOf('/PA2VJBNA4R')!=-1){caccess = "ppv";}
    if(fullurl.indexOf('/services/')!=-1){caccess = "print";}
    setMetaData('baseurl', baseurl);
    setMetaData('fullurl', fullurl);
    setMetaData('refresh', refresh);
    setMetaData('caccess', caccess);
    if(link){setMetaData('link', link);}
    if(reflink){setMetaData('reflink', reflink);}
    if(targeturl){setMetaData('targeturl', targeturl);} 
    try {
      setMetaData('numads', numads.toString());
      if(GetCookie('TR')){setMetaData('userid', GetCookie('TR'));}
      if(GetCookie("user_type") != 'subscribed'){
	setMetaData('asub', 'no');
      }else{
	setMetaData('asub', 'yes');
      }
    } catch(err){}
    /* END omniture_snippet_wsj_1.htm */

		setMetaData('csource','WSJ Online');			    
		setMetaData('displayname','U.S. Home');			    
		setMetaData('ctype','home page');			    
		setMetaData('primaryproduct','Online Journal');			    
		setMetaData('sitedomain','online.wsj.com');			    
		setMetaData('pagename','U.S. Home_0_0012');			    
		setMetaData('subsection','Home Page Public');			    
		setMetaData('section','Home');			    
		setMetaData('abasedocid','0_0002_public');			    
		
	  		/** START omniture_snippet_wsj_2.htm **/
    if(s.prop19 == 'article'){
        s.hier1 = s.channel+','+s.prop1+','+s.prop2+','+s.pageName+','+s.prop22+','+s.prop3+','+s.prop20+','+s.prop4+','+s.prop6;
    }else{
        s.hier1 = s.channel+','+s.prop1+','+s.prop2+','+s.pageName+','+s.prop6;
    }

/** pageView event and eVar value **/
s.events=s.events?s.events+",event12":"event12";
s.eVar3 = "";
try{
  if (GetCookie('TR')){s.eVar3 = GetCookie('TR')}
} catch(err){}
s.eVar4 = s.pageName;
s.eVar5="";
s.eVar6="";
if(link){s.eVar5 =link;}
if(reflink){s.eVar6 =reflink;}
s.eVar8 = "";
if (s.prop18){
  s.eVar8 = s.prop18;
}
s.eVar11 = s.channel;

/** DO NOT ALTER ANYTHING BELOW THIS LINE **/
var s_code=s.t();if(s_code)document.write(s_code)//--></script>
<script type="text/javascript"><!--
if(navigator.appVersion.indexOf('MSIE')>=0)document.write(unescape('%3C')+'\!-'+'-')
//--></script><!--/DO NOT REMOVE/-->
<!-- End SiteCatalyst code version: H.3. -->

<script type="text/javascript"><!--
/**** Code added for Spotlight Tag - Jan 2007 ****/

try { 
    if(!GetCookie('spotlightSet')  && GetCookie('TR')){ 
    var cookieVal = GetCookie('TR'); 
    var randomNumber=Math.floor(Math.random()*1000000); 
    var spotlightTag = '<img src="http://ad.doubleclick.net/activity;src=1373310;type=rapta615;cat=track812;u='+cookieVal+';ord='+randomNumber+'?" width="1" height="1" border="0" alt=""/>'; 

     document.write(spotlightTag); 
     SetCookie('spotlightSet','true','90d+'); 
    } 
} 
catch(err){}

//--></script>
<!--/DO NOT REMOVE/-->

<!-- START: Loomia Similar Items Recommendation Code  -->
<div id="_loomia_si_script_anchor" class="failsafe"></div>
<div id="_loomia_cs_script_anchor" class="failsafe"></div>
<div id="_loomia_cs_anchor" class="failsafe"></div>
<script type="text/JavaScript">
<!--
function _loomia_addScript(url,script_anchor){
	var anchor=document.getElementById(script_anchor);
	var script= document.createElement("SCRIPT");
	script.src=url;
	anchor.appendChild(script);
}
var _loomia_scripts_loaded=0;
function _loomia_addCS() {
	if (!_loomia_scripts_loaded) {
		_loomia_addScript("http://assets.loomia.com/js/clixdom.js","_loomia_cs_script_anchor");
		_loomia_addScript("http://assets.loomia.com/js/simitems.js","_loomia_si_script_anchor");
	}
	_loomia_scripts_loaded=1;
};
var L_VARS=new Object();
L_VARS.publisher_key=6563391702;
L_VARS.guid=(typeof s!='undefined')?s.prop20:"";
L_VARS.anchor="_loomia_si_anchor";
var exList=['0_0002','0_0012','0_0003','0_0013','0_0004','0_0014']
pID=(typeof pID != 'undefined')?pID:"";
if(window.location.href.indexOf('/article') != -1 && window.pID && pID.indexOf('Infogrfx') == -1 && exList.join('|').indexOf('|'+pID+'|') == -1 && parent.location.protocol=="http:"){
	if (window.addEventListener) {
		window.addEventListener("DOMContentLoaded", _loomia_addCS, false);
		if($('_loomia_si_anchor')!=null){
			window.addEventListener("load", _loomia_addCS, false);
		}
	} else if (window.attachEvent) {
		window.attachEvent("onload", _loomia_addCS);
	}
}
//-->
</script>
<!-- END: Loomia Similar Items Recommendation Code  -->

<!-- END omniture_snippet_wsj_2.htm -->

    	
<!-- starting retargeting_pixel.htm -->
<script type="text/javascript">
<!--
var title = 'TITLE';
try {
if (title == unescape('%u0054%u0049%u0054%u004C%u0045') && document.title) title = document.title;
document.write('<img width="0" height="0" border="0" src="http://media.adrevolver.com/adrevolver/trace?adpath=722&title=' + escape(title) + '&ref=' + escape(document.referrer) + '&rnd=' + Math.round(Math.random() * 10000000) + '">');
} catch(e){}

var _l = 1002; var _p = 1440; var _f = 1; var _ta = (document.domain).split ("."); var psd = (_ta.length > 1 ? "." + _ta[_ta.length - 2] + "." + _ta[_ta.length - 1] : document.domain); var _cn = "L" + _l + "="; var _call = document.cookie.indexOf (_cn); var _il = 1; var _tl = 0; var _ex; var _rnd = (new Date ()).getTime (); if (_call >= 0) { _pos = document.cookie.substring (_call).indexOf (';'); if (_pos > 0) _val = document.cookie.substring (_call + _cn.length, _call + _pos); else _val = document.cookie.substring (_call + _cn.length); if (_val.indexOf ('.') > 0) { _il = _val.substring (0, _val.indexOf ('.')); _ex = _val.substring (_val.indexOf ('.') + 1); _tl = _ex - (new Date ()).getTime (); } if (_tl <= 0) document.cookie = _cn + "; domain=" + psd + "; path=/; expires=" + (new Date ((new Date ()).getTime () - 1000000)).toGMTString () + ";"; } if (_il < _f || _tl <= 0) { var expiry = (new Date((new Date()).getTime()+_p*2*60*1000)).toGMTString(); if (document.cookie.indexOf(_cn) < 0 ) document.cookie=_cn+''+(1)+'.'+((new Date()).getTime()+_p*60*1000)+'; domain='+psd+';path=/;expires='+expiry; else document.cookie=_cn+''+(_il-0+1)+'.'+_ex+';domain='+psd+'; path=/;expires='+expiry; document.write ("<sc" + "ript language='javascript' src='http://adopt.specificclick.net/Custom/bht.jsp?px=" + _l + "&v=1&rnd=" + _rnd + "'>"); document.write ("</sc" + "ript>"); } 
// -->
</script><img src="us_files/trace.gif" border="0" height="0" width="0"><script language="javascript" src="us_files/bht.html"></script>
<script type="text/javascript" src="us_files/randm.js"></script><script language="JavaScript1.1" src="us_files/decide_002.html"></script>
<script type="text/javascript" src="us_files/randm_002.js"></script>

<!-- img src="http://media.fastclick.net/rt?cn1=urt5&amp;v1=e"  alt="" width="1" height="1" border="0" / -->
<img src="us_files/a.gif" alt="" border="0" height="0" width="0">

<!-- Start of DoubleClick Spotlight Tag: Please do not remove-->
<script type="text/javascript">
<!--
var axel = Math.random()+"";
var a = axel * 10000000000000;
document.write('<img src="http://ad.doubleclick.net/activity;src=1371794;type=wsjbr858;cat=wsjco985;ord='+ a + '?" width="1" height="1" alt="" />');
// --></script><img src="us_files/activity.gif" alt="" height="1" width="1">
<noscript>
<img src="http://ad.doubleclick.net/activity;src=1371794;type=wsjbr858;cat=wsjco985;ord=1?" width="1" height="1" alt="" />
</noscript>
<!-- End of DoubleClick Spotlight Tag: Please do not remove-->

<!-- end retargeting_pixel.htm -->


<!-- TIMESTAMP: Tue Jul 24 02:45:09 EDT 2007 -->
<!-- SERVER: sbkj2kwebp02 -->
<!-- TARGET: evo_live -->
</body></html>
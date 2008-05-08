#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 74;

BEGIN { use_ok('SL::Subrequest') or die }

# slurp the test webpage
my $content = do { local $/; <DATA> };

use Time::HiRes qw(tv_interval gettimeofday);

my $base_url   = 'http://online.wsj.com';
my $subreq     = SL::Subrequest->new();

# clear out the cache
$subreq->{cache}->clear;

my $start      = [gettimeofday];
my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);
my $interval = tv_interval( $start, [gettimeofday] );

is( scalar( @{$subreq_ref} ), scalar(@{test_urls()}), 'num subrequests extracted' );
diag("extraction took $interval seconds");
my $limit = 0.1;
cmp_ok( $interval, '<', $limit,
    "subrequests extracted in $interval seconds" );

diag("check correct subrequests were extracted");
# unique subrequests
my %subreq_hash = map { $_->[0] => 1 } @{$subreq_ref};
foreach my $test_url ( @{ test_urls() } ) {
    ok(exists $subreq_hash{$test_url});
}

diag('test replacing the links');
my $port = '6969';
$start = [gettimeofday];
ok(
    $subreq->replace_subrequests(
        { port => $port, content_ref => \$content, subreq_ref => $subreq_ref }
    )
);
$interval = tv_interval( $start, [gettimeofday] );
$limit = 0.075;    # 35 milliseconds
diag("replacement took $interval seconds");
cmp_ok( $interval, '<', $limit, "replace_subrequests took $interval seconds" );

open(FH, '>/tmp/foobar.html') or die $!;
print FH $content;
close(FH);

sub test_urls {
    return [
'http://s.wsj.net/favicon.ico',
'http://feeds.wsjonline.com/wsj/xml/rss/3_7011.xml',
'http://s.wsj.net/j20type.css',
'http://s.wsj.net/css/freeTodayBoxAdjuster.css',
'/wsj_nav_array/2008_03_26_05_02.js',
'http://s.wsj.net/navigation.js',
'http://s.wsj.net/headerscripts.js',
'http://s.wsj.net/quotesearch.js',
'http://s.wsj.net/cornerstone.js',
'http://s.wsj.net/javascript/dateTimeFunctions.js',
'http://s.wsj.net/javascript/stringFunctions.js',
'http://s.wsj.net/javascript/mathFunctions.js',
'http://s.wsj.net/javascript/xmlFunctions.js',
'http://s.wsj.net/javascript/httpRequest.js',
'/javascript/partialRefresh.js',
'http://s.wsj.net/javascript/matchheight.js',
'http://s.wsj.net/img/News_selected.gif',
'http://s.wsj.net/img/b.gif',
'http://s.wsj.net/img/rssNavPromoImageAutos.gif',
'http://s.wsj.net/img/rssNavPromoImageAllTD.gif',
'http://s.wsj.net/img/rssNavPromoImageRealEstate.gif',
'http://s.wsj.net/img/rssNavPromoImageCrossword.gif',
'http://s.wsj.net/img/weekend_edition_strap.gif',
'http://s.wsj.net/public/resources/images/OB-BF324_pj_wom_20080328173710.gif',
'http://s.wsj.net/public/resources/images/OB-BF332_pj_mil_20080328180653.gif',
'http://s.wsj.net/public/resources/images/OB-BF314_pj_nor_20080328171244.gif',
'http://s.wsj.net/img/subscibeNow.gif',
'http://s.wsj.net/img/whatsNewsSmall.gif',
'/img/b.gif',
'http://s.wsj.net/public/resources/images/OB-BF358_Paulso_20080328231508.jpg',
'http://s.wsj.net/css/autocomplete.css',
'http://s.wsj.net/img/hprightarrowNew.gif',
'http://s.wsj.net/public/resources/images/OB-BF360_fay_vi_20080329131915.jpg',
'http://s.wsj.net/public/resources/images/OB-BF117_032708_20080327152944.jpg',
'http://s.wsj.net/public/resources/images/OB-BF348_IT_Hot_20080328202820.gif',
'http://s.wsj.net/public/resources/images/OB-BF284_mendoz_20080328155959.gif',
'http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1478143689_2aa1f8cf828210147d4e429a59482a408716f473.jpg?pubId=86240652',
'http://s.wsj.net/img/hpVideoPlayBtnNew.gif',
'http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1478190627_9ac90259e70c5220f4bc25e1c1f570eb79603aac.jpg?pubId=86240652',
'http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1478204341_cea343d002787ff8a0f67a2395baffa346c7da3e.jpg?pubId=86240652',
'http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1473736558_558241c82248d910aa5015eb777d477e09b6b477.jpg?pubId=86240652',
'http://s.wsj.net/public/resources/images/it_olympic-china08282006160216.gif',
'http://s.wsj.net/public/resources/images/OB-BF229_tibetf_20080328111932.jpg',
'/public/resources/media/it_podcast.gif',
'/javascript/com/dowjones/utils/rssSelector.js',
'http://s.wsj.net/img/feed-icon.gif',
'http://leadback.advertising.com/adcedge/lb?site=695501&amp;srvc=1&amp;betr=wsj_cs=3&amp;betq=1031=359955',
'http://s.wsj.net/img/wj00g18.gif',
'http://s.wsj.net/js/s_code_wsj.js',
'http://js.revsci.net/gateway/gw.js?csid=G07608',
'http://s.wsj.net/img/closeWSJ.gif',
'http://s.wsj.net/javascript/sphere.js',
'http://amch.questionmarket.com/adsc/d260080/36/263292/randm.js',
'http://amch.questionmarket.com/adsc/d260080/37/263293/randm.js',
'http://www.burstnet.com/enlightn/426/public/7FAA/',
'http://ad.yieldmanager.com/pixel?id=61612&t=1',
'http://bh.contextweb.com/bh/set.aspx?action=replace&advid=570&token=WSJ01',
'http://ad.doubleclick.net/activity;src=1371794;type=wsjbr858;cat=wsjco985;ord=1?',
'http://feeds.wsjonline.com/',
'http://s.wsj.net/',
'http://ad.doubleclick.net/',
'http://online.wsj.com/',
'http://www.europesubs.wsj.com/',
'http://chart.bigcharts.com/',
'http://mobile.wsj.com/',
'http://public.wsj.com/',
'http://media.adrevolver.com/',
'http://amch.questionmarket.com/',
'http://bh.contextweb.com/',

    ];
}

__DATA__


















<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">












<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta name="GOOGLEBOT" content="NOARCHIVE" />
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />
<!--added for registration bypass2 October 3,2002-->
 
<!-- CDS hostname /sbkj2kappp02/ -->
<meta http-equiv="refresh" content="1200;URL=/public/us?refresh=on" /> 
<meta name="pagename" content="U.S. Home_0_0002_public" />
<meta name="section" content="Home" />
<meta name="subsection" content="Home Page Public" />
<meta name="csource" content="WSJ Online" />
<meta name="ctype" content="home page" />
<meta name="displayname" content="U.S. Home" />
<meta name="keywords" content="Business Financial News, Business News Online, Personal Finance News, Financial News, Business News, Finance news, Personal Finance, Personal Financial News, Busines Newspaper" />
<meta name="description" content="Business Financial News - The Wall Street Journal is the world's leading business publication. At WSJ.com users can access business news online as well as personal finance news" />
 
<link rel="SHORTCUT ICON" href="http://s.wsj.net/favicon.ico" />

<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var userName = '(none)';
var serverTime = new Date("March 29, 2008 21:56:14");
//-->
</script>
<meta http-equiv="Cache-Control" content="no-cache" />
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
<link rel="alternate" type="application/rss+xml" title="WSJ.com: What's News US" href="http://feeds.wsjonline.com/wsj/xml/rss/3_7011.xml" />
<link rel="stylesheet" href="http://s.wsj.net/j20type.css" type="text/css" />
<link rel="stylesheet" href="http://s.wsj.net/css/freeTodayBoxAdjuster.css" type="text/css" />
<script type="text/javascript"><!--
var pID="0_0002_public",nSP="",uP="http://online.wsj.com",gcPH="/pj/PortfolioDisplay.cgi",gcWIA="http://users.wsj.com/WebIntegration/WebIntegrationServlet",gcLFU="https://commerce.wsj.com/auth/submitlogin",gcHSP="https://",gcDomain="online.wsj.com",pStl="nonsub-summary",PSS="0_0002_public",PSSG="header0_0002_public",_navTxt="News",pDate="9:56&nbsp;p.m.&nbsp;EDT&nbsp;Saturday,&nbsp;March&nbsp;29,&nbsp;2008",writeUrl="http://ds.wsj.com";
var isTrial=false, isDenial=false, isFree=false;
//--></script>

	<script type="text/javascript">var mpsection='Home Page Public'</script>


<script type="text/javascript" src="/wsj_nav_array/2008_03_26_05_02.js"></script>
<script type="text/javascript" src="http://s.wsj.net/navigation.js"></script>

<script type="text/javascript" src="http://s.wsj.net/headerscripts.js"></script>
<script type="text/javascript" src="http://s.wsj.net/quotesearch.js"></script>
<script type="text/javascript" src="http://s.wsj.net/cornerstone.js"></script>
<script type="text/javascript" src="http://s.wsj.net/javascript/dateTimeFunctions.js"></script>
<script type="text/javascript" src="http://s.wsj.net/javascript/stringFunctions.js"></script>
<script type="text/javascript" src="http://s.wsj.net/javascript/mathFunctions.js"></script>
<script type="text/javascript" src="http://s.wsj.net/javascript/xmlFunctions.js"></script>
<script type="text/javascript" src="http://s.wsj.net/javascript/httpRequest.js"></script>
<script type="text/javascript" src="/javascript/partialRefresh.js"></script>
<script type="text/javascript" src="http://s.wsj.net/javascript/matchheight.js"></script>

<script type="text/javascript">
<!--
window.name = "wndMain"
function onLoadAction(){
	var idev=false;setTimeout('initPartialRefresh()',3*1000);matchHeight2('left_rr','right_rr');;
	
}

function onUnloadAction(){
;
}
//-->
</script>
<title>Business Financial News, Business News Online &amp; Personal Finance News at WSJ.com - WSJ.com</title>
</head>
<body style="margin:0px;padding:0px;background-color:#FFF" onunload="onUnloadAction();exitPopup();" onload="onLoadAction()">
<a name="top"></a>



<!-- Begin header -->
<div style="border: 0px; padding: 0px; margin: 0px; width: 990px">
	<div>





<div id="container_0_0200" style="width:990px;"><!-- begin: container_0_0200 -->
<div id="column_1_0_0200" style="float:left;padding: 0px 1px 0px 9px;height: 66px;"><!-- begin: column_1_0_0200 -->



	<script type="text/javascript"><!--
if((typeof window.nSP)=='undefined'||nSP==null){var nSP='';}
document.write('<'+'a id="logolink" href="'+nSP+'/home"'+'>'+'<'+'img width="407" height="62" src="http://s.wsj.net/img/mainWSJlogoWhite.gif" alt="The Wall Street Journal Home Page" border="0" /'+'>'+'<'+'/'+'a>');
//--></script>
<script type="text/javascript"><!--
/*
if((typeof window.nSP)!='undefined'&&nSP!=''){$('logolink').href=nSP+'/home';}
else{nSP='';}
if((typeof pID)=='undefined'||pID==null){var pID='';}
if((typeof $)=='undefined'){function $(i){return (document.getElementById)?document.getElementById(i):null}}
if((typeof GetCookie)=='undefined'){function GetCookie(N){;var co=document.cookie,pos=co.indexOf(N+"=");return (pos!=-1)?unescape(co.substring(pos+N.length+1,(co.indexOf("; ",pos)!=-1?co.indexOf("; ",pos):co.length))):null;}}
if((typeof loggedIn)=='undefined'){var loggedIn=(window.laserJ4J?laserJ4J.isLoggedIn('WSJ'):true);}else{loggedIn=(window.laserJ4J?laserJ4J.isLoggedIn('WSJ'):true);}
*/
/*
 * dependencies:
 * variables: nSP,pID,loggedIn,laserJ4J,gcPH,gcDomain
 * functions: function $,function GetCookie
 */
//--></script>

<!-- end: column_1_0_0200 --></div>
<div id="promo_container" style="float:left;padding: 5px 18px 4px 20px;*padding:7px 18px 2px 20px;"><!-- begin: promo_container -->



<center>
	 
<div style="text-align:center;padding:0px 0px 5px 0px;">
 	
 	
<span id="adSpanH"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=302x52;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="adH" src="'+adURL+'" width="302" height="52" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:302">';
} else {
  tempHTML += '<iframe id="adH" src="/static_html_files/blank.htm" width="302" height="52" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:302px;">';
  ListOfIframes.adH= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=302x52;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=302x52;ord=1820182018201820;" border="0" width="302" height="52" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</span>
</div>
</center>

<!-- end: promo_container --></div>
<div id="search_container" style="display:none;padding: 10px 20px 10px 20px; *padding: 6px 20px 0px 20px; width:300px; float: left; height: 46px; *height: 60px;"><!-- begin: search_container -->



	<script type="text/javascript"><!--

	var staticDomainVal='';
	if((typeof window.nSP)=='undefined'||nSP==null){var nSP='';}
	staticDomainVal='http://s.wsj.net';

    searchBoxID = 'QuoteSearchBox';
    resultContainerID = 'symbolCompleteResults';
    searchGoButtonID = 'SearchQuoteGoButton';

	if((typeof window.nSP)=='undefined'||nSP==null){var nSP='';}

	document.write('<link href="'+nSP+'/css/autocomplete.css" type="text/css" rel="stylesheet" \/>');

	document.write('<scr'+'ipt type="text/javascript" src="'+staticDomainVal+'/javascript/yui-0.12.2.js">' + '<\/script>');
	document.write('<scr'+'ipt type="text/javascript" src="'+staticDomainVal+'/javascript/infocomplete.js">' + '<\/script>');
	document.write('<scr'+'ipt type="text/javascript" src="'+staticDomainVal+'/javascript/global_autocomplete.js">' + '<\/script>');
//--></script>

<script type="text/javascript">
<!--
if (typeof(initInfoComplete) != 'undefined' && YAHOO.util.Event){YAHOO.util.Event.onAvailable('QuoteSearchBox', initInfoComplete); }// -->
</script>

<table border="0" cellpadding="0" cellspacing="0">
<tr>
<td width="280" style="padding-right:10px" valign="top">
<!--<div class="b12">Search</div>-->
<div class="searchHeader" style="margin:0px;">Search</div>

<!--<form name="main_article_search" id="main_article_search" action="/search" method="post" style="margin:0px;padding:0px;">-->
<div class="searchQuoteSection">
<div class="symbolCompleteContainer"><div><input type="text" name="QuoteSearchBox" id="QuoteSearchBox" value="Enter Symbol(s) or Keyword(s)" maxlength = "80" class="unUsed" style="width:192px;" onfocus="searchFieldOnFocus(this);setFocused(this);" onblur="setFocused(null);" autocomplete="off" /></div>
<div id="symbolCompleteResults" class="symbolCompleteResults"></div></div>
<div id="SearchQuoteGoButton" class="largebutton"><div class="leftcapoff"></div><div class="buttonoff"><p style="width: 20px; text-align: center;"><a href="http://online.wsj.com/" onfocus="setFocused('');" onblur="setFocused(null);">GO</a></p></div><div class="rightcapoff"></div></div>
<div style="clear:both;"/>
</div>
<!--</form>-->
<!--<div class="p10">-->
<div class="quoteSearchLinks" style="*margin-top:-3px;">
<script type="text/javascript"><!--
document.write('<'+'a href="'+nSP+'/advanced_search" class="unvisited p10">Advanced Search<'+'/a>');
document.write(' | <'+'a href="'+nSP+'/quotes/main.html" class="unvisited p10">Symbol Lookup<'+'/a>');
//--></script>
</div>
</td>
</tr>
</table>




	<script type="text/javascript"><!--
if(loggedIn){$('promo_container').style.display='none';$('search_container').style.display='block';}
//--></script>

<!-- end: search_container --></div>
<div id="login_container" style="margin:0px;"><!-- begin: login_container -->



	<div style="padding: 6px 9px 8px 0px; _padding: 5px 9px 5px 0px; float: left; width: 224px; height: 52px;">
  <div style="border-bottom:1px solid #9BADCE;background-color: #EFF7F7;background-image: url(http://s.wsj.net/img/hp_login_top_bk.gif);background-repeat: repeat-x;background-position: top;">
    <div style="background-image: url(http://s.wsj.net/img/hp_login_rt_bl_bk.gif);background-repeat: repeat-y;background-position: right;">
      <div style="background-image: url(http://s.wsj.net/img/hp_login_le_bl_bk.gif);background-repeat: repeat-y;">
        <div style="background-image: url(http://s.wsj.net/img/hp_login_tl_bk.gif);background-repeat: no-repeat;background-position: left top;">
          <div style="background-image: url(http://s.wsj.net/img/hp_login_tr_bk.gif);background-repeat: no-repeat;background-position: right top;">
            <form method="post" action="/login" name="login_form" id="login_form" style="margin:0px;" onsubmit="suppress_popup=true;return true;">
              <input type="hidden" name="url" value="/home" />
              <table align="center" style="padding:2px 0px 0px 0px;" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="letter-spacing: -1px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 9px;">User Name:&nbsp;</td>
                  <td><input type="text" name="user" size="9" maxlength="30" style="width:54px;font-size:9px;" /></td>
                  <td style="letter-spacing: -1px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 9px;">Password:&nbsp;</td>
                  <td><input type="password" name="password" size="9" style="width:50px;font-size:9px;" maxlength="30" /></td>
                </tr>
              </table>
              <table align="center" style="padding:2px 0px 0px 0px;" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td width="14" style="padding-left:12px;"><input type="checkbox" id="savelogin" name="savelogin" value="true" checked="checked" style="padding:0px;margin:0px;width:14px;height:13px;" /></td>
                  <td class="pb11" valign="middle" colspan="3" style="color:#9D0903;"><label for="savelogin" style="cursor:pointer;">Remember Me</label></td>
                  <td class="pb11" align="right" style="padding-right:7px;"><a href="/login" onclick="document.login_form.submit();return false" style="color:#9D0903;">Log In&nbsp;<input name="img" type="image" src="http://s.wsj.net/img/loginArrow.gif" style="width:5px;height:9px;border:0px;" alt="" /></a></td>
                </tr>
              </table>
            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div style="background-image: url(http://s.wsj.net/img/hp_login_bottom_bk.gif);background-repeat: repeat-x;background-position: bottom;">
    <div style="background-image: url(http://s.wsj.net/img/hp_login_rt_wt_bk.gif);background-repeat: repeat-y;background-position: right;">
      <div style="background-image: url(http://s.wsj.net/img/hp_login_le_wt_bk.gif);background-repeat: repeat-y;">
        <div style="background-image: url(http://s.wsj.net/img/hp_login_bl_bk.gif);background-repeat: no-repeat;background-position: left bottom;">
          <div style="padding:2px 0px 3px 0px;background-image: url(http://s.wsj.net/img/hp_login_br_bk.gif);background-repeat: no-repeat;background-position: right bottom;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 9px;text-align: center;letter-spacing: -1px;"><a href="http://commerce.wsj.com/auth/forgotpass">Forgot your username or password?</a> <span style="color:#666666">|</span>
          <script language="JavaScript" type="text/javascript"><!--
           var partners = new Array('yahoo', 'google', 'msn', 'other');
           function getPartner(modparam) {
				var localMod="";
			    if(modparam != null && modparam.length > 0) {
					for (var i=0; i<partners.length; i++) {
				  if (modparam.indexOf(partners[i]) > -1 ) {
					localMod = partners[i];
							break;
					  }
					}
				}
				return ( (localMod==null || localMod.length<1) ? "other":localMod );
			}

		  var modParam = "";
		  var which_mod = "";

		  var sourceCode = "6BCWCC_1007";

          if(pID=='0_0002_public'){
            sourceCode="6BCWBM_1007";

          }else if(pID=='2_0433'){
            sourceCode="6BCWCD_1007";

          }else if(pID=='3_0513'){

			  modParam = GetArg("mod");
			  which_mod = getPartner(modParam);

			  if(which_mod == 'google'){
				sourceCode = "6BCWBP_1007";
			  }else if(which_mod == 'yahoo'){
				sourceCode = "6BCWBR_1007";
			  }else if(which_mod == 'msn'){
				sourceCode = "6BCWBS_1007";
			  }else{
	            sourceCode="6BCWBN_1007"
	          }

          }else if(pID=='3_0508' || pID=='3_0508B'){

			  modParam = GetArg("mod");
			  which_mod = getPartner(modParam);

			  if(which_mod == 'google'){
				sourceCode = "6BCWBW_1007";
			  }else if(which_mod == 'yahoo'){
				sourceCode = "6BCWCA_1007";
			  }else if(which_mod == 'msn'){
				sourceCode = "6BCWCB_1007";
			  }else{
	            sourceCode="6BCWBT_1007"
	          }
          }
          document.write('<a href="https://commerce.wsj.com/reg/promo/'+sourceCode+'">Subscribe</a>');
          //--></script>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
<script type="text/javascript" language="javascript" charset="ISO-8859-1"><!--
var myPID=(typeof pID != 'undefined')?pID:"";
var hometarget=new Array();
hometarget["0_0002_public"]="/home/us";
hometarget["0_0003_public"]="/home/europe";
hometarget["0_0004_public"]="/home/asia";
hometarget["0_0110"]="/myonlinejournal";
hometarget["0_0112"]="/myonlinejournal";
hometarget["0_0114"]="/myonlinejournal";

var changedURL=window.location.href;
var rn=Math.floor(Math.random()*1000000);
var concatURL='http://'+(gcDomain!=""?gcDomain:document.domain);
if ( (typeof hometarget[myPID] != 'undefined') && (hometarget[myPID] != null || hometarget[myPID] != "") ) {
  changedURL = concatURL + hometarget[myPID];
}
else if (window.location.href.indexOf('/article') > -1 ) {
  if (changedURL.indexOf('?') > -1) {
       changedURL+='&apl=y&r='+rn;
  } else {
       changedURL +='?apl=y&r='+rn;
  }
} else if (myPID.indexOf('2_3') > -1 ) {
  changedURL = concatURL + '/mdc/page/marketsdata.html?mod=mdc_hdr_login'
}
else {
  changedURL = concatURL + '/home';
}if((typeof overrideLogin)=='undefined'||overrideLogin==null){var overrideLogin='';}

if(overrideLogin != ''){
	document.login_form.url.value = overrideLogin;
}else{
	document.login_form.url.value=changedURL;
}
document.login_form.action=gcLFU;
//--></script>

<!-- end: login_container --></div>
<div id="welcome_container" style="margin:0px;display:none;"><!-- begin: welcome_container -->



	<script type="text/javascript" language="javascript" charset="ISO-8859-1"><!--
try {
  var userName=laserJ4J?laserJ4J.getUser():"";
} catch(e) {
  var userName="";
}
if(userName == null){
	userName = "";
}

if((typeof overrideHeaderLogout)=='undefined'||overrideHeaderLogout==null){var overrideHeaderLogout='';}


//--></script>
<div style="padding: 10px 9px 4px 0px; float: left; width: 224px; height: 52px;">
	<div style="border-bottom:1px solid #9BADCE;background-color: #EFF7F7;background-image: url(http://s.wsj.net/img/hp_login_top_bk.gif);background-repeat: repeat-x;background-position: top;">
		<div style="background-image: url(http://s.wsj.net/img/hp_login_rt_bl_bk.gif);background-repeat: repeat-y;background-position: right;">
			<div style="background-image: url(http://s.wsj.net/img/hp_login_le_bl_bk.gif);background-repeat: repeat-y;">
				<div style="background-image: url(http://s.wsj.net/img/hp_login_tl_bk.gif);background-repeat: no-repeat;background-position: left top;">
					<div style="background-image: url(http://s.wsj.net/img/hp_login_tr_bk.gif);background-repeat: no-repeat;background-position: right top;text-align: center;">
						<div class="pb11" style="padding-top:4px;padding-bottom:3px;height:15px;vertical-align: middle;">WELCOME <span class="userName" style="color:#9D0903;"><script type="text/javascript" language="javascript" charset="ISO-8859-1"><!--
						document.write((userName.length>11)?userName.substring(0,11)+"...":userName);
						//--></script></span> | <span class="p10"><a href="#" onclick="(!GetCookie('logoutprompt'))?OpenWin((overrideHeaderLogout != '') ? overrideHeaderLogout : nSP+'/static_html_files/logout_confirmation.htm','logoutconfirmation',325,200,'off',true,0,0,true):window.location=nSP+'\/logout';return false" class="unvisited p10">Log Out</a></span></div>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div style="background-image: url(http://s.wsj.net/img/hp_login_bottom_bk.gif);background-repeat: repeat-x;background-position: bottom;">
		<div style="background-image: url(http://s.wsj.net/img/hp_login_rt_wt_bk.gif);background-repeat: repeat-y;background-position: right;">
			<div style="background-image: url(http://s.wsj.net/img/hp_login_le_wt_bk.gif);background-repeat: repeat-y;">
				<div style="background-image: url(http://s.wsj.net/img/hp_login_bl_bk.gif);background-repeat: no-repeat;background-position: left bottom;">
					<div id="msgCenter" style="background-image: url(http://s.wsj.net/img/hp_login_br_bk.gif);background-repeat: no-repeat;background-position: right bottom;text-align: center;">
  <table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
<td class="p10" style="padding:4px 0px 5px 0px;border-right:1px solid #9BADCE;" align="center"><script type="text/javascript"><!--
document.write('<'+'a href="'+nSP+'/acct/setup_account" class="unvisited p10"'+'>'+'My Account'+'<'+'/'+'a>');
//--></script></td>
<td class="p10" style="padding:4px 0px 5px 0px;border-right:1px solid #9BADCE;" align="center"><script type="text/javascript"><!--
document.write('<'+'a href="'+nSP+'/msgcenter/view_messages.html?product=WSJ" class="unvisited p10"'+'>'+'Messages'+'<'+'/'+'a>');
//--></script></td>
<td class="milu" style="color:#fff;padding:4px 0px 5px 0px;" align="center"><script type="text/javascript"><!--
document.write('<'+'a href="'+nSP+'/setup/setup_center_mainpage" class="unvisited p10"'+'>'+'Preferences'+'<'+'/'+'a>');
//--></script></td>
</tr>
  </table>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>





	<script type="text/javascript"><!--
if(loggedIn){$('login_container').style.display='none';$('welcome_container').style.display='block';}
//--></script>

<!-- end: welcome_container --></div>
<div id="column_6_0_0200"><!-- begin: column_6_0_0200 -->



	<table cellpadding="0" cellspacing="0" width="990" border="0" class="p11" style="color:#ffffff;clear:both; background-color:#336699;height:19px;">
  <tr>
    <td class="nobr" align="left" style="padding-left:11px;height:20px;"><script type="text/javascript"><!--
      if((typeof pID)=='undefined'||pID==null){var pID='';}
	  if((typeof window.nSP)=='undefined'||nSP==null){var nSP='';}
      if(((typeof pDate)!='undefined')&&pDate!=''){document.write('As&nbsp;of&nbsp;<span id="pageTimeStamp">'+pDate+'</span>');}
    //--></script></td><td class="nobr" align="right" style="width: 0px;"><script type="text/javascript"><!--
    document.write('<'+'a href="'+nSP+'/login" onclick="if(loggedIn){;OpenWin(\'/setup/select_edition_popup\',\'Warning\',310,280,\'st\',1,300,100);return false;}else{;return true;}" style="color:#fff;"'+'>Set My Home Page<'+'/'+'a>');
    //--></script></td><td style="padding: 0px 5px; width: 1px;"><span style="color:#fff;">|</span></td><td style="padding-right: 26px; width: 10px;" align="right"><script type="text/javascript"><!--
      var printUrl=((pID=='0_0013'||pID=='0_0003'||pID=='2_0003')?'http://www.europesubs.wsj.com/?mod=header_'+pID:((pID=='0_0014'||pID=='0_0004'||pID=='2_0004')?'https://www.awsj.com.hk/awsj2/?source=PWSHE4ECHR1N&mod=header_'+pID:'http://services.wsj.com?mod=header_'+pID));
      var onlineUrl=nSP+((loggedIn)?'':'/public')+'/page/0_0809.html?page=0_0809&mod=header_'+pID;
      document.write('<'+'a style="color:#fff;white-space:nowrap;" href="'+onlineUrl+'"'+'>Customer&nbsp;Service<'+'/'+'a>');
    //--></script></td>
  </tr>
</table>

<!-- end: column_6_0_0200 --></div>
<div id="column_7_0_0200" style="width:990px;float:left;"><!-- begin: column_7_0_0200 -->



	<script type="text/javascript"><!--
var staticDomain='';
if((typeof window.nSP)=='undefined'||nSP==null){var nSP='';}
if(nSP==''){staticDomain='http://s.wsj.net'};

document.write('<'+'script type="text/javascript" src="http://s.wsj.net/javascript/HorizontalNavigationData_new.js"'+'>'+'<'+'/'+'script>');
document.write('<'+'script type="text/javascript" src="http://s.wsj.net/javascript/HorizontalNavigation_new.js"'+'>'+'<'+'/'+'script>');
//--></script>

<!-- end: column_7_0_0200 --></div>
<div id="column_8_0_0200" style="clear:left;"><!-- begin: column_8_0_0200 --><script type="text/javascript"><!--
var msnADArray = {};
//--></script>



	<!-- Just to clear left -->

<!-- end: column_8_0_0200 --></div><!-- end: container_0_0200 --></div>
	</div>
</div>
<!-- End header -->



<!-- Begin content -->
<div class="main" style="border: 0px; padding: 0px; margin: 18px 0px 0px 0px; width: 990px">


<!-- Begin nav -->
  <div style="float: left; width: 131px; margin: 0px 0px 0px 0px;">
	<div style="clear: left; width: 131px; margin: 0px;">
     





<div id="column_1_0_0089"><!-- begin: column_1_0_0089 -->





	<script type="text/javascript">
	<!-- OM = "";
	// --></script>
	<div style="width:131px;background-color:#fff;padding:0px;margin:0px;border:0px;">
  <div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#f00;" class="b11"><script type="text/javascript"><!--
  document.write('<a href="' + nSP + '/home" onclick="document.location.href=nSP+\'/home\';return false;" onmouseover="MyImg=new Image;MyImg.src=document.HOMEIMG.src;document.HOMEIMG.src=\'http://s.wsj.net/img/Home_over.gif\'" onmouseout="document.HOMEIMG.src=MyImg.src"><img name="HOMEIMG" src="http://s.wsj.net/img/Home_normal.gif" border="0" width="131" height="18" alt="" /></a>'); // --></script></div>

<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#f00;" class="b11"><img src="http://s.wsj.net/img/News_selected.gif" border="0" alt=""/></div>

<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color: #F93;" class="p12">News Main</div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/news/us_business?mod=2_0002" onclick="document.location.href=nSP+'/news/us_business?mod=2_0002';return false;">U.S. Business</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/redirect/europe.html?mod=0_0003" onclick="document.location.href=nSP+'/redirect/europe.html?mod=0_0003';return false;">Europe</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/redirect/asia.html?mod=0_0004" onclick="document.location.href=nSP+'/redirect/asia.html?mod=0_0004';return false;">Asia</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/news/world_news?mod=2_0006" onclick="document.location.href=nSP+'/news/world_news?mod=2_0006';return false;">World News</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/redirect/economy.html?mod=2_0007" onclick="document.location.href=nSP+'/redirect/economy.html?mod=2_0007';return false;">Economy</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/page/politics_policy.html?mod=2_0008" onclick="document.location.href=nSP+'/page/politics_policy.html?mod=2_0008';return false;">Politics &amp; Policy</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/public/page/election2008.html?mod=2_1309" onclick="document.location.href=nSP+'/public/page/election2008.html?mod=2_1309';return false;">Campaign 2008</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/news/earnings?mod=2_0009" onclick="document.location.href=nSP+'/news/earnings?mod=2_0009';return false;">Earnings</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/health?mod=0_0005" onclick="document.location.href=nSP+'/health?mod=0_0005';return false;">Health</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/law?mod=2_0079" onclick="document.location.href=nSP+'/law?mod=2_0079';return false;">Law</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/sports?mod=2_1448" onclick="document.location.href=nSP+'/sports?mod=2_1448';return false;">Sports</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/media?mod=0_0006" onclick="document.location.href=nSP+'/media?mod=0_0006';return false;">Media &amp; Marketing</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/news/industry?mod=2_0010" onclick="document.location.href=nSP+'/news/industry?mod=2_0010';return false;">News by Industry</a></div>

						<div style="padding:1px 0px 2px 7px;background-color:#EFEFEF;border-bottom:1px solid #fff;margin:0px;color:#000;" class="p12"><a style="color: #000;" class="unvisited" href="/page/columnists.html?mod=2_0140" onclick="document.location.href=nSP+'/page/columnists.html?mod=2_0140';return false;">Columnists</a></div>

<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#0253B7;" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/technology.html?mod=1_0013" onclick="document.location.href=nSP+\'/redirect/technology.html?mod=1_0013\';return false;" onmouseover="OverBar=true;OpenMenu(\'Technology\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/Technology_normal.gif" name="TechnologyIMG" border="0" alt=""/></a>'); // --></script></div>

<noscript><a href="/redirect/technology.html">Technology Main</a></noscript>

<noscript><a href="/page/gadgets.html">Gadgets</a></noscript>

<noscript><a href="/technology/telecommunications">Telecommunications</a></noscript>

<noscript><a href="/technology/e_commerce">E-Commerce/Media</a></noscript>

<noscript><a href="/page/asia_tech.html">Asia Technology</a></noscript>

<noscript><a href="/technology/europe">Europe Technology</a></noscript>

<noscript><a href="/technology/columns">Technology Columns</a></noscript>

<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#0253B7;" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/markets.html?mod=1_0021" onclick="document.location.href=nSP+\'/redirect/markets.html?mod=1_0021\';return false;" onmouseover="OverBar=true;OpenMenu(\'Markets\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/Markets_normal.gif" name="MarketsIMG" border="0" alt=""/></a>'); // --></script></div>

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

<noscript><a href="/page/asia_markets.html">Asia Markets</a></noscript>

<noscript><a href="/page/europe_markets.html">Europe Markets</a></noscript>

<noscript><a href="/page/americas_markets.html">Americas Markets</a></noscript>

<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#0253B7;" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/personaljournal?mod=1_0028" onclick="document.location.href=nSP+\'/personaljournal?mod=1_0028\';return false;" onmouseover="OverBar=true;OpenMenu(\'PersonalJournal\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/PersonalJournal_normal.gif" name="PersonalJournalIMG" border="0" alt=""/></a>'); // --></script></div>

<noscript><a href="/personaljournal">PJ Main</a></noscript>

<noscript><a href="/redirect/personalfinance.html">Personal Finance</a></noscript>

<noscript><a href="/redirect/styleandfashion.html">Fashion &amp; Style</a></noscript>

<noscript><a href="/health">Health</a></noscript>

<noscript><a href="/public/page/autos_main.html">Autos Main</a></noscript>

<noscript><a href="/personal_journal/homes">Homes</a></noscript>

<noscript><a href="/page/2_1367.html">Travel</a></noscript>

<noscript><a href="/careers">Careers</a></noscript>

<noscript><a href="/page/gadgets.html">Gadgets</a></noscript>

<noscript><a href="/personal_journal/tools">Tools</a></noscript>

<noscript><a href="/personal_journal/columns">PJ Columns</a></noscript>

<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#0253B7;" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/opinion.html?mod=1_0045" onclick="document.location.href=nSP+\'/redirect/opinion.html?mod=1_0045\';return false;" onmouseover="OverBar=true;OpenMenu(\'Opinion\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/Opinion_normal.gif" name="OpinionIMG" border="0" alt=""/></a>'); // --></script></div>

<noscript><a href="/redirect/opinion.html">Opinion Main</a></noscript>

<noscript><a href="http://forums.wsj.com/viewforum.php?f=28">Forums</a></noscript>

<noscript><a href="/public/page/letters.html">Letters</a></noscript>

<noscript><a href="/public/page/opinion_columns.html">Columnists</a></noscript>

<noscript><a href="http://www.opinionjournal.com/politicaldiary/">Political Diary</a></noscript>

<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#0253B7;" class="p11"><script type="text/javascript"><!--
document.write('<a href="' + nSP + '/redirect/leisure.html?mod=1_0051" onclick="document.location.href=nSP+\'/redirect/leisure.html?mod=1_0051\';return false;" onmouseover="OverBar=true;OpenMenu(\'Leisure\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/Leisure_normal.gif" name="LeisureIMG" border="0" alt=""/></a>'); // --></script></div>

<noscript><a href="/redirect/leisure.html">Main Page</a></noscript>

<noscript><a href="/public/page/at_leisure_weekend_journal.html">Weekend Journal</a></noscript>

<noscript><a href="/redirect/foodanddrink.html">Food &amp; Drink</a></noscript>

<noscript><a href="/redirect/styleandfashion.html">Fashion &amp; Style</a></noscript>

<noscript><a href="/page/2_1168.html">Arts &amp; Entertainment</a></noscript>

<noscript><a href="/page/books.html">Books</a></noscript>

<noscript><a href="/personal_journal/travel">Travel</a></noscript>

<noscript><a href="/public/page/autos_main.html">Autos Main</a></noscript>

	</div>




	<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
function addUrlPrefix(theUrl) {
	return (theUrl.substr(0,10) == 'javascript'||theUrl.substr(0,4) == 'http')?theUrl:(nSP + theUrl)
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

var newSection = new Array("Travel","SmallBusiness","Autos","Careers","Realestate","SmartMoney","TodaysNewspaper","MyOnlineJournal")
for(var s=0;s<newSection.length;s++){
  if(typeof SectionArray != 'undefined'&&SectionArray.length>0){
    SectionArray[SectionArray.length] = newSection[s]
  }
  eval('var '+newSection[s]+'_normal_img=new Image(131,20)')
  eval(newSection[s]+'_normal_img.src="http://s.wsj.net/img/'+newSection[s]+'_normal.gif"')
  eval('var '+newSection[s]+'_over_img=new Image(131,20)')
  eval(newSection[s]+'_over_img.src="http://s.wsj.net/img/'+newSection[s]+'_over.gif"')
}
TravelArray=new Array("Travel|/redirect/travel.html")
SmallBusinessArray=new Array("Main|http://online.wsj.com/small-business/main?mod=l_nav","Financing|http://online.wsj.com/small-business/financing?mod=l_nav","Running a Business|http://online.wsj.com/small-business/running-a-business?mod=l_nav","On Technology|http://online.wsj.com/small-business/technology?mod=l_nav","Building Awareness|http://online.wsj.com/small-business/building-awareness?mod=l_nav","Franchising|http://online.wsj.com/small-business/franchising?mod=l_nav","Small Business Link|http://online.wsj.com/small-business/small-business-link?mod=l_nav")
AutosArray=new Array("Main|/public/page/autos_main.html","Review/Ratings|/public/page/autos_review.html","Buying/Tools|/public/page/autos_tools.html","Owning/Maintaining|/public/page/autos_ownership.html")
CareersArray=new Array("Careers|http://online.wsj.com/careers/main?mod=l_nav")
RealestateArray=new Array("Realestate|http://www.realestatejournal.com/")
SmartMoneyArray=new Array("SmartMoney|http://www.smartmoney.com/indexwsj.cfm?CID=1115")
MyOnlineJournalArray=new Array("My News|"+mojURL,"My Email|/email","Keyword/Symbol Alerts|/ksemail","My Desktop Alerts|/page/alerts.html","My Account|/my_account")
TodaysNewspaperArray=new Array("U.S.|"+((loggedIn)?"/page/us_in_todays_paper.html?mod=2_0133":"/public/page/us_in_todays_paper.html?mod=2_0433"),"Europe|"+((loggedIn)?"/page/europe_in_todays_paper.html?mod=2_0134":"/public/page/europe_in_todays_paper.html?mod=2_0434"),"Asia|"+((loggedIn)?"/page/asia_in_todays_paper.html?mod=2_0135":"/public/page/asia_in_todays_paper.html?mod=2_0435"),"Past Editions|"+((pID=='2_0234'||pID=='2_0434')?'/page/2_0234.html':((pID=='2_0235'||pID=='2_0435')?'/page/2_0235.html':'/page/2_0233.html')),"Index to Businesses|/page/index_to_business.html?mod=2_0156","Index to People|/page/index_to_people.html?mod=2_0155","Journal Reports|"+((loggedIn)?"/page/journal_reports.html":"/public/page/journal_reports.html")+"?mod=2_0102","Columnists|"+((loggedIn)?"":"/public")+"/page/columnists.html","Letters|"+((loggedIn)?"":"/public")+"/page/2_0048.html","Corrections|/public/corrections?mod=2_0102")

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
var tempHTML='';
document.write('<div style="width:131px;background-color:#fff;padding:0px;margin:0px;border:0px;">')
for(var s=0;s<(newSection.length-2);s++){
	tempHTML='';
	var tempSecArray = eval(newSection[s]+"Array")
	var thisURL = addUrlPrefix(tempSecArray[0].split("|")[1])
	document.write('<div style="padding:0px;border-bottom:1px solid #efefef;background-color:#369;margin:0px;color:#0253B7;" class="p11">')
	if(tempSecArray.length>1){
		document.write('<a href="'+thisURL+'" onmouseover="OverBar=true;OpenMenu(\''+newSection[s]+'\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/'+newSection[s]+'_normal.gif" name="'+newSection[s]+'IMG" border="0" alt=""/></a>')
	} else {
		document.write('<a href="'+thisURL+'" ><img ')
		if(typeof SectionArray != 'undefined'&&SectionArray.length>0){
			document.write('onmouseover="this.src='+newSection[s]+'_over_img.src" onmouseout="this.src='+newSection[s]+'_normal_img.src" ')
		}
		document.write('src="http://s.wsj.net/img/'+newSection[s]+'_normal.gif" name="'+newSection[s]+'IMG" border="0" alt=""/></a>')
	}
	document.write('</div>')
}
document.write('</div>')
document.write('<div><img src="http://s.wsj.net/img/b.gif" alt="" border="0" height="7" width="1" /></div>')

var encounteredOpenSection = -1;
document.write('<div style="margin:1px 0px 1px 0px;border-top:1px solid #8E99B6;border-left:1px solid #8E99B6;border-right:1px solid #8E99B6;">')
for(var s=(newSection.length-2);s<newSection.length;s++){
  var isSectionOpen = false;
  var selectedPage = 0;
  var tempSecArray = eval(newSection[s]+"Array")
  tempHTML = "";
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
      temp+='<img src="http://s.wsj.net/img/'+newSection[s]+'_over.gif" name="'+newSection[s]+'IMG" border="0" alt="" style="border-bottom:1px solid #8E99B6;"/>'
      if(!isMainPage)
        temp+= '</a>'
      tempHTML=temp+'</div>'+tempHTML
    } else {
      tempHTML='<div><a href="'+addUrlPrefix(thisURL)+'" onmouseover="OverBar=true;OpenMenuNew(\''+newSection[s]+'\',\'#8E99B6\',\'#8E99B6\',\'#F8F9EF\')" onmouseout="OverBar=false;"><img src="http://s.wsj.net/img/'+newSection[s]+'_normal.gif" name="'+newSection[s]+'IMG" border="0" alt="" style="border-bottom:1px solid #8E99B6;"/></a></div>'
    }
  } else {
    tempHTML='<div><a href="'+addUrlPrefix(tempSecArray[0])+'" ><img '
    if(typeof SectionArray != 'undefined'&&SectionArray.length>0){
      tempHTML+='onmouseover="this.src='+newSection[s]+'_over_img.src" onmouseout="this.src='+newSection[s]+'_normal_img.src" '
    }
    tempHTML+='src="http://s.wsj.net/img/'+newSection[s]+'_normal.gif" name="'+newSection[s]+'IMG" border="0" alt="" style="border-bottom:1px solid #8E99B6;"/></a></div>'
  }
  document.write(tempHTML)
}
document.write('</div>')

//-->
</script>









<table  class="" cellpadding="0" cellspacing="0" border="0" style="border-right:1px solid #336699;height:100%;">
  
  <tr>
  
    <td style="">



	<div><img src="http://s.wsj.net/img/b.gif" width="1" height="10" border="0" alt="" /></div>
<div class="pb12" style="background:#5E81AB;color:#E2E2BC;padding:5px 0px 5px 5px;">Site Highlights</div><div style="padding-left:5px;">
	<span class="p11darkRed" >
		NEW!<br /> The Deal Journal Blog:<br />Updated throughout<br /> the market day with exclusive commentary, news flashes, profiles, data and more, <b>The Deal Journal</b> provides you<br /> with the up-to-the-minute take on deals and deal-makers.<br />
		<a class="pb11" href="http://blogs.wsj.com/deals/?mod=djm_shdealblog">Visit Now >></a>
	</span>
</div>
<div style="border-top:1px solid #5E81AB;"><img src="http://s.wsj.net/img/b.gif" width="1" height="1" border="0" alt="" /></div>






	<!-- adType:  -->
  	




	<!-- adType: C -->	
<div style="margin:0px 0px 15px 0px;"><script type="text/javascript">
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
</script>
</div>




	<!-- adType: C -->	
<div style="margin:0px 0px 15px 0px;"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us_subscriber2;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=120x240;ord=9287928792879287;';
if ( isSafari ) {
  tempHTML += '<iframe id="adN2_120x240" src="'+adURL+'" width="120" height="240" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:120">';
} else {
  tempHTML += '<iframe id="adN2_120x240" src="/static_html_files/blank.htm" width="120" height="240" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:120px;">';
  ListOfIframes.adN2_120x240= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us_subscriber2;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=120x240;ord=9287928792879287;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us_subscriber2;!category=;msrc=' + msrc + ';' + segQS + ';ptile=2;sz=120x240;ord=9287928792879287;" border="0" width="120" height="240" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</div>




	<!-- adType:  -->
  	




	<!-- adType:  -->
  	




	<!-- adType:  -->
  	




	<div class="adl">
	<div class="pb12" style="background:#5E81AB;color:#E2E2BC;padding:5px 0px 8px 5px;">Advertiser Links</div>
<!--	<div style="border:1px solid #ccc;background-color: #EFEFEF;margin:4px 0px 0px 0px;padding:1px;">
		<div style="width:100%;text-align:center;padding-top:4px;"><span class="p11" >Featured Advertiser </span></div>
		<div style="width:100%;height:1px;background-color:#CFCFCF;overflow:hidden;margin:1px 0px 1px 0px;"></div>
		<div style="width:100%;text-align:center;padding-top:4px;"><span class="p11" >RBS and WSJ.com present<br /><a class="b11" href="http://ad.doubleclick.net/clk;73205474;11024269;a?http://online.wsj.com/ad/rbs" target="_new">"Make it Happen"</a><br />find out how RBS and WSJ.com can help you "Make it Happen". </span></div>
		<div style="width:100%;text-align:center;padding-top:6px;"><span class="p11" ><a class="p11" href="javascript:%20window.open('http://ad.doubleclick.net/clk;73205474;11024269;a?http://online.wsj.com/ad/rbs','LM','toolbar=yes,scrollbars=yes,location=no,resizable=yes,width=760,height=525,left=20,top=15');void('');">Click Here ...</a> </span></div>
	</div>
-->
</div>






	
<!--Begin Commerce Center MODULE-->
<div class="adl">




	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;195067810;6853491;q?http://www.dlblairsweeps.com/j6357/" onclick="OpenWin(this.href,'service','','','on',true);return false;">Enter the Transamerica Golf Weekend Getaway Sweeps!</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;193255594;6853491;w?http://www.retirementdebate.com" onclick="OpenWin(this.href,'service','','','on',true);return false;">Weigh in on the Retirement Debate! Presented by WSJ & Allstate</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;172144014;6853491;d?http://online.wsj.com/public/page/2_1369.html" onclick="OpenWin(this.href,'service','','','on',true);return false;">A WSJ Monthly Fund Analysis, presented by Janus</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;172127569;11024269;e?http://ad.doubleclick.net/clk;180181205;24092796;e?http://www.diamondconsultants.com/?adsrc=WWSJ02" onclick="OpenWin(this.href,'service','','','on',true);return false;">Diamond optimizes performance</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://online.wsj.com/page/podcast.html?mod=topnav_0_0002" onclick="OpenWin(this.href,'service','','','on',true);return false;">Listen to original WSJ.com Podcasts</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;193308335;11024269;z?http://online.wsj.com/ad/accenture" onclick="OpenWin(this.href,'service','','','on',true);return false;">Accenture: Understanding China’s new consumers.</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;175560712;11024269;y?http://ibmpub.a.mms.mavenapps.net:80/mms/rt/1/site/ibmpub-wallstreetjournal-pub01-live/current/launch.html?maven_playerId=wallstreetjournal" onclick="OpenWin(this.href,'service','','','on',true);return false;">Stories of Innovation by IBM®</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;175561515;11024269;a?http://wsj.com/businessinsight" onclick="OpenWin(this.href,'service','','','on',true);return false;">The Journal Report: Business Insight</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;193282811;11024269;z?http://clk.atdmt.com/ANY/go/wllseups0370000075any/direct/01/" onclick="OpenWin(this.href,'service','','','on',true);return false;">See UPS Freight Solutions at the New UPS Whiteboard Site. </a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;146803963;6853491;t?http://online.wsj.com/public/page/mobile_download.html" onclick="OpenWin(this.href,'service','','','on',true);return false;">Get WSJ.com’s mobile application, presented on Windows Mobile®</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;189222729;11024269;g?http://clk.atdmt.com/MRT/go/wllseaub0930010031mrt/direct/01/" onclick="OpenWin(this.href,'service','','','on',true);return false;">Get a FREE Web site for your business.</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;159819745;11024269;n?http://online.wsj.com/ad/incredibleindia/" onclick="OpenWin(this.href,'service','','','on',true);return false;">Explore Incredible India: Where Diversity Delights</a>
	</div>
  



	<div class="adli">
	  <a target="service" href="http://ad.doubleclick.net/clk;193893050;11024269;c?http://www.closebiz.org/ikorb.php?func=memberarea" onclick="OpenWin(this.href,'service','','','on',true);return false;">CLOSE more sales and get more customers.</a>
	</div>
  
<div style="height:11px; font-size:2px;padding:0; margin: 0; border-top: 0px solid #fff;"></div>
</div>
<!--End Commerce Center MODULE-->





	<!-- adType:  -->
  	




	<style type="text/css">
<!--
.rssNavTitle{font-size:18px;color:#F60;padding-bottom:5px;}
.rssNavPromo{margin: 0px 6px 15px 6px;border:1px solid #0253B7;padding:13px;font-size:11px;}
.rssNavPromo ul{margin:0px;padding:8px 0px 8px 0px;list-style-type: none;}
.rssNavPromo li{width:90px;overflow:hidden;list-style-position: outside;list-style-type: none;}
-->
</style>
<div class="rssNavTitle" align="center">Inside<br /><b>WSJ.com</b></div>




<div class="rssNavPromo"><div align="center"><a href="http://online.wsj.com/autos?mod=hsn_us_autos"><img border="0" src="http://s.wsj.net/img/rssNavPromoImageAutos.gif" width="90" height="121" alt="WSJ.com: Autos Main"></a></div><ul><li>&#149;&nbsp;<a href="http://online.wsj.com/article/SB120657190798066839.html?mod=rss_Autos_Main">Mom Called and Said, 'Slow Down!'</a></li><li>&#149;&nbsp;<a href="http://online.wsj.com/article/SB120648834678863907.html?mod=rss_Autos_Main">Posh Bikes Rev Up Amid Slowdown</a></li><li>&#149;&nbsp;<a href="http://online.wsj.com/article/SB120611892936755181.html?mod=rss_Autos_Main">A European Future for U.S. Drivers?</a></li></ul><a class="unvisited" href="http://online.wsj.com/autos?mod=hsn_us_autos">
				MORE
			</a></div>



<div class="rssNavPromo"><div align="center"><a href="http://www.allthingsd.com/?siteid=wsj_hsn_atd"><img border="0" src="http://s.wsj.net/img/rssNavPromoImageAllTD.gif" width="90" height="122" alt="All Things Digital"></a></div><ul><li>&#149;&nbsp;<a href="http://feeds.allthingsd.com/~r/atd-feed/~3/259880000/">Survey: &ldquo;I'm a Mac, You're a Dork&rdquo; Campaign a Resounding Success [Digital Daily]</a></li><li>&#149;&nbsp;<a href="http://feeds.allthingsd.com/~r/atd-feed/~3/259845170/">QUOTED [Digital Daily]</a></li><li>&#149;&nbsp;<a href="http://feeds.allthingsd.com/~r/atd-feed/~3/259851612/">P2P Tax to Be Followed by Boston P2P Party? [Digital Daily]</a></li></ul><a class="unvisited" href="http://www.allthingsd.com/?siteid=wsj_hsn_atd">
				MORE
			</a></div>



<div class="rssNavPromo"><div align="center"><a href="http://www.realestatejournal.com/?rejpartner=wsj_hsn"><img border="0" src="http://s.wsj.net/img/rssNavPromoImageRealEstate.gif" width="90" height="119" alt="RealEstateJournal.com Residential Real Estate News"></a></div><ul><li>&#149;&nbsp;<a href="http://www.realestatejournal.com/buysell/tactics/20080328-beals.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage">Sellers Rely on Marketing Savvy, Incentives in Tough Climate</a></li><li>&#149;&nbsp;<a href="http://www.realestatejournal.com/buysell/mortgages/20080328-davis.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage">Hillary Clinton Pushes for More Governmental Aid to Homeowners</a></li><li>&#149;&nbsp;<a href="http://www.realestatejournal.com/buysell/tactics/20080328-hoak.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage">Should First-Time Buyers Take The Plunge in Today's Market?</a></li></ul><a class="unvisited" href="http://www.realestatejournal.com/?rejpartner=wsj_hsn">
				MORE
			</a></div>




	<div class="rssNavPromo">
	<div align="center"><a href="/documents/puzzle-archive.htm"><img src="http://s.wsj.net/img/rssNavPromoImageCrossword.gif" height="136" width="90" border="0" alt=""/></a></div>
	<div><a href="/edition/resources/applets/puzzle-current.html" class="unvisited bold">View this week's puzzle.</a> View a <a href="/public/resources/documents/puzzle-current.pdf" class="unvisited bold">PDF</a> version, and see the Journal's <a href="/documents/puzzle-archive.htm" class="unvisited bold">Crossword Archive</a> for previous puzzles and their solutions.</div>
</div>





	<img src="http://s.wsj.net/img/b.gif" width="1" height="1" border="0" alt="" id="navExtenderIMAGE" />
<div id="navExtender"></div>
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
  
</table>

<!-- end: column_1_0_0089 --></div>
	</div>	
  </div>
<!-- End nav -->


<!-- Begin body -->
  <div style="float: left; width: 854px;">
	
  
	
<!-- Begin column 3 -->
  		<div style="margin: 0px 0px 0px 14px; border:0px; padding: 0px">
  		






<div style="margin-top:3px;"><div style="width:100%;height:1px;overflow:hidden;background-color:#7898c7;margin:0px;"><img width="1" height="1" border="0" alt="" src="http://s.wsj.net/img/b.gif"></div><div style="width:1px;height:1px;overflow:hidden;"><img width="1" height="1" border="0" alt="" src="http://s.wsj.net/img/b.gif"></div><table cellspacing="0" cellpadding="0" border="0" width="100%"><tr bgcolor="#FFFFFF"><td rowspan="2" height="1"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td><td height="1"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td><td rowspan="2" height="1"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td><td rowspan="2" height="1"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td></tr><tr><td rowspan="2" width="1"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td><td rowspan="2" width="1"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td></tr><tr><td style="padding-left:5px;" valign="top" width="34%"><table cellspacing="0" border="0" width="100%"><tr><td><div><img border="0" alt="Weekend Edition" height="22" width="140" src="http://s.wsj.net/img/weekend_edition_strap.gif"></div><div class="plnTwenty" style="width:100%;text-align:left;padding-top:4px;"><a href="/article/SB120674839234873285.html?mod=home_we_banner_left">Backlash in the Gender Wars</a></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div><div class="plnElevenCompMore" style="clear:both;width:100%;text-align:left;padding-top:4px;"><a class="bold" href="/article/SB120674839234873285.html.html?mod=home_we_banner_left"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF324_pj_wom_20080328173710.gif" alt="Go to the article" width="100" height="93" align="LEFT" class="imgitboxLEFT"></a><p style="padding:0px;margin:0px;">Clinton's presidential campaign was meant to shatter the ultimate glass ceiling. But in the sometimes bitter resistance to her effort, many supporters see a backlash against women's gains. The concerns come amid signs that women's progress in the workplace has stalled or even regressed. <br>
&#8226; <a class="bold" href="http://forums.wsj.com/viewtopic.php?t=1945"><b>Your Take:</b> Women in the workplace</a></p></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td><td width="10"><img border="0" alt="" height="1" width="10" src="http://s.wsj.net/img/b.gif"></td></tr></table></td><td valign="top" width="34%"><div><img border="0" alt="" height="23" width="1" src="http://s.wsj.net/img/b.gif"></div><table cellspacing="0" border="0" width="100%"><tr><td width="10"><img border="0" alt="" height="1" width="10" src="http://s.wsj.net/img/b.gif"></td><td><div class="plnTwenty" style="width:100%;text-align:left;padding-top:4px;"><a href="/article/SB120673042293672339.html?mod=home_we_banner_left">Out to Pasture</a></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div><div class="plnElevenCompMore" style="clear:both;width:100%;text-align:left;padding-top:4px;"><a class="bold" href="/article/SB120673042293672339.html.html?mod=home_we_banner_left"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF332_pj_mil_20080328180653.gif" alt="click to read" width="100" height="93" align="LEFT" class="imgitboxLEFT"></a><p style="padding:0px;margin:0px;">India's milkmen, once respected civil servants, are caught in limbo. Sales have plummeted but government layoffs are strictly prohibited. So the deliverymen show up for work each morning and do nothing all day. The dairy's demise can be traced to the trends that have defined the expansion of modern India. <br>
&#8226; <a class="bold" href="JavaScript:OpenWin('/article/SB120648526528463725.html?mod=world_news_promo','infogrfx',760,524,'off',1,0,0,1);void('')"><b>Photos:</b> Profession Gone Sour</a></p></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td><td width="10"><img border="0" alt="" height="1" width="10" src="http://s.wsj.net/img/b.gif"></td></tr></table></td><td valign="top" width="34%"><div><img border="0" alt="" height="23" width="1" src="http://s.wsj.net/img/b.gif"></div><table cellspacing="0" border="0" width="100%"><tr><td width="10"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td><td><div class="plnTwenty" style="width:100%;text-align:left;padding-top:4px;"><a href="/article/SB120674232054172839.html?mod=home_we_banner_left">Jazzing Up the Screen</a></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div><div class="plnElevenCompMore" style="clear:both;width:100%;text-align:left;padding-top:4px;"><a class="bold" href="/article/SB120674232054172839.html.html?mod=home_we_banner_left"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF314_pj_nor_20080328171244.gif" alt="Norah Jones" width="100" height="93" align="LEFT" class="imgitboxLEFT"></a><p style="padding:0px;margin:0px;">Six years after jazzy pop songs made her a household name, Norah Jones is moving into the movies. By diving into a film with an avant-garde director, she's acting like the hustling indie artist she was before fame swept her up -- and standing out from the countless musicians who have crossed over into film. <br>
&#8226; <a class="bold" href="/article/SB120664373033969179.html?mod=home_we_banner_left"><b>Q&A with Norah Jones</b></a></p></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td></tr></table></td></tr><tr><td height="1" colspan="5" bgcolor="#FFFFFF"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></td></tr></table><div style="width:100%;height:1px;overflow:hidden;background-color:#7898c7;margin-top:8px;"></div><span style="line-height: 8px; font-size: 8px;"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"><br></span></div><div><img alt="" border="0" width="1" height="20" src="http://s.wsj.net/img/b.gif"></div>

  		</div>
 <!-- End column 3 --> 		
  	

<!-- Begin left column -->
	<div  style="float:left; width: 333px;">
		<div style="clear: left; width: 319px; margin: 0px 0px 0px 14px;">








<!-- Start Breaking News -->
<span id="breakingNewsContent">
	<!--ContentStart//-->
	<!--DivID:breakingNewsContent://-->

<!--ContentEnd//-->
</span>
<!-- End Breaking News -->



	<div id="ledeContent"><!--ContentStart//--><!--DivID:ledeContent://-->




<div class="arialResize"></div>




	<!--ContentEnd//--></div>




	   




	<map name="SubscribeNowMap"><area shape="rect" coords="100,1,178,18" href="https://commerce.wsj.com/reg/promo/6BCWCE_1007"></map>
<div style="margin-top:15px;background-image: url(http://s.wsj.net/img/subscibeNowBK.gif);background-repeat: repeat-x;background-position: center center;" align="center"><img src="http://s.wsj.net/img/subscibeNow.gif" width="178" height="18" alt="" border="0" usemap="#SubscribeNowMap" /></div>
<img align="left" src="http://s.wsj.net/img/whatsNewsSmall.gif" width="151" height="22" border="0" alt="Whats News" style="padding-top:15px" />
<div style="clear:both;"><img src="http://s.wsj.net/img/b.gif" width="1" height="1" alt="" border="0" /></div>




	<div id="collTimestampContent"><!--ContentStart//--><!--DivID:collTimestampContent://-->





 
<div class="plnNine" style="padding:3px 0px 2px 0px;border-top:1px solid #999; border-bottom:1px solid #999;margin:5px 0px 5px 0px;color:#333;text-align:left;"><span class="nobr">As of <span id="collectionTimeStamp">9:56:00 PM EDT Sat, March 29, 2008</span> </span></div>




	<!--ContentEnd//--></div>



<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="9"><img src="http://s.wsj.net/img/b.gif" border="0" height="9" width="1" alt="" /></td>
</tr></table>



	<div id="whatsnewContent"><!--ContentStart//--><!--DivID:whatsnewContent://-->

<!-- This module has no content -->
<!-- This module has no content -->




<a name="medium_head_home_whats_news_us"></a>
<table cellpadding="0" width="100%" cellspacing="0" border="0"><tr valign="top"><td valign="top" ><div style="background:url(http://s.wsj.net/img/b.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="0" align="left" height="1" alt="" />
			<!-- Summary article type=U.S. Business News Page=U.S. Home--><a href="/article/SB120675834275673863.html?mod=hpp_us_whats_news" class="p18 georgia">Sweeping Changes in Paulson Plan</a></div><div  class="arialResize" ><a class="arial" href="/article/SB120675834275673863.html?mod=hpp_us_whats_news"><img src="http://s.wsj.net/public/resources/images/OB-BF358_Paulso_20080328231508.jpg" vspace="0" hspace="0" border="0"  align="left" class="imglftsum" alt="[Go to the article]" height="93" width="85"/></a>
<div class="arial">Treasury Secretary Henry Paulson plans Monday to present a complete reworking of the U.S. regulatory system for finance. The blueprint, which would merge some agencies and broaden the authority of the Fed, is aimed at revamping a system of oversight built piecemeal since the Civil War.&nbsp; <span class="red arial" style="white-space:nowrap;">8:12 p.m.</span></div>
<div style="padding:4px 0 5px 0;">
<div class="wnlistitem p11"><span class="p11">&bull;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/economics/2008/03/29/paulson-capital-markets-turmoil-is-priority">Q&amp;A With Paulson</a> | <a class="arial" href="http://online.wsj.com/public/resources/documents/WSJ_20080328_Paulson.pdf">Executive Summary Text</a></div>
<div class="wnlistitem p11"><span class="p11">&bull;</span>&nbsp;<a class="arial" href="/article/SB120682843791774761.html?mod=hpp_us_whats_news"><b>Treasury Plan Garners Mixed Response</b></a></div>
<div class="wnlistitem p11"><span class="p11">&bull;</span>&nbsp;<a class="arial" href="/article/SB120682889675974767.html?mod=hpp_us_whats_news"><b>Treasury Backs Federal Insurance Regulation</b></a></div>
<div class="wnlistitem p11"><span class="p11">&bull;</span>&nbsp;<a class="arial" href="http://blogs.wsj.com/washwire/2008/03/29/obama-calls-treasury-plan-inadequate/?mod=WSJBlog"><b>Washington Wire:</b> Obama Calls Plan 'Inadequate' </a></div>
</div>
</div><div class="clearer">&nbsp;</div></td></tr></table><!-- headlineSummariesFooter --><span style="line-height:5px; font-size:5px;"><br />&nbsp;<br /></span>




	<!--ContentEnd//--></div>




	<div id="whatsnew2Content"><!--ContentStart//--><!--DivID:whatsnew2Content://-->





<a name="home_whats_news_us"></a>
<table cellpadding="0" width="100%" cellspacing="0" border="0"><tr valign="top"><td valign="top" ><div style="background:url(http://s.wsj.net/img/b.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="0" align="left" height="1" alt="" />
			<!-- Summary article type=World News Page=U.S. Home--><a href="/article/SB120681915464474581.html?mod=hpp_us_whats_news" class="p18 georgia">U.S. Says 16 Gunmen Killed in Basra</a></div><div  class="arialResize" ><div class="arial">A U.S. warplane attacked snipers in the southern city of Basra, killing at least 16 suspected militants after Iraqi troops came under heavy fire, the U.S. military said. Earlier, Prime Minister Maliki vowed to remain in Basra until government forces wrest control from militias.&nbsp; <span class="red arial" style="white-space:nowrap;">9:30 p.m.</span></div>
</div><div class="clearer">&nbsp;</div><span style="line-height:5px; font-size:5px;"><br />&nbsp;<br /></span><div style="background:url(http://s.wsj.net/img/b.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="0" align="left" height="1" alt="" />
			<!-- Summary article type=Economy Page=U.S. Home--><a href="/article/SB120679977389874405.html?mod=hpp_us_whats_news" class="p18 georgia">World Panel Urges Risk Disclosure</a></div><div  class="arialResize" ><div class="arial">The world's top financial authorities urged financial institutions to fully expose their risks to bring about the return of financial market confidence.</div>
</div><div class="clearer">&nbsp;</div></td></tr></table>









<div style="padding-top:15px;">
<a name="home_whats_news_us"></a><div style="padding-bottom:17px;"><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120680096362174393.html?mod=hpp_us_whats_news" class="arialResize" >Bush Backs Stimulus Effort</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120674015029472775.html?mod=hpp_us_whats_news" class="arialResize" >Judge Sides With IAC's Diller</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120681072199574457.html?mod=hpp_us_whats_news" class="arialResize" >Voting Closes in Zimbabwe Election</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120675856370773951.html?mod=hpp_us_whats_news" class="arialResize" >Lehman May Be Fraud Victim</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120672798287172277.html?mod=hpp_us_whats_news" class="arialResize" >Northwest Reworks Merger Plan</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120671093586671677.html?mod=hpp_us_whats_news" class="arialResize" >Housing Woes Shake Fremont</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120674895705973321.html?mod=hpp_us_whats_news" class="arialResize" >BlackRock Sets IPO for Fund</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120675186936073477.html?mod=hpp_us_whats_news" class="arialResize" >Vegas Casino Plan Goes Awry</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120671871940671939.html?mod=hpp_us_whats_news" class="arialResize" >GM Is Hit Hard by Parts Strike</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120671274797471773.html?mod=hpp_us_whats_news" class="arialResize" >Boeing Tries to Address 787 Snags</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120674061047372717.html?mod=hpp_us_whats_news" class="arialResize" >Lawyer Pleads Guilty to Fraud</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120670656497671569.html?mod=hpp_us_whats_news" class="arialResize" >Spending Weak; Inflation Muted</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120672457122272165.html?mod=hpp_us_whats_news" class="arialResize" >Burger King to Offer Whopper Bar</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120672890827072299.html?mod=hpp_us_whats_news" class="arialResize" >UBS Plans Auction-Rate Price Cuts</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120669875197271405.html?mod=hpp_us_whats_news" class="arialResize" >Beijing Opens Tibet to Diplomats</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120670178397671455.html?mod=hpp_us_whats_news" class="arialResize" >Weak Consumer Sinks Stocks</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120671921700272013.html?mod=hpp_us_whats_news" class="arialResize" >EU Opens Review of Nokia Map Bid</a></div></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><div style="background:url(http://s.wsj.net/img/hp_whats_news_round_bullet.gif) no-repeat; "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" /><a href="/article/SB120671920685371985.html?mod=hpp_us_whats_news" class="arialResize" >Bush Set to Name SEC Democrats</a></div></td></tr></table>
<!-- MORE --><!-- Footer --><!-- whats news Footer -->
<div style="padding-top:10px;" class="p12">
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
	document.write('<div class="p12"><a href="/news/us_business?mod='+WhatsNewsFooterMod+'"><img src="http://s.wsj.net/img/loginArrow.gif" border="0"> LOG IN to see complete coverage</a></div>')
}
//-->
</script>
</div>

</div>

</div>




	<!--ContentEnd//--></div>



<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="7"><img src="http://s.wsj.net/img/b.gif" border="0" height="7" width="1" alt="" /></td>
</tr></table>



	<script>
var modVal=(loggedIn)?"hps_us_pageone_more":"hpp_us_pageone_more";
var itpPath=(loggedIn)?"/page/2_0133.html":"/public/page/2_0433.html"
document.write('<map name="itpImgMap">')
 document.write(' <area shape="rect" coords="166,42,272,58" href="/page/2_0233.html?mod=' + modVal +' " target="_top" alt="Go to Past Editions">')
  document.write('<area shape="rect" coords="49,42,165,58" href="' + itpPath + '?mod=' + modVal +' " target="_top" alt="Go to Todays Newspaper">')
document.write('</map>')
document.write('<img width="316" height="65" border="0" src="http://s.wsj.net/img/hp_itp_page_one_2.gif" usemap="#itpImgMap" alt="Todays Newspaper"  />')
</script>




<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="8"><img src="http://s.wsj.net/img/b.gif" border="0" height="8" width="1" alt="" /></td>
</tr></table>




<a name="PageOne_1"></a>
<table cellpadding="0" width="100%" cellspacing="0" border="0"><tr valign="top"><td valign="top" ><div style="background:url(http://s.wsj.net/img/hp_whats_news_square_bullet.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" />
			<!-- Summary article type=Leader (U.S.) Page=U.S. Home--><a href="/article/SB120671093586671677.html?mod=hpp_us_pageone" class="bold80">Housing Woes Shake Fremont</a></div><div  class="arialResize" ><div >Regulators ordered mortgage lender Fremont General to raise new capital within 60 days or sell its banking unit. (<a class="" href="http://wsj.com/public/resources/documents/fremont20080328.pdf">FDIC directive</a>)</div>
<div style="padding:4px 0 5px 0;">
<div class=""><span class="p11">&bull;</span>&nbsp;<a class="" href="http://blogs.wsj.com/marketbeat/2008/03/28/fdic-to-fremont-you-need-money/?mod=WSJBlog"><b>MarketBeat:</b> FDIC to Fremont: You Need Money</a></div>
</div>
</div><div class="clearer">&nbsp;</div><span style="line-height:7px; font-size:7px;"><br />&nbsp;<br /></span><div style="background:url(http://s.wsj.net/img/hp_whats_news_square_bullet.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" />
			<!-- Summary article type=Leader (U.S.) Page=U.S. Home--><a href="/article/SB120670656497671569.html?mod=hpp_us_pageone" class="bold80">Spending Weak; Inflation Muted</a></div><div  class="arialResize" ><div >Consumer spending rose just 0.1% last month before inflation, despite a 0.5% gain in incomes. After inflation, consumption was flat, casting shadows on the economic outlook. J.C. Penney was the latest retailer to cut its forecast.</div>
</div><div class="clearer">&nbsp;</div><span style="line-height:7px; font-size:7px;"><br />&nbsp;<br /></span><div style="background:url(http://s.wsj.net/img/hp_whats_news_square_bullet.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" />
			<!-- Summary article type=Leader (U.S.) Page=U.S. Home--><a href="/article/SB120674839234873285.html?mod=hpp_us_pageone" class="bold80">Backlash in the Gender Wars</a></div><div  class="arialResize" ><div >Clinton's presidential campaign was meant to shatter the ultimate glass ceiling. But in the sometimes bitter resistance to her effort, many supporters see a backlash against women's gains. The concerns come amid signs that women's progress in the workplace has stalled or even regressed.</div>
</div><div class="clearer">&nbsp;</div><span style="line-height:7px; font-size:7px;"><br />&nbsp;<br /></span><div style="background:url(http://s.wsj.net/img/hp_whats_news_square_bullet.gif) no-repeat;  "><img src="/img/b.gif" border="0" vspace="0" hspace="0" width="12" align="left" height="1" alt="" />
			<!-- Summary article type=A-hed Page=U.S. Home--><a href="/article/SB120673042293672339.html?mod=hpp_us_pageone" class="bold80">India's Milkmen Bide Their Time</a></div><div  class="arialResize" ><div >India's milkmen, once respected civil servants, are caught in limbo. Sales have plummeted but government layoffs are strictly prohibited. So the deliverymen show up for work each morning and do nothing all day. The dairy's demise can be traced to the trends that have defined the expansion of modern India.</div>
<div style="padding:4px 0 5px 0;">
<div class=""><span class="p11">&bull;</span>&nbsp;<a class="" href="/article/SB120648526528463725.html" onclick="OpenWin('/article/SB120648526528463725.html?mod=world_news_promo','infogrfx',760,524,'off',1,0,0,1);void('');return false;"><b>Photos:</b> Profession Gone Sour</a></div>
</div>
</div><div class="clearer">&nbsp;</div></td></tr></table>



<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="9"><img src="http://s.wsj.net/img/b.gif" border="0" height="9" width="1" alt="" /></td>
</tr></table>



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
 	document.write('<tr><td class="p11"><a href="/login?mod='+logInMod+'" class="unvisited"><img src="http://s.wsj.net/img/loginArrow.gif" border="0"> LOG IN to access Today\'s Print Edition</a></td></tr>')
 }  
 document.write('</table>')
</script>




<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="27"><img src="http://s.wsj.net/img/b.gif" border="0" height="27" width="1" alt="" /></td>
</tr></table>



	<script type="text/javascript">
<!--

document.write('<script type="text/javascript" src="http://online.wsj.com/javascript/MSNController.js?'+Math.random()*1000+'"></'+'script>');

//-->
</script>

<script type="text/javascript">
<!--
if((typeof sponsorshipRendered)=='undefined' && !turnOffMSNAds){
	document.write('<script type="text/javascript" src="http://s.wsj.net/javascript/MSNMappingInfo.js">'+'</'+'script'+'>');
}
//-->
</script>

<script type="text/javascript">
<!--

if((typeof sponsorshipRendered)=='undefined' && !turnOffMSNAds){

		if((typeof pID)=='undefined'||pID==null){pID=''}

		if((typeof adKeyword)=='undefined'||adKeyword==null){adKeyword=''}

		pageID = pID?pID:'';
		parDomain = window.location.toString();

		var adInfoObj = getAdInfo(pageID,parDomain);

		var msn_adunit_style  = adInfoObj.adst?adInfoObj.adst:"text-align:center";

		if(msn_adunit_style.indexOf('left') == -1)
		document.write('<div style="'+msn_adunit_style+'" id="MSNOutterDiv">');

}

//-->
</script>

<script type="text/javascript">
<!--

function GetArg(N){;var i=0,u="".concat(window.location),u=(u.indexOf("?")>-1)?u.split("?")[1]:"",u=(u.indexOf("#")>-1)?u.split("#")[0]:u,u=(u.charAt(u.length-1)=="&")?u.substring(0,u.length-1):u;N+="=";while(i<u.length){;var j=i+(N.length);if(u.substring(i,j)==N){;return unescape(u.substring(j,(u.indexOf("&",j)==-1)?u.length:u.indexOf("&",j)));};i=u.indexOf("&",i)+1;if(i==0){;break;};};return null;}

if((typeof turnOffMSNAds)=='undefined'){turnOffMSNAds=false;}

if((typeof sponsorshipRendered)=='undefined' && !turnOffMSNAds){

	isLatest = "New";

	if(GetArg("adId") != null && GetArg("adwd") != null && GetArg("adht") != null){

		microsoft_adunitid=GetArg("adId");
		microsoft_adunit_width=GetArg("adwd");
		microsoft_adunit_height=GetArg("adht");
		microsoft_adunit_keywordhints=GetArg("adkwh");

		document.write('<script type="text/javascript" src="https://adsyndication.msn.com/delivery/getads.js?'+Math.random()*1000+'"></'+'script>');

	}else{

		if((typeof pID)=='undefined'||pID==null){pID=''}

		if((typeof adKeyword)=='undefined'||adKeyword==null){adKeyword=''}

		pageID = pID?pID:'';
		parDomain = window.location.toString();

		if(parDomain.indexOf('setup')!=-1){
			document.write('<tr><td colspan="3">');
		}


		microsoft_adunitid= adInfoObj.adid;
		microsoft_adunit_width=adInfoObj.adwd;
		microsoft_adunit_height=adInfoObj.adht;
		microsoft_adunit_keywordhints=adKeyword?adKeyword:"";

		if(msn_adunit_style.indexOf('left') != -1)
		document.write('<div style="'+msn_adunit_style+'" id="MSNInnerDiv">');

		document.write('<script type="text/javascript" src="https://adsyndication.msn.com/delivery/getads.js?'+Math.random()*1000+'"></'+'script>');

		if(msn_adunit_style.indexOf('left') != -1)
		document.write('</div>');

		if(parDomain.indexOf('setup')!=-1){
			document.write('</td></tr>');
		}

		}

	var sponsorshipRendered=true;

}

//-->
</script>

<script type="text/javascript">
<!--
if((typeof sponsorshipRendered)=='undefined' && !turnOffMSNAds){
		if(msn_adunit_style.indexOf('left') == -1)
		document.write('</div>');
}
//-->
</script>

		</div>
	</div> 
<!-- End left column -->

	
<!-- Begin right column -->
	<div  style="float:left; width: 521px;">
		<div style="clear: left; width: 508px; margin: 0px 0px 0px 13px;">




<center>
	 
<div style="text-align:center;padding:0px 0px 10px 0px;">
 	
 	
<span id="adSpanT"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=508x1;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="adT" src="'+adURL+'" width="508" height="1" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:508">';
} else {
  tempHTML += '<iframe id="adT" src="/static_html_files/blank.htm" width="508" height="1" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:508px;">';
  ListOfIframes.adT= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=508x1;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=508x1;ord=1820182018201820;" border="0" width="508" height="1" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</span>
</div>
</center>























<!-- Begin body -->
  <div style="background-color:#F2F7FB;clear: left; width: 506px; border: 1px solid #CCC;">
	
  
	
<!-- Begin column 3 -->
  		<div style="margin: 0px; border:0px; padding: 0px">
  		



	<script type="text/javascript">
    searchBoxID = 'QuoteSearchBoxPublic';
    resultContainerID = 'symbolCompleteResultsPublic';
    searchGoButtonID = 'SearchQuoteGoButtonPublic';
</script>
<link href="http://s.wsj.net/css/autocomplete.css" type="text/css" rel="stylesheet" />
<script type="text/javascript">
<!--
if (typeof(initInfoComplete) != 'undefined' && YAHOO.util.Event){YAHOO.util.Event.onAvailable('QuoteSearchBoxPublic', initInfoComplete); }// -->
</script>
<div style="background-color:#FFF;height:52px;background-image: url(http://s.wsj.net/img/freeTodayBk.gif);background-repeat: repeat-x;background-position: center bottom;border-bottom:1px solid #CCC;">
	<div style="height:52px;background-image: url(http://s.wsj.net/img/freeTodayTitle.gif);background-repeat: no-repeat;background-position: 9px 17px;">
		<div style="padding: 10px 16px 0px 25px;border:0px;float:right;">
			<div class="searchQuoteSection">
				<div class="symbolCompleteContainerPublic" align="left">
					<div><input type="text" name="QuoteSearchBoxPublic" id="QuoteSearchBoxPublic" value="Enter Symbol(s) or Keyword(s)" maxlength = "80" class="unUsed" style="width:175px;" onfocus="searchFieldOnFocus(this);setFocused(this);" onblur="setFocused(null);" autocomplete="off" />
					<img align="absmiddle" id="SearchQuoteGoButtonPublic" src="http://s.wsj.net/img/hprightarrowNew.gif" style="padding-right:3px;" width="34" height="18" border="0"  alt="go"/>
					</div>
            				<div id="symbolCompleteResultsPublic" class="freesymbolCompleteResults"></div>
            			</div>
				<!--
            			<div id="SearchQuoteGoButtonPublic" style="padding:0px;margin:0px;" class="largebutton"><div style="margin:0px;padding:0px;" class="leftcapoff"></div><div style="margin:0px;padding:0px;" class="buttonoff"><p style="margin:0px;padding:0px;"><a style="margin:0px;padding:0px;" href="http://online.wsj.com/" onfocus="setFocused('');" onblur="setFocused(null);">GO</a></p></div><div style="margin:0px;padding:0px;" class="rightcapoff"></div></div>
				//-->
	            		<div style="clear:both"></div>
	            		<div style="margin:0px;padding:0px;">
	            			<div class="quoteSearchLinks" style="margin:0px;padding:0px;">
	            			<script type="text/javascript"><!--
					nSP = '';
					document.write('<'+'a href="'+nSP+'/public/search">Advanced Search<'+'/a>');
					document.write(' | <'+'a href="'+nSP+'/quotes/main.html">Symbol Lookup<'+'/a>');
					//-->
					</script>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>




<table cellpadding="0" cellspacing="0" border="0" bgcolor="#F2F7FB" width="100%"><tr>
<td height="10"><img src="http://s.wsj.net/img/b.gif" border="0" height="10" width="1" alt="" /></td>
</tr></table>







<table  class="" cellpadding="0" cellspacing="0" border="0" style="background-color:#F2F7FB;width:100%;padding:0px;margin:0px;">
  
  <tr>
  
    <td style="padding:0px 5px 0px 10px ;border-right:1px solid #CCC;vertical-align: top;">


<div class="arialResize"><table id="carouselContainer" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td style="display:none;" id="carouselItem1"><div class="arial" style="clear:both;"><a class="bold" href="/article/SB120655950055166131.html?mod=hpp_us_inside_today"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF360_fay_vi_20080329131915.jpg" alt="Go to story" width="177" height="115" align="NONE" class="imgitboxNONE"></a><div style="border:0px solid #CCC;height:78px;padding:3px;overflow:hidden;"><p style="padding-top:0px;margin-top:0px;"><a class="bold" href="/article/SB120655950055166131.html?mod=hpp_us_inside_today">Author Q&A</a><br>
Former commissioner Fay Vincent on the "golden age" of baseball. <br>
&#8226; <a class="bold" href="JAVASCRIPT:OpenWin('/article/SB120673088169372345.html','wsjpopup','760','524','off',true,0,0,true);void('')"><b>Slideshow</b></a></p></div></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td><td style="display:none;" id="carouselItem2"><div class="arial" style="clear:both;"><a class="bold" href="http://link"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF117_032708_20080327152944.jpg" alt="robot" width="177" height="115" align="NONE" class="imgitboxNONE"></a><div style="border:0px solid #CCC;height:78px;padding:3px;overflow:hidden;"><p style="padding-top:0px;margin-top:0px;"><a class="bold" href="JAVASCRIPT:OpenWin('http://link.brightcove.com/services/link/bcpid1336737864/bclid1341026943/bctid1477205896','wsjpopup','988','550','off',true,0,0,true);void('')">Part 4: The Battle Begins</a><br>
WSJ's Andy Jordan braces for Team 694's first shot at winning a robot battle.  <br>
&#8226; Parts <a class="bold" href="JAVASCRIPT:OpenWin('http://link.brightcove.com/services/link/bcpid1336737864/bclid1341026943/bctid1473707223','wsjpopup','988','550','off',true,0,0,true);void('')">1</a> | <a class="bold" href="JAVASCRIPT:OpenWin('http://link.brightcove.com/services/link/bcpid1336737864/bclid1341026943/bctid1474198138','wsjpopup','988','550','off',true,0,0,true);void('')">2</a> | <a class="bold" href="JAVASCRIPT:OpenWin('http://link.brightcove.com/services/link/bcpid1336737864/bclid1341026943/bctid1475735980','wsjpopup','988','550','off',true,0,0,true);void('')">3</a></p></div></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td><td style="display:none;" id="carouselItem3"><div class="arial" style="clear:both;"><a class="bold" href="/article/SB120673297868272437.html.html?mod=hpp_us_inside_today"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF348_IT_Hot_20080328202820.gif" alt="Hot Dog icon" width="177" height="115" align="NONE" class="imgitboxNONE"></a><div style="border:0px solid #CCC;height:78px;padding:3px;overflow:hidden;"><p style="padding-top:0px;margin-top:0px;"><a class="bold" href="/article/SB120673297868272437.html?mod=hpp_us_inside_today">America's Top Dog</a><br>
From Los Angeles to Boston, a nationwide search for the nation's best hot dog. <br>
&#8226; <a class="bold" href="http://forums.wsj.com/viewtopic.php?t=1943"><b>Forum</b></a></p></div></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td><td style="display:none;" id="carouselItem4"><div class="arial" style="clear:both;"><a class="bold" href="http://online.wsj.com/page/2_1367.html"><img border="0" src="http://s.wsj.net/public/resources/images/OB-BF284_mendoz_20080328155959.gif" alt="mendoza" width="177" height="115" align="NONE" class="imgitboxNONE"></a><div style="border:0px solid #CCC;height:78px;padding:3px;overflow:hidden;"><p style="padding-top:0px;margin-top:0px;"><a class="bold" href="http://online.wsj.com/page/2_1367.html">Malbec Country</a><br>
Those seeking a Napa alternative have embraced Mendoza, Argentina. <a class="bold" href="JavaScript:OpenWin('/article/SB120672915934572325.html?mod=your_money_hidden_1_general_hs','infogrfx',760,524,'off',1,0,0,1);void('')"><b>Photos</b></a><br>
&#8226; <a class="bold" href="http://online.wsj.com/travel"><b>WSJ's new Travel page</b></a></p></div></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></td></tr></table><div style="height:16px;border-left:0px solid #CCC;border-right:0px solid #CCC;border-bottom:2px solid #7d9ac2;"><a style="float:left;padding:2px 0px 0px 3px;" onclick="com.dowjones.hpCarousel.backword();return false;" href="#" class="bold p10 unvisited">&lt;&lt; PREV</a><a style="float:right;padding:2px 3px 0px 0px" onclick="com.dowjones.hpCarousel.forward();return false;" href="#" class="bold p10 unvisited">NEXT &gt;&gt;</a></div><div><img alt="" border="0" width="1" height="20" src="http://s.wsj.net/img/b.gif"></div><script charset="ISO-8859-1" language="javascript" type="text/javascript">$import("com.dowjones.hpCarousel");</script></div><div class="arialResize"><div><img alt="" width="1" height="10" border="0" src="http://s.wsj.net/img/b.gif"></div><div class="arial" style="clear:both;"><p style="padding-top:0px;margin-top:0px;"><a class="bold" href="http://blogs.wsj.com/iraq/2008/03/28/a-friend-celebrates-a-birth-but-curfew-leaves-him-stuck-at-hospital/?mod=WSJBlog">Baghdad Life</a><br>
A friend celebrates a birth, but can't leave the hospital.</p><p style="padding-top:0px;margin-top:0px;"><a class="bold" href="/article/SB120674219704372883.html?mod=hpp_us_inside_today">The Gear Guy Speaks</a><br>
Ex-USGA expert says golfers pay too much for too little.</p><p style="padding:0px;margin:0px;"><a class="bold" href="/article/SB120675216306373487.html?mod=hpp_us_inside_today">Money Hunt</a><br>
Look beyond Treasurys for income. <i>Green Thumb</i></p></div><div class="clearer"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></div>



  </td>
      
  
    <td style="padding:0px 5px 0px 5px;vertical-align: top;">



	<script type="text/javascript" language="javascript" charset="ISO-8859-1">
var pzn_enable_right_click_search = "";
var pzn_user_type = "";
var pzn_user_to_industries = "";
var pzn_user_to_companies = "";
var pzn_user_to_columns = "";
var pzn_user_to_topics = "";
var pzn_user_to_indexes = "";
var pzn_user_to_charts = "";
var pzn_userto_topnews = "";
var pzn_edition_option = "";

if(typeof pzn_enable_right_click_search == "string"){
SetCookie('RCSEARCH',((pzn_enable_right_click_search=="n")?"off":"on")+"|"+pzn_user_to_charts+"|"+pzn_user_to_indexes,'365d+');
}
</script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
document.write('<'+'s'+'c'+'r'+'i'+'p'+'t s'+'r'+'c'+'="/public/resources/live/0_0024_JSON.'+'j'+'s'+'?a='+GenRandomNum()+'"'+'>'+'<'+'/'+'s'+'c'+'r'+'i'+'p'+'t'+'>')
// -->
</script>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var d = {'0_0012':'DJI~NCM~SPX~HIUX~USTYN','0_0002_public':'DJI~NCM~SPX~HIUX~USTYN','0_0013':'DJI~NCM~STOXX50~FST~DAX30','0_0014':'NIKKE~HKS~FST~DJI~NCM','0_0002':'0_0002_public','0_0003':'0_0013','0_0004':'0_0014'};d=(d[pID].indexOf('~')>-1)?d[pID]:d[d[pID]];d=d.split("~");
var c = d;
var marketsOnScreen = c
function reloadMarkets(){
  new WSJAXRequest(
    new _arg('VERB','GET'),
    new _arg('URL','/public/resources/live/0_0024_JSON.js?a='+GenRandomNum()),
    new _arg('HEADERS',new Array(new Array('Connection','close'))),
    new _arg('PROCESS',
    function( myObject ) {
      if (myObject.readyState == 4) {
        var r="".concat(myObject.responseText);r=trim(r.substring(0,(r.length-119)))
        try{
          eval(r)
          try{
            for(var i=0;i<marketsOnScreen.length;i++){
              if(typeof myMDObj[marketsOnScreen[i]]=='object') {
            	  document.getElementById(marketsOnScreen[i]+"_o").innerHTML=((myMDObj[marketsOnScreen[i]].o!="*")?"":"*")
            	  if(marketsOnScreen[i]!="USTYN"){
            	  	document.getElementById(marketsOnScreen[i]+"_l").innerHTML=myMDObj[marketsOnScreen[i]].l
            	  	document.getElementById(marketsOnScreen[i]+"_c").innerHTML=myMDObj[marketsOnScreen[i]].c
            	  } else {
            	  	myMDObj[marketsOnScreen[i]].t=myMDObj[marketsOnScreen[i]].t.replace(".0","")
            	  	document.getElementById(marketsOnScreen[i]+"_l").innerHTML=myMDObj[marketsOnScreen[i]].y
            	  	document.getElementById(marketsOnScreen[i]+"_c").innerHTML=myMDObj[marketsOnScreen[i]].t
            	  }
            	  document.getElementById(marketsOnScreen[i]+"_p").innerHTML=myMDObj[marketsOnScreen[i]].p+"%"
            	  var s=new Array("changePosTen","changeNegTen","p10");s=""+s[myMDObj[marketsOnScreen[i]].s]+""
            	  document.getElementById(marketsOnScreen[i]+"_c").className=s
            	  document.getElementById(marketsOnScreen[i]+"_p").className=s
              }
            }
            //document.getElementById('marketsChartPZN').src="".concat(document.getElementById('marketsChartPZN').src)
            document.getElementById('marketsChartPZN').src="".concat(document.getElementById('marketsChartPZN').src+'&amp;a='+Math.round(Math.random()*10000000));
            setTimeout('reloadMarkets()',120*1000)
          }catch(e){
          }
        }catch(e){
        }
      }
    })
  )
}
//-->
</script>
<!-- Markets Module -->
<div style="border-bottom:1px solid #CCC; padding:0px;margin-bottom:3px;"><a href="/redirect/markets.html?mod=hps_us_indexes" class="arial bold" style="font-size:16px;color:#FF6600;">Markets</a></div>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
function ApplyLinkStyle(o){;for(var i=0;i<5;i++){var l=document.getElementById('indexlnk'+i);if(l){;l.className=(i!=o)?"unvisited":"pumpkinIndex";};}return false;}
// -->
</script>
<table width="303" cellspacing="0" cellpadding="0" border="0"><tr><td valign="top"><table width="195" cellspacing="0" cellpadding="0" border="0">
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
var h="",im="",s=new Array("changePosTen","changeNegTen","p10")
for(var i=0;i<c.length;i++){
  if(typeof myMDObj[c[i]]=='object') {
    myMDObj[c[i]].t=myMDObj[c[i]].t.replace(".0","")
    if(im==""){;im=myMDObj[c[i]].i;};
    h+='<tr><td valign="top" class="p10" style="border-bottom:1px solid #CCC;padding-bottom:1;padding-top:1px;"><span style="white-space:nowrap;">'
    if(myMDObj[c[i]].i!=""){;h+='<a id="indexlnk'+i+'" href="http://chart.bigcharts.com/custom/wsjie/wsjie-sm'+myMDObj[c[i]].i+'" class="'+((im==myMDObj[c[i]].i)?"pumpkinIndex":"unvisited")+'" onclick="ApplyLinkStyle('+i+');document.images.marketsChartPZN.src=this.href;return false;">';}
    h+=myMDObj[c[i]].a+'<span id="'+c[i]+'_o">'+((myMDObj[c[i]].o!="*")?"":"*")+'</span>'
    if(myMDObj[c[i]].i!=""){;h+='</a>';}
    h+='</span></td><td valign="top" align="right" style="border-bottom:1px solid #CCC;padding-bottom:1;padding-top:1px;" class="p10"><span style="white-space:nowrap;"><span id="'+c[i]+'_l">'+((c[i]!="USTYN")?myMDObj[c[i]].l:myMDObj[c[i]].y)+'</span></span></td><td valign="top" align="right" class="'+s[myMDObj[c[i]].s]+'" style="border-bottom:1px solid #CCC;padding-bottom:1;padding-top:1px;"><span style="white=space:nowrap;"><span id="'+c[i]+'_c">'+((c[i]!="USTYN")?myMDObj[c[i]].c:myMDObj[c[i]].t)+'</span></span></td><td valign="top" align="right" class="'+s[myMDObj[c[i]].s]+'" style="border-bottom:1px solid #CCC;padding-bottom:1;padding-top:1px;"><span style="white-space:nowrap;"><span id="'+c[i]+'_p">'+myMDObj[c[i]].p+'%</span></span></td></tr>'
  }
}
document.write(h)
//-->
</script>
<tr><td valign="top" class="greyTen" style="padding-top:1px;">* at close</td><td valign="top" align="right" colspan="3" style="padding-top:1px;" class="p10"><span style="white-space:nowrap;">Source: Dow Jones, <a href="/public/page/reuters_popup.html?mod=hps_us_indexes" onclick="OpenWin(this.href,'Reuters_Disclaimer',290,240,'off',true);return false;" class="unvisited">Reuters</a></span></td></tr><tr><td valign="top" colspan="4" style="padding-top:1px;" class="p10"><a href="/setup/todaysmarkets_setup?mod=hps_us_indexes" class="unvisited">Edit Markets Preference</a></td></tr></table></td>

<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
document.write('<td width="97" valign="top"><a href="/marketsdata"><img id="marketsChartPZN" src="http://chart.bigcharts.com/custom/wsjie/wsjie-sm'+im+'" border="0" width="97" height="91" style="margin-left:10px;margin-top:2px;"/></a></td>')
//-->
</script>
</tr></table>
<script type="text/javascript" language="javascript" charset="ISO-8859-1">
<!--
document.write('<div class="p10" style=" border-top:1px solid #CCC;"><a href="'+((loggedIn)?"":"/public")+'/page/0_0810.html?page=0_0810&mod=hps_us_indexes" class="unvisited">Quotes &amp; Company Research</a> | <a href="/page/mdc/2_0515-mdc_index-1.html?mod=hps_us_indexes" class="unvisited">Data Center</a> | <a href="/pj/PortfolioDisplay.cgi?mod=hps_us_indexes" class="unvisited">Portfolio</a></div>')
// -->
</script>





	 
<div style="padding:3px 0px 9px 0px;text-align:center;">
 	
 	
<div style="text-align:center;" class="boldGreyNine">advertisement</div>
	
<span id="adv300x250"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';ptile=2;sz=300x250;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="adR" src="'+adURL+'" width="300" height="250" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:300">';
} else {
  tempHTML += '<iframe id="adR" src="/static_html_files/blank.htm" width="300" height="250" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:300px;">';
  ListOfIframes.adR= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';ptile=2;sz=300x250;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';ptile=2;sz=300x250;ord=1820182018201820;" border="0" width="300" height="250" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</span>
</div>




<div class="arialResize"></div>
</td>
      
  </tr>
  
</table>





	<!--
<center style="padding-top:10px;padding-bottom:10px;background-color:#f2f7fb;"><div id="hpminor" style="height:60px;width:487px;text-align:center;font-size:1.6em;background-color:#cac;clear:both;">this is minor</div></center>
-->
<script type="text/javascript"><!--
var wl=window.location,wlh=wl.hostname,wlp=wl.pathname,idev=(wlh=='idev.online.wsj.com'),pub=(wlp.indexOf('/public')!=-1),trgt='';
var midr=(idev?{bd:'02/11/2008',ed:'02/11/2008'}:{bd:'02/11/2008',ed:'02/11/2008'});
var trgt=(pub?'us':'us_subscriber'),tempHTML = '';
if(inDateRange(midr.bd,midr.ed)){
  var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/'+trgt+';!category=;msrc=' + msrc + ';' + segQS + ';sz=487x60;ord=19590195901959019590;';
  if ( isSafari ) {
    tempHTML += '<iframe id="adMinor" src="'+adURL+'" width="487" height="60" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:487px;height:60px;">';
  } else {
    tempHTML += '<iframe id="adMinor" src="/static_html_files/blank.htm" width="487" height="60" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:487px;height:60px;">';
    ListOfIframes.adMinor= adURL;
  }
  tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/'+trgt+';!category=;msrc=' + msrc + ';' + segQS + ';sz=487x60;ord=19590195901959019590;" target="_new">';
  tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/'+trgt+';!category=;msrc=' + msrc + ';' + segQS + ';sz=487x60;ord=19590195901959019590;" border="0" width="487" height="60" vspace="0" alt="Advertisement" /></a><br /></iframe>';
  document.write('<'+'center'+' style="'+(pub?'background-color:#f2f7fb;':'')+'clear:both;"><'+'div style="text-align:center;padding:10px 0px 10px 0px;"'+'><'+'span id="adSpanMinor"'+'>');
  document.write(tempHTML);
  document.write('<'+'/'+'span'+'><'+'/'+'div'+'><'+'/'+'center'+'>');
}
//--></script>




<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="12"><img src="http://s.wsj.net/img/b.gif" border="0" height="12" width="1" alt="" /></td>
</tr></table>


<table cellpadding="0" cellspacing="0" border="0" bgcolor="#7D9AC2" width="100%"><tr>
<td height="2"><img src="http://s.wsj.net/img/b.gif" border="0" height="2" width="1" alt="" /></td>
</tr></table>


<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="5"><img src="http://s.wsj.net/img/b.gif" border="0" height="5" width="1" alt="" /></td>
</tr></table>


<div style="padding: 0px 10px 0px 10px"><table width="100%" border="0" cellpadding="0" cellspacing="0"><tr><td valign="top"><table cellspacing="0" cellpadding="0" border="0"><tr height="9"><td></td></tr><tr><td style="white-space:nowrap;" class="p12"><a onclick="OpenWin('/public/page/8_0004.html','videoplayer',993,550,'off',true,0,0,true);return false;" href="/video" style="font-size:16px;color:#FF6600;" class="arial bold">Video Center</a>
								|
								<a onclick="OpenWin('/public/page/8_0004.html','videoplayer',993,550,'off',true,0,0,true);return false;" href="/video" class="p11 unvisited">
									See All Video Offerings	
								</a></td></tr></table></td><td width="5">&nbsp;</td><td valign="top" width="100%"><table width="100%" cellspacing="0" cellpadding="0" border="0"><tr height="4"><td></td></tr><tr><td class="p11" align="right">&nbsp;</td></tr><tr height="6"><td></td></tr><tr style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:bottom" valign="top" height="1"><td width="100%"></td></tr></table></td></tr></table></div><div style="clear:both;"><img border="0" alt="" height="10" width="1" src="http://s.wsj.net/img/b.gif"></div><div style="
			float:left;
			
	      				padding-left:5px;
	      			"><div><a href="/video?bctid=1478148492" onclick="OpenWin('/public/page/8_0004.html?bctid=1478148492','videoplayer',993,550,'off',true,0,0,true);return false;"><img border="0" alt="Cayne Cashes Out" width="120" height="90" src="http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1478143689_2aa1f8cf828210147d4e429a59482a408716f473.jpg?pubId=86240652"></a></div><div style="width:120px;" align="center"><a class="p11 unvisited" href="/video?bctid=1478148492" onclick="OpenWin('/public/page/8_0004.html?bctid=1478148492','videoplayer',993,550,'off',true,0,0,true);return false;"><div style="height:30px;width:120px;">Cayne Cashes Out</div><img border="0" alt="" src="http://s.wsj.net/img/hpVideoPlayBtnNew.gif" height="25" width="58" style="margin:6px 0px 0px 0px;"></a></div></div><div style="
			float:left;
			
	      				border-left:1px solid #CCC;
	      				padding-left:2px;
	      				margin-left:2px;
	      				"><div><a href="/video?bctid=1477205728" onclick="OpenWin('/public/page/8_0004.html?bctid=1477205728','videoplayer',993,550,'off',true,0,0,true);return false;"><img border="0" alt="Vytorin Results Disappoint" width="120" height="90" src="http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1478190627_9ac90259e70c5220f4bc25e1c1f570eb79603aac.jpg?pubId=86240652"></a></div><div style="width:120px;" align="center"><a class="p11 unvisited" href="/video?bctid=1477205728" onclick="OpenWin('/public/page/8_0004.html?bctid=1477205728','videoplayer',993,550,'off',true,0,0,true);return false;"><div style="height:30px;width:120px;">Vytorin Results Disappoint</div><img border="0" alt="" src="http://s.wsj.net/img/hpVideoPlayBtnNew.gif" height="25" width="58" style="margin:6px 0px 0px 0px;"></a></div></div><div style="
			float:left;
			
	      				border-left:1px solid #CCC;
	      				padding-left:2px;
	      				margin-left:2px;
	      				"><div><a href="/video?bctid=1475736003" onclick="OpenWin('/public/page/8_0004.html?bctid=1475736003','videoplayer',993,550,'off',true,0,0,true);return false;"><img border="0" alt="Banks Offer Bitter Homeowners Money" width="120" height="90" src="http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1478204341_cea343d002787ff8a0f67a2395baffa346c7da3e.jpg?pubId=86240652"></a></div><div style="width:120px;" align="center"><a class="p11 unvisited" href="/video?bctid=1475736003" onclick="OpenWin('/public/page/8_0004.html?bctid=1475736003','videoplayer',993,550,'off',true,0,0,true);return false;"><div style="height:30px;width:120px;">Banks Offer Bitter Homeowners Money</div><img border="0" alt="" src="http://s.wsj.net/img/hpVideoPlayBtnNew.gif" height="25" width="58" style="margin:6px 0px 0px 0px;"></a></div></div><div style="
			float:left;
			
	      				border-left:1px solid #CCC;
	      				padding-left:2px;
	      				margin-left:2px;
	      				
							padding-right:4px;
						"><div><a href="/video?bctid=1474198186" onclick="OpenWin('/public/page/8_0004.html?bctid=1474198186','videoplayer',993,550,'off',true,0,0,true);return false;"><img border="0" alt="BBC Launches New Strategy" width="120" height="90" src="http://brightcove.vo.llnwd.net/d5/unsecured/media/86240652/86240652_1473736558_558241c82248d910aa5015eb777d477e09b6b477.jpg?pubId=86240652"></a></div><div style="width:120px;" align="center"><a class="p11 unvisited" href="/video?bctid=1474198186" onclick="OpenWin('/public/page/8_0004.html?bctid=1474198186','videoplayer',993,550,'off',true,0,0,true);return false;"><div style="height:30px;width:120px;">BBC Launches New Strategy</div><img border="0" alt="" src="http://s.wsj.net/img/hpVideoPlayBtnNew.gif" height="25" width="58" style="margin:6px 0px 0px 0px;"></a></div></div><div style="padding:0px 10px 0px 10px"><div style="border-bottom:1px solid #CCC;"><img border="0" alt="" height="1" width="1" src="http://s.wsj.net/img/b.gif"></div></div>



<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="12"><img src="http://s.wsj.net/img/b.gif" border="0" height="12" width="1" alt="" /></td>
</tr></table>



	<div style="padding:0px 10px 0px 10px;clear:both;">
<table cellspacing="0" cellpadding="0" border="0" width="100%">
	<tr>
		<td valign="top">
			<table border="0" cellpadding="0" cellspacing="0">

				<tr height="9">
					<td></td>
				</tr>
				<tr>

					<td class="p12" style="white-space:nowrap;">
						<a class="arial bold" style="font-size:16px;color:#FF6600;" href="/page/8_0019.html">Blogs</a>
						|
						<a class="p11 unvisited" href="/page/most_popular.html#MostPopBlogs">
							View Most Popular Posts
						</a>
						|
						<a class="p11 unvisited" href="/page/8_0019.html">
							View Complete List of Blogs
						</a>

					</td>
				</tr>
			</table>
		</td>
		<td width="5">&nbsp;</td>

		<td width="100%" valign="top">
			<table border="0" cellpadding="0" cellspacing="0" width="100%">
				<tr height="4">

					<td></td>
				</tr>
				<tr>
					<td align="right" class="p11">&nbsp;</td>
				</tr>

				<tr height="6"><td></td></tr>
				<tr height="1" valign="top" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:bottom">
					<td width="100%"></td>

				</tr>
			</table>
		</td>
	</tr>
</table>
<div style="clear:both;"><img src="http://s.wsj.net/img/b.gif" width="1" height="10" alt="" border="0" /></div>
</div>



<div style="margin:0px 10px 0px 10px;border-bottom:1px solid #CCC;padding-bottom:10px;"><table width="100%" border="0"><tr><td width="50%" valign="top"><div style="padding-right:8px; border-right:1px solid #CCC;"><div style="padding-bottom:10px;"><span class="p10 darkRed" style="text-transform:uppercase;">Economics Blog </span><span class="greyTen">March 29, </span><span class="greyTen"> 2:54 PM</span><br><a style="font-family: Arial; font-size:12px; color:#0253B7; text-decoration:none;" href="http://blogs.wsj.com/economics/2008/03/29/paulson-capital-markets-turmoil-is-priority/?mod=WSJBlog?mod=homeblogmod_economicsblog">Paulson: Capital Markets Turmoil Is Priority</a></div><div style="padding-bottom:10px;"><span class="p10 darkRed" style="text-transform:uppercase;">Deal Journal </span><span class="greyTen">March 28, </span><span class="greyTen"> 6:23 PM</span><br><a style="font-family: Arial; font-size:12px; color:#0253B7; text-decoration:none;" href="http://blogs.wsj.com/deals/2008/03/28/do-stock-options-turn-you-into-a-bad-person/?mod=WSJBlog?mod=homeblogmod_dealjournal">Do Stock Options Turn You Into A Bad Person?</a></div><div style="padding-bottom:10px;"><span class="p10 darkRed" style="text-transform:uppercase;">Law Blog </span><span class="greyTen">March 28, </span><span class="greyTen"> 5:49 PM</span><br><a style="font-family: Arial; font-size:12px; color:#0253B7; text-decoration:none;" href="http://blogs.wsj.com/law/2008/03/28/scalia-to-news-media-focus-on-the-text/?mod=WSJBlog?mod=homeblogmod_lawblog">Scalia to News Media: Focus on the Text!</a></div></div></td><td width="50%" valign="top"><div style="padding-left:8px;"><div style="padding-bottom:10px;"><span class="p10 darkRed" style="text-transform:uppercase;">Washington Wire </span><span class="greyTen">March 29, </span><span class="greyTen"> 8:10 PM</span><br><a style="font-family: Arial; font-size:12px; color:#0253B7; text-decoration:none;" href="http://blogs.wsj.com/washwire/2008/03/29/obama-calls-treasury-plan-inadequate/?mod=WSJBlog?mod=homeblogmod_washingtonwire">Obama Calls Treasury Plan 'Inadequate'</a></div><div style="padding-top:6px;"><span class="p10 darkRed" style="text-transform:uppercase;">Business Technology </span><span class="greyTen">March 28, </span><span class="greyTen"> 7:00 PM</span><br><a style="font-family: Arial; font-size:12px; color:#0253B7; text-decoration:none;" href="http://blogs.wsj.com/biztech/2008/03/28/hacked-macs-myspace-founder-loses-friends-cyber-squatting/?mod=WSJBlog?mod=homeblogmod_businesstechnology">Hacked Macs; MySpace Founder Loses Friends; Cyber Squatting</a></div><div style="padding-top:6px;"><span class="p10 darkRed" style="text-transform:uppercase;">Buzzwatch </span><span class="greyTen">March 28, </span><span class="greyTen"> 5:49 PM</span><br><a style="font-family: Arial; font-size:12px; color:#0253B7; text-decoration:none;" href="http://blogs.wsj.com/buzzwatch/2008/03/28/daily-diversion-the-best-line-rider-yet/?mod=WSJBlog?mod=homeblogmod_buzzwatch">Daily Diversion: The Best Line Rider Yet</a></div></div></td></tr></table></div>



<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%"><tr>
<td height="25"><img src="http://s.wsj.net/img/b.gif" border="0" height="25" width="1" alt="" /></td>
</tr></table>
  		</div>
 <!-- End column 3 --> 		
  	

<!-- Begin left column -->
	<div  id ="left_rr"  style="padding-left:10px;float:left; width:242px; border-right: 1px solid #CCC; overflow: hidden; background-color:#F2F7FB;">
		<div style="clear: left; width: 232px; margin: 0px; overflow: hidden; background-color:#F2F7FB;">









<div style="padding:0px;">
<div style="padding-bottom:17px;"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="/personaljournal?mod=hpp_us_personal_journal">Personal Journal</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="/personaljournal?mod=hpp_us_personal_journal">more &gt;</a>

		</td>
	</tr>
</table>
</tr><tr><td colspan="4" height="1px" style="background-color:#ccc;"></td></tr><tr><td colspan="4" height="7px"></td></tr></table><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120674335305672877.html?mod=hpp_us_personal_journal" class="p11" >Money on the Vine</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120674199730372867.html?mod=hpp_us_personal_journal" class="p11" >Interior Design: Kitchens by Crayola</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120675400426973631.html?mod=hpp_us_personal_journal" class="p11" >Passing On Inherited Can Be Trying</a></td></tr></table>
<!-- MORE --><!-- Footer -->
</div>

</div>









<div style="padding-top:15px;">
<a name="money_page_left_hs"></a><div style="padding-bottom:17px;"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="/redirect/personalfinance.html?mod=hpp_us_personal_finance">Personal Finance</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="/redirect/personalfinance.html?mod=hpp_us_personal_finance">more &gt;</a>

		</td>
	</tr>
</table>
</tr><tr><td colspan="4" height="1px" style="background-color:#ccc;"></td></tr><tr><td colspan="4" height="7px"></td></tr></table><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120658400885267681.html?mod=hpp_us_personal_finance" class="p11" >When to Exercise Options</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120658383783567635.html?mod=hpp_us_personal_finance" class="p11" >Household Wealth Rises as Retirees Age</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120658613157067827.html?mod=hpp_us_personal_finance" class="p11" >Bargain Growth Stocks</a></td></tr></table>
<!-- MORE --><!-- Footer -->
</div>

</div>













<div style="padding-top:15px;">
<a name="Careers_7"></a><div style="padding-bottom:17px;"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="http://online.wsj.com/careers/main?mod=hpp_us_careerjournal">Careers</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="http://online.wsj.com/careers/main?mod=hpp_us_careerjournal">more &gt;</a>
		</td>
	</tr>
</table>
</tr><tr><td colspan="4" height="1px" style="background-color:#ccc;"></td></tr><tr><td colspan="4" height="7px"></td></tr></table><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120645763855762561.html?mod=hpp_us_leisure" class="p11" >How I Got Here: From Ad Man to Granola Guru</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120657740153967147.html?mod=hpp_us_leisure" class="p11" >Pregnancy-Discrimination Claims Increase</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120611296397054965.html?mod=hpp_us_leisure" class="p11" >Career Q&amp;A: When a New Hire Earns More Than You</a></td></tr></table>
<!-- MORE --><!-- Footer -->
</div>

</div>




<center>
	 
<div style="text-align:center;padding:14px 0px 20px 0px;">
 	
 	
<span id="adSpanE"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=230x192;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="adE" src="'+adURL+'" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230">';
} else {
  tempHTML += '<iframe id="adE" src="/static_html_files/blank.htm" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230px;">';
  ListOfIframes.adE= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=230x192;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us1;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=230x192;ord=1820182018201820;" border="0" width="230" height="192" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</span>
</div>
</center>










<div style="padding-top:15px;">
<div style="padding-bottom:17px;"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="/redirect/leisure.html?mod=hpp_us_leisure">Leisure</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="/redirect/leisure.html?mod=hpp_us_leisure">more &gt;</a>

		</td>
	</tr>
</table>
</tr><tr><td colspan="4" height="1px" style="background-color:#ccc;"></td></tr><tr><td colspan="4" height="7px"></td></tr></table><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120673297868272437.html?mod=hpp_us_leisure" class="p11" >America's Top Dog</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120674340028272915.html?mod=hpp_us_leisure" class="p11" >A Different Kind of Slavery</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120674232054172839.html?mod=hpp_us_leisure" class="p11" >Norah Jones Jazzes Up the Big Screen</a></td></tr></table>
<!-- MORE --><!-- Footer -->
</div>

</div>



<div id="rjHeadlines" style="padding-top:8px;"><table style="padding-bottom:5px;" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td valign="bottom" style="white-space:nowrap;padding-right:1px;"><a style="font-size:16px;color:#FF6600;" class="arial bold" href="http://www.realestatejournal.com?rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com?rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Real Estate</a></td><td style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px" width="100%">&nbsp;</td><td valign="bottom" style="white-space:nowrap;padding:0px 0px 2px 1px;"><a class="unvisited p11" href="http://www.realestatejournal.com?rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com?rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">go to site &gt;</a></td></tr></table><div style="margin-bottom: 8px">
									&bull;
									<a href="http://www.realestatejournal.com/buysell/tactics/20080328-beals.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com/buysell/tactics/20080328-beals.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Sellers Rely on Marketing Savvy, Incentives in Tough Climate</a><p></p></div><div style="margin-bottom: 8px">
									&bull;
									<a href="http://www.realestatejournal.com/buysell/mortgages/20080328-davis.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp" onclick="OpenWin('http://www.realestatejournal.com/buysell/mortgages/20080328-davis.html?mod=RSS_Real_Estate_Journal&rejrss=frontpage&rejpartner=wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">Hillary Clinton Pushes for More Governmental Aid to Homeowners</a><p></p></div><div style="margin-bottom: 15px"></div><div style="margin-bottom: 20px"><form id="homeSearchForm" target="homeSearchFormtarget" method="get" action="http://rej.careercast.com/properties/search/results.php" onSubmit="return OpenWin('http://rej.careercast.com/properties/search/results.php', 'homeSearchFormtarget');"><span style="padding-right:3px;" class="searchheader">FIND A HOME</span><input name="qKeywords" value="" type="text" size="15" max="75" class="p11"><input style="padding-left:3px;" width="34" type="image" height="18" border="0" src="/img/hprightarrowNew.gif" name="imageField"><input type="hidden" name="qAction" value="search"><input type="hidden" name="qTerms" value="sell"></form></div></div>



<div id="atdHeadlines" style="padding-top:8px;"><table style="padding-bottom:5px;" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td valign="bottom" style="white-space:nowrap;padding-right:1px;"><a style="font-size:16px;color:#FF6600;" class="arial bold" href="http://www.allthingsd.com?siteid=wsj_hpp_atd" onclick="OpenWin('http://www.allthingsd.com?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">AllThingsDigital</a></td><td style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px" width="100%">&nbsp;</td><td valign="bottom" style="white-space:nowrap;padding:0px 0px 2px 1px;"><a class="unvisited p11" href="http://www.allthingsd.com?siteid=wsj_hpp_atd" onclick="OpenWin('http://www.allthingsd.com?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">go to site &gt;</a></td></tr></table><div style="margin-bottom: 8px">
									&bull;
									<a href="http://feeds.allthingsd.com/~r/atd-feed/~3/259880000/?siteid=wsj_hpp_atd" onclick="OpenWin('http://feeds.allthingsd.com/~r/atd-feed/~3/259880000/?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">Survey: &ldquo;I'm a Mac, You're a Dork&rdquo; Campaign a Resounding Success </a><p></p></div><div style="margin-bottom: 8px">
									&bull;
									<a href="http://feeds.allthingsd.com/~r/atd-feed/~3/259845170/?siteid=wsj_hpp_atd" onclick="OpenWin('http://feeds.allthingsd.com/~r/atd-feed/~3/259845170/?siteid=wsj_hpp_atd', '', '911', '656', '', '', '59', '45', '');return false;">QUOTED </a><p></p></div><div style="margin-bottom: 20px"></div></div>



<div id="smHeadlines" style="padding-top:8px;"><table style="padding-bottom:5px;" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td valign="bottom" style="white-space:nowrap;padding-right:1px;"><a style="font-size:16px;color:#FF6600;" class="arial bold" href="http://www.smartmoney.com/indexwsj.cfm?CID=1108&siteid=rss_wsj_hpp" onclick="OpenWin('http://www.smartmoney.com/indexwsj.cfm?CID=1108&siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">SmartMoney</a></td><td style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px" width="100%">&nbsp;</td><td valign="bottom" style="white-space:nowrap;padding:0px 0px 2px 1px;"><a class="unvisited p11" href="http://www.smartmoney.com/indexwsj.cfm?CID=1108&siteid=rss_wsj_hpp" onclick="OpenWin('http://www.smartmoney.com/indexwsj.cfm?CID=1108&siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">go to site &gt;</a></td></tr></table><div style="margin-bottom: 8px">
									&bull;
									<a href="http://www.smartmoney.com/etf-outlook/index.cfm?story=20080328-daily-etf-wrap-up&cid=1108&" onclick="OpenWin('http://www.smartmoney.com/etf-outlook/index.cfm?story=20080328-daily-etf-wrap-up&cid=1108&', '', '911', '656', '', '', '59', '45', '');return false;">Financial, Retail ETFs Drop on Poor Data (Daily ETF Wrap-Up)</a><p></p></div><div style="margin-bottom: 8px">
									&bull;
									<a href="http://www.smartmoney.com/mag/index.cfm?story=april2008-cut-medical-bills&cid=1108&" onclick="OpenWin('http://www.smartmoney.com/mag/index.cfm?story=april2008-cut-medical-bills&cid=1108&', '', '911', '656', '', '', '59', '45', '');return false;">Under the Knife: Cutting Medical Bills (SmartMoney Magazine)</a><p></p></div><div style="margin-bottom: 20px"></div></div>



<div id="mwHeadlines" style="padding-top:8px;"><table style="padding-bottom:5px;" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td valign="bottom" style="white-space:nowrap;padding-right:1px;"><a style="font-size:16px;color:#FF6600;" class="arial bold" href="http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp" onclick="OpenWin('http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">MarketWatch</a></td><td style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px" width="100%">&nbsp;</td><td valign="bottom" style="white-space:nowrap;padding:0px 0px 2px 1px;"><a class="unvisited p11" href="http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp" onclick="OpenWin('http://www.marketwatch.com/news/default.asp?siteid=rss_wsj_hpp', '', '911', '656', '', '', '59', '45', '');return false;">go to site &gt;</a></td></tr></table><div style="margin-bottom: 8px">
									&bull;
									<a href="http://www.marketwatch.com/enf/rss.asp?guid=%7BA19E0038-7952-4629-8FB7-0562713E751C%7D&siteid=rss_wsj_hpp&rss=1&" onclick="OpenWin('http://www.marketwatch.com/enf/rss.asp?guid=%7BA19E0038-7952-4629-8FB7-0562713E751C%7D&siteid=rss_wsj_hpp&rss=1&', '', '911', '656', '', '', '59', '45', '');return false;">Treasury secretary to call for sweeping regulation overhaul</a><p></p></div><div style="margin-bottom: 8px">
									&bull;
									<a href="http://www.marketwatch.com/enf/rss.asp?guid=%7BE9FCBFC5-6FCC-4217-AE15-B01E54D12175%7D&siteid=rss_wsj_hpp&rss=1&" onclick="OpenWin('http://www.marketwatch.com/enf/rss.asp?guid=%7BE9FCBFC5-6FCC-4217-AE15-B01E54D12175%7D&siteid=rss_wsj_hpp&rss=1&', '', '911', '656', '', '', '59', '45', '');return false;">Stocks in focus for Monday</a><p></p></div><div style="margin-bottom: 20px"></div></div>

		</div>
	</div> 
<!-- End left column -->

	
<!-- Begin right column -->
	<div  id ="right_rr"  style="padding-left:10px;float:left; width: 243px; background-color:#F2F7FB;  ">
		<div style="clear: left; width: 233px; margin: 0px; overflow: hidden; background-color:#F2F7FB;">









<div style="padding:0px;">
<a name="AutosChannelMain_Review"></a><div style="padding-bottom:17px;"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="/autos?mod=hpp_us_autos">Autos</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="/autos?mod=hpp_us_autos">more &gt;</a>

		</td>
	</tr>
</table>
</tr><tr><td colspan="4" height="1px" style="background-color:#ccc;"></td></tr><tr><td colspan="4" height="7px"></td></tr></table><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120657190798066839.html?mod=hpp_us_autos" class="p11" >Mom Called and Said, 'Slow Down!'</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120648834678863907.html?mod=hpp_us_autos" class="p11" >Posh Bikes Rev Up Amid Slowdown</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120611892936755181.html?mod=hpp_us_autos" class="p11" >A European Future for U.S. Drivers?</a></td></tr></table>
<!-- MORE --><!-- Footer -->
</div>

</div>









<div style="padding-top:15px;">
<a name="SmallBusinessMain_1"></a><div style="padding-bottom:17px;"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="/small-business/main?mod=hpp_us_entrepreneur">Small Business</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="/small-business/main?mod=hpp_us_entrepreneur">more &gt;</a>

		</td>
	</tr>
</table>
</tr><tr><td colspan="4" height="1px" style="background-color:#ccc;"></td></tr><tr><td colspan="4" height="7px"></td></tr></table><table width="100%" cellspacing="0" cellpadding="0" border="0"><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120671239240971743.html?mod=hpp_us_entrepreneur" class="p11" >A Restaurant That Serves Up Farm-Fresh Dishes</a></td></tr><!-- results from db --><tr><td style="padding-bottom:6px;"><span class="p13">&bull;&nbsp;</span><a href="/article/SB120662637357468619.html?mod=hpp_us_entrepreneur" class="p11" >Candidates Stump With Start-Ups, Run With New Tech</a></td></tr></table>
<!-- MORE --><!-- Footer -->
</div>

</div>





<a name="2_1077_1"></a>
<table cellpadding="0" width="100%" cellspacing="0" border="0"><tr><table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td style="white-space:nowrap;padding-right:1px;" valign="bottom">
			<a class="bold arial" style="font-size:16px;color:#FF6600;" href="/public/page/2_1077.html?mod=hpp_us_interactives">Interactives</a>
		</td>
		<td width="100%" style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px">&nbsp;</td>
		<td style="white-space:nowrap;padding:0px 0px 2px 1px;" valign="bottom">
			<a class="unvisited p11" href="/public/page/2_1077.html?mod=hpp_us_interactives">more &gt;</a>

		</td>
	</tr>
</table>
<div class="p11" style="padding:10px 0px 10px 0px;">ANALYSIS OF NEWS AND TRENDS</div>
</tr><tr><td height="1" bgcolor="#cccccc"></td></tr><tr><td height="7"></td></tr><tr valign="top"><td valign="top" >
			<div class="arialResize">
<div style="" class="decoClearer"><a class="arialInner" href="/public/resources/documents/info-LHASAMAP080314.html" onclick="OpenWin('/public/resources/documents/info-flash07.html?project=LHASAMAP080314&amp;h=530&amp;w=980&amp;hasAd=1&amp;settings=LHASAMAP080314','LHASAMAP080314','980','700','off','true',40,10);void('');return false;"><img src="http://s.wsj.net/public/resources/images/it_olympic-china08282006160216.gif" vspace="0" hspace="0" border="0"  align="left" class="imglftsum" alt="[Go to feature]" height="48" width="44"/></a>
<div class="p11"><a class="arialInner" href="/public/resources/documents/info-LHASAMAP080314.html" onclick="OpenWin('/public/resources/documents/info-flash07.html?project=LHASAMAP080314&amp;h=530&amp;w=980&amp;hasAd=1&amp;settings=LHASAMAP080314','LHASAMAP080314','980','700','off','true',40,10);void('');return false;"><b>Anatomy of an Uprising</b></a>: Map of the antigovernment protests that spread from Lhasa, Tibet, to other parts of western China, posing a serious challenge to China ahead of the Olympics. Also: <a class="arialInner" href="/article/SB120550234193436617.html" onclick="OpenWin('/article/SB120550234193436617.html','infogrfx',760,524,'off',1,0,0,1);void('');return false;"><b>Photos</b></a> of the protests, and <a class="arialInner" href="/article/SB120594738619749009.html" onclick="OpenWin('/article/SB120594738619749009.html?mod=world_news_promo','infogrfx',760,524,'off',1,0,0,1);void('');return false;"><b>young Tibetan activists</b></a>. <i>03/20/08</i></div>
<br/>
<div class="p11"></div>

</div></div></td></tr></table>



<div xmlns:content="http://purl.org/rss/1.0/modules/content/" id="" style="margin-top: 10px; border-bottom: 1px solid #5a87b0"><table style="padding-bottom:5px;" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td valign="bottom" style="white-space:nowrap;padding-right:1px;"><a style="font-size:16px;color:#FF6600;" class="bold arial" href="/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos" onclick="OpenWin('/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos','infogrfx',760,524,'off',1,0,0,1);return false;">
						Today's Photos
					</a></td><td style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px" width="100%">&nbsp;</td><td valign="bottom" style="white-space:nowrap;padding:0px 0px 2px 1px;"><a class="unvisited p11" href="/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos" onclick="OpenWin('/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos','infogrfx',760,524,'off',1,0,0,1);return false;">more &gt;</a></td></tr></table><div style="width:231px;background-color:#FFFFFF;border: 1px solid #CCCCCC;margin-bottom:20px"><div style="width:211px;margin:10px 10px 2px 10px;overflow:hidden"><a class="bold" href="JAVASCRIPT:OpenWin('/article/SB120667211891670841.html','wsjpopup','760','524','off',true,0,0,true);void('')" onclick="JAVASCRIPT:OpenWin('/article/SB120667211891670841.html','wsjpopup','760','524','off',true,0,0,true);void('');return false;
				"><img border="0px" src="http://s.wsj.net/public/resources/images/OB-BF229_tibetf_20080328111932.jpg" alt="See more" width="211" height="158" align="LEFT" class="imgitboxLEFT" padding="0px"></a></div><div style="width:211px;margin:0px 10px 10px 10px;border-top:1px solid #000000;font-size:11px;font-color:#990000;padding-top:2px"><span class="phototext">Tibetan exiles are loaded into a van to be taken for detention as...
						</span><span class="pb11"><a href="/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos" onclick="OpenWin('/article/infogrfx_photos_of_the_day.html?mod=hpp_us_photos','infogrfx',760,524,'off',1,0,0,1);return false;">

						more
					</a></span></div></div></div>



<div id="podcasts" style=""><table style="padding-bottom:5px;" border="0" cellspacing="0" cellpadding="0" width="100%"><tr><td valign="bottom" style="white-space:nowrap;padding-right:1px;"><a style="font-size:16px;color:#FF6600;" class="bold arial" href="/public/page/0_0813.html?mod=hpp_us_podcasts">
						Podcasts & RSS
					</a></td><td style="background-image:url(http://s.wsj.net/img/stap_bk_underline.gif);background-repeat:repeat-x;background-position:0px 0px" width="100%">&nbsp;</td><td valign="bottom" style="white-space:nowrap;padding:0px 0px 2px 1px;"><a class="unvisited p11" href="/public/page/0_0813.html?mod=hpp_us_podcasts">more &gt;</a></td></tr></table><div class="bsubstrap" style="margin:10px 0px 10px 0px">
				FEATURED PODCAST
		</div><div style="float:left"><img src="/public/resources/media/it_podcast.gif" style="width:44px; height: 48px;"></div><div><div class="regtext"><div>&bull;&nbsp;<a class="bold" href="http://podcast.mktw.net/wsj/audio/20080326/pod-wsjauto/pod-wsjauto.mp3"><span style="p11">Car Cast:</span></a> David Patton and Mathew Passy on Ford's selling Jaguar and Land Rover to India's Tata.</div></div></div><div style="margin:15px 0px 4px 0px"><span class="bsubstrap"><a href="/public/page/0_0813.html?mod=hpp_us_podcasts">

				RSS NEWS FEEDS
			</a></span><span class="onlinepipe">&nbsp;|&nbsp;</span><span class="onlinehmore"><a href="/public/page/0_0813.html?mod=hpp_us_podcasts">
				MORE
			</a></span></div><script charset="ISO-8859-1" src="/javascript/com/dowjones/utils/rssSelector.js" language="javascript" type="text/javascript"></script><div class="p11" style="padding-bottom:3px"><img alt="Get RSS" src="http://s.wsj.net/img/feed-icon.gif" border="0" style="vertical-align:middle;"><span class="black">&nbsp;Get Feed U.S.:&nbsp;</span><a onclick="com.dowjones.utils.rssSelector.show(this);return false" href="/xml/rss/3_7011.xml" class="unvisited">What's News</a></div><div class="p11" style="margin-bottom:20px"><img alt="Get RSS" src="http://s.wsj.net/img/feed-icon.gif" border="0" style="vertical-align:middle;"><span class="black">&nbsp;Get Feed U.S.:&nbsp;</span><a onclick="com.dowjones.utils.rssSelector.show(this);return false" href="/xml/rss/3_7014.xml" class="unvisited">Business</a></div></div>




<center>
	 
<div style="text-align:center;padding:0px 0px 14px 0px;">
 	
 	
<span id="adSpanF"><script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us2;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=230x192;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="adF" src="'+adURL+'" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230">';
} else {
  tempHTML += '<iframe id="adF" src="/static_html_files/blank.htm" width="230" height="192" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:230px;">';
  ListOfIframes.adF= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us2;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=230x192;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us2;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=230x192;ord=1820182018201820;" border="0" width="230" height="192" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</span>
</div>
</center>


		</div>
	</div> 
<!-- End right column -->
	

	
<!-- Begin column 4 -->
	<div style="clear:both;text-align:center;">
		







	</div>
<!-- End column 4 -->
	

	
  </div>	  
<!-- End body -->  









<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%">
	<tr><td height="20"><img src="/img/b.gif" border="0" height="20" width="1" alt="" /></td></tr>
</table>
<table style="border:1px solid #cfc7b7;margin-bottom:5px;" align="center" width="507" border="0" cellpadding="0" cellspacing="0" bgcolor="#ffffff">
<tr>
<td colspan="2" class="b12" bgcolor="#e9e7e0" style="padding:3px 0px 3px 0px;"><span class="p10" style="color:#000; float:right">An Advertising Feature&nbsp;&nbsp;</span>&nbsp;&nbsp;PARTNER CENTER</td>
</tr>

<tr>
<td class="p10" valign="top" align="center" style="padding:10px 0px 5px 0px;border-right:1px solid #cfc7b7;">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=1;sz=170x67;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter1" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter1" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter1= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=1;sz=170x67;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=1;sz=170x67;ord=1820182018201820;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</td>

<td class="p10" valign="top" align="center" style="padding:10px 0px 5px 0px;">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=2;sz=170x67;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter2" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter2" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter2= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=2;sz=170x67;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=2;sz=170x67;ord=1820182018201820;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</td>

</tr>

<tr>
<td class="p10" valign="top" align="center" style="padding:10px 0px 5px 0px;border-right:1px solid #cfc7b7;border-top:1px solid #cfc7b7;">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=3;sz=170x67;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter3" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter3" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter3= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=3;sz=170x67;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=3;sz=170x67;ord=1820182018201820;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</td>

<td class="p10" valign="top" align="center" style="padding:10px 0px 5px 0px;border-top:1px solid #cfc7b7;">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=4;sz=170x67;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter4" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter4" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter4= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=4;sz=170x67;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=4;sz=170x67;ord=1820182018201820;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</td>

</tr>

<tr>
<td class="p10" valign="top" align="center" style="padding:10px 0px 5px 0px;border-right:1px solid #cfc7b7;border-top:1px solid #cfc7b7;">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=5;sz=170x67;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter5" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter5" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter5= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=5;sz=170x67;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=5;sz=170x67;ord=1820182018201820;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</td>

<td class="p10" valign="top" align="center" style="padding:10px 0px 5px 0px;border-top:1px solid #cfc7b7;">



<script type="text/javascript">
<!--
var tempHTML = '';
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=6;sz=170x67;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="tradingcenter6" src="'+adURL+'" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170">';
} else {
  tempHTML += '<iframe id="tradingcenter6" src="/static_html_files/blank.htm" width="170" height="67" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:170px;">';
  ListOfIframes.tradingcenter6= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=6;sz=170x67;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'brokerbuttons.wsj.com')+'/us_subscriber;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';tile=6;sz=170x67;ord=1820182018201820;" border="0" width="170" height="67" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>
</td>

</tr>

</table>
<table cellpadding="0" cellspacing="0" border="0" bgcolor="" width="100%">
	<tr><td height="20"><img src="/img/b.gif" border="0" height="20" width="1" alt="" /></td></tr>
</table>

		</div>
	</div> 
<!-- End right column -->
	

	
<!-- Begin column 4 -->
	<div style="clear:both;text-align:center;">
		



	<img src="http://leadback.advertising.com/adcedge/lb?site=695501&amp;srvc=1&amp;betr=wsj_cs=3&amp;betq=1031=359955" width="1" height="1" border="0" alt=""/>

	</div>
<!-- End column 4 -->
	

	
<!-- Begin footer -->
	<div class="p12" style="clear:both;padding:17px 0px 10px 0px;text-align:center">

  		<a href="#top" class="unvisited">Return To Top</a>

  	 </div>
	<div style="border-top:1px solid #ccc; margin: 0 0 0 12px">



	<h1 style="text-align: center; font-family: arial; font-size: 9px; color: #666666; padding: 15px 0px 15px 0px; border-bottom: 1px solid #CCCCCC; 
	margin:0px;">Business Financial News -  Business News Online -  Personal Finance News -  Financial News -  Business News -  Finance news -  Personal Finance -  Personal Financial News</h1>

<div style="text-align: center; padding:7px 0px 5px; 0px;font-family: Arial;font-size: 12px; font-weight:bold">
  WSJ Digital Network:
</div>

<div style="text-align: center; padding:0px;font-family: Arial;font-size: 12px;">
  <a href="http://www.marketwatch.com/news/default.asp?siteid=wsj&dist=freedjsiteslink" class="unvisited">MarketWatch</a><span class="p12" style="padding:0px 5px;">|</span><a href="http://online.barrons.com/public/main" class="unvisited">Barrons.com</a><span class="p12" style="padding:0px 5px;">|</span><a href="http://realestatejournal.com/" class="unvisited">RealEstateJournal</a>
</div>

<div style="text-align: center; padding:3px 0px 9px 0px;font-family: Arial;font-size: 12px;">
  <a href="http://ptech.wsj.com/" class="unvisited">AllThingsDigital</a><span class="p12" style="padding:0px 5px;">|</span><a href="http://www.dowjones.com/alerts" class="unvisited">Dow Jones News Alerts</a><span class="p12" style="padding:0px 5px;">|</span><a href="http://online.wsj.com/public/other_wsj_sites" class="unvisited">MORE</a>
</div>

<div class="pln75" style="padding:7px 0px 0px 0px;text-align:center;border-top:1px solid #cccccc;">
    <script type="text/javascript">
    <!--
    if((typeof overrideLogout)=='undefined'||overrideLogout==null){var overrideLogout='';}

    var tempHTML=''
    if(loggedIn){
      tempHTML+= (overrideLogout != '')? overrideLogout : '<a href="'+nSP+'/logout" class="unvisited">Log Out</a>\n'
    } else {
      tempHTML+='<a href="http://online.wsj.com/reg/promo/6BCWCG_1007"  class="unvisited">Subscribe</a>\n'
      tempHTML+='&nbsp;\n'
      tempHTML+='<a href="'+nSP+'/login" class="unvisited">Log In</a>\n'
      tempHTML+='&nbsp;\n'
      tempHTML+='<a href="'+nSP+'/wsjgate?source=j2tourp&URI=/j2tour/welcome.html" onClick="OpenWin(this.href,\'mediatourpopup\',765,515,\'off\',true,18,23);return false" class="unvisited">Take a Tour</a>\n'
    }
    document.write(tempHTML)
    // -->
    </script>
    &nbsp;
    <script type="text/javascript">
    <!--
    document.write('<a href="'+nSP+((loggedIn)?"":"/public")+'/page/contact_us.html" class="unvisited">Contact Us</a>')
    //--></script>
    &nbsp;
    <script type="text/javascript">
    <!--
    document.write('<a href="'+nSP+'/wsjhelp/center" class="unvisited" onclick="OpenWin(this.href,\'help\',610,510,\'tool,scroll,resize\',true,153,40);return false;">Help</a>')
    // --></script>
    &nbsp;
    <script type="text/javascript">
    <!--
    document.write('<a href="'+nSP+'/email" class="unvisited">Email Setup</a>')
    // --></script>
    &nbsp;
    <script type="text/javascript">
    <!--
    if(loggedIn){;document.write('<a href="'+nSP+'/acct/setup_account" class="unvisited">My Account/Billing</a>&nbsp;')}
    // --></script>
    <span class="p12" style="color: #333">Customer Service:</span>
    <script type="text/javascript"><!--
    document.write('<a href="'+nSP+((loggedIn)?"":"/public")+'/page/0_0809.html?page=0_0809" class="unvisited">Online</a>')
    // --></script>
    <span class="p12">|</span>
    <script type="text/javascript">
    <!--
    document.write('<a href="'+((pID=="0_0013"||pID=="0_0003"||pID=="2_0003")?"http://www.europesubs.wsj.com/":((pID=="0_0014"||pID=="0_0004"||pID=="2_0004")?"https://www.awsj.com.hk/awsj2/?source=PWSHE4ECHR1N":"http://services.wsj.com"))+'" class="unvisited">Print</a>')
    // --></script>
</div>
<div class="pln75" style="padding-top:8px;text-align:center;">
    <script type="text/javascript">
    <!--
      document.write('<a href="'+nSP+'/public/page/privacy_policy.html" class="unvisited">Privacy Policy</a>')
    // --></script>
    &nbsp;
    <script type="text/javascript">
    <!--
      document.write('<a href="'+nSP+'/public/page/subscriber_agreement.html" class="unvisited">Subscriber Agreement & Terms of Use</a>')
    // --></script>
    &nbsp;
    <script type="text/javascript">
    <!--
      document.write('<a href="'+nSP+'/public/page/copyright_policy.html" class="unvisited">Copyright Policy</a>')
    // --></script>
    &nbsp;
    <script type="text/javascript">
    <!--
      document.write('<a href="http://mobile.wsj.com" class="unvisited">Mobile Devices</a>')
    // --></script>
    &nbsp;
    <script type="text/javascript">
     <!--
       document.write('<a href="'+nSP+((loggedIn)?"":"/public")+'/page/0_0813.html" class="unvisited">RSS Feeds</a>')
    // --></script>
</div>
<div class="pln75" style="padding-top:8px;text-align:center;">
    &nbsp;
    <a href="http://public.wsj.com/partner" class="unvisited">News Licensing</a>
    &nbsp;
    <a href="http://www.dowjonesonline.com" class="unvisited">Advertising</a>
    &nbsp;
    <a href="http://www.dj.com/" class="unvisited">About Dow Jones</a>
</div>
<div class="pln75" style="padding-top:8px;text-align:center;">
    <script type="text/javascript">
    <!--
    var dO=new Date()
    if(pID.substring(0,6)=="3_0513" || pStl.substring(0,2)=="3_"||pStl.indexOf("article")>-1){
      document.write('<a class="unvisited" href="#" onclick="CopyrightPopUp();return false">Copyright &#169; '+((dO.getYear()>1900)?dO.getYear():(dO.getYear()+1900))+' Dow Jones & Company, Inc. All Rights Reserved</a></font>')
    } else {
      document.write('<a class="unvisited" href="http://www.djreprints.com">Copyright &#169; '+((dO.getYear()>1900)?dO.getYear():(dO.getYear()+1900))+' Dow Jones & Company, Inc. All Rights Reserved</A></font>')
    }
    // -->
    </script>
</div>
<div style="padding-top:8px;text-align:center;"><img src="http://s.wsj.net/img/wj00g18.gif" width="78" height="19" border="0" alt="DowJones" /></div>
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
var adURL = 'http://ad.doubleclick.net/adi/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=1x1;ord=1820182018201820;';
if ( isSafari ) {
  tempHTML += '<iframe id="adO" src="'+adURL+'" width="1" height="1" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:1">';
} else {
  tempHTML += '<iframe id="adO" src="/static_html_files/blank.htm" width="1" height="1" marginwidth="0" marginheight="0" hspace="0" vspace="0" frameborder="0" scrolling="no" bordercolor="#000000" style="width:1px;">';
  ListOfIframes.adO= adURL;
}
tempHTML += '<a href="http://ad.doubleclick.net/jump/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=1x1;ord=1820182018201820;" target="_new">';
tempHTML += '<img src="http://ad.doubleclick.net/ad/'+((GetCookie('etsFlag'))?'ets.wsj.com':'interactive.wsj.com')+'/us;!category=;msrc=' + msrc + ';' + segQS + ';' + mc + ';sz=1x1;ord=1820182018201820;" border="0" width="1" height="1" vspace="0" alt="Advertisement" /></a><br /></iframe>';
document.write(tempHTML);
// -->
</script>

<!-- End 1x1 Code -->









<script type="text/javascript">
<!-- 
LoadIframes()
// -->
</script>





	  		<!-- START omniture_snippet_wsj_1.htm -->
<script type="text/javascript" src="http://s.wsj.net/js/s_code_wsj.js"></script>
<script type="text/javascript">
<!--
  var localSuppressOmniture = false;
  try {
  	if (typeof setSuppressOmniture != 'undefined') {
  		localSuppressOmniture = setSuppressOmniture();
  	}
  }
  catch(e) { }
  if (! localSuppressOmniture) {
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

		setMetaData('displayname','U.S. Home');			    
		setMetaData('section','Home');			    
		setMetaData('abasedocid','0_0002_public');			    
		setMetaData('pagename','U.S. Home_0_0012');			    
		setMetaData('ctype','home page');			    
		setMetaData('csource','WSJ Online');			    
		setMetaData('subsection','Home Page Public');			    
		setMetaData('sitedomain','online.wsj.com');			    
		setMetaData('primaryproduct','Online Journal');			    
		
	  		/** START omniture_snippet_wsj_2.htm **/
    if(s.prop19 == 'article'){
        s.hier1 = s.channel+','+s.prop1+','+s.prop2+','+s.prop22+','+s.prop3+','+s.prop20+','+s.prop4+','+s.prop6;
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
s.eVar25 = s.prop2;

/** DO NOT ALTER ANYTHING BELOW THIS LINE **/
var s_code=s.t();if(s_code)document.write(s_code)
}
//--></script>


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


<!-- START: RSI  Code  -->
<script type="text/javascript" src="http://js.revsci.net/gateway/gw.js?csid=G07608"></script>
<script type="text/javaScript">
<!--
 if(parent.location.protocol=="http:" && "".concat(document.domain).indexOf('online')>-1){
    if(s.prop19 == 'article'){
        DM_cat(s.channel+' > '+s.prop1+' > '+s.prop2+' > '+s.prop3);	
    }else{
        DM_cat(s.channel+' > '+s.prop1+' > '+s.prop2+' > '+s.pageName);	
    }
    try {
            DM_tag();
            saveSegment(rsinetsegs);
    } catch(err){}
}    //-->
</script>
<!-- END: RSI  Code  -->

<!-- Start of the Interstitial Popup -->
<div id="modal" style="position:absolute;left:0px;top:0px;display:none;background-color:#000;width:990px;height:1600px;filter:alpha(opacity=50);opacity:0.5;"></div>
<div id="message" style="position:absolute;top:100px;left:295px;border:2px solid #31659C;width:390px;height:400px;display:none;background-image: url(http://s.wsj.net/img/w.gif);background-color:#FFFFFF">
<div style="padding:6px 0px 0px 10px"><a href="#" onclick="closeMessage();return false"><img src="http://s.wsj.net/img/closeWSJ.gif" width="9" height="10" alt=""/><span class="p10" style="color:#31659C"> Close</span></a></div>
<div style="padding:15px 10px 10px 10px" id="messagecontent"></div>
</div>
<!-- End of the Interstitial Popup -->

<!-- START: Loomia Similar Items Recommendation Code  -->
<div id="_loomia_si_script_anchor" class="failsafe"></div>
<div id="_loomia_cs_script_anchor" class="failsafe"></div>
<div id="_loomia_cs_anchor" class="failsafe"></div>
<div id="sphere_container" class="failsafe"></div>
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
		/** The following javascript doesn't belong to loomia but we are using this function call to load the sphere js and css **/
		_loomia_addScript("http://online.wsj.com/sphere/widgets/sphereit/js?siteid=wsj&baseurl=http://online.wsj.com/sphere/widgets/sphereit/","sphere_container");
	}
	_loomia_scripts_loaded=1;
};
var L_VARS=new Object();
L_VARS.publisher_key=6563391702;
L_VARS.guid=(typeof s!='undefined')?s.prop20:"";
L_VARS.anchor="_loomia_si_anchor";

var exList=['0_0002','0_0012','0_0003','0_0013','0_0004','0_0014','3_0603']
pID=(typeof pID != 'undefined')?pID:"";
if(window.location.href.indexOf('/article') != -1 && window.pID && pID.indexOf('Infogrfx') == -1 && exList.indexOf(pID) == -1 && parent.location.protocol=="http:"){
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

<!-- START: Sphere recommended articles code-->
<script type="text/javascript" src="http://s.wsj.net/javascript/sphere.js"></script>
<script type="text/javascript">
<!-- 
  var x = document.getElementsByName("pagename")[0];
  var st1 = (x == null) ? '' : x.content;
  var index = (st1 == null) ? '' : st1.indexOf('_');
  var articleId = st1.substring(index + 1);
  var is_ie = false;
//-->
</script>
<!--[if IE]>
<script type="text/javascript">
  is_ie = true;
</script>
<![endif]-->
<script type="text/javascript">
<!--
  if(window.location.href.indexOf('/article') != -1 && window.pID && pID.indexOf('Infogrfx') == -1 && exList.indexOf(pID) == -1 && parent.location.protocol=="http:"){
    if(is_ie) {
      TransformIE();
    } else {
      TransformNotIE();
    }
  }
//-->
</script>
<!-- END: Sphere recommended articles code-->

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
</script>
<script type="text/javascript" src="http://amch.questionmarket.com/adsc/d260080/36/263292/randm.js"></script>
<script type="text/javascript" src="http://amch.questionmarket.com/adsc/d260080/37/263293/randm.js"></script>

<!-- img src="http://media.fastclick.net/rt?cn1=urt5&amp;v1=e"  alt="" width="1" height="1" border="0" / -->
<img src="http://www.burstnet.com/enlightn/426/public/7FAA/" alt="" width="0" height="0" border="0" />

<!-- Advertiser 'Wall Street Journal',  Include user in conversion 'Free Page Inclusion Pixel' - DO NOT MODIFY THIS PIXEL IN ANY WAY -->
<script type="text/javascript" src="http://ad.yieldmanager.com/pixel?id=61612&t=1"></script>

<img src="http://bh.contextweb.com/bh/set.aspx?action=replace&advid=570&token=WSJ01" width="1" height="1" border="0" alt=""/>

<!-- Start of DoubleClick Spotlight Tag: Please do not remove-->
<script type="text/javascript">
<!--
var axel = Math.random()+"";
var a = axel * 10000000000000;
document.write('<img src="http://ad.doubleclick.net/activity;src=1371794;type=wsjbr858;cat=wsjco985;ord='+ a + '?" width="1" height="1" alt="" />');
// --></script>
<noscript>
<img src="http://ad.doubleclick.net/activity;src=1371794;type=wsjbr858;cat=wsjco985;ord=1?" width="1" height="1" alt="" />
</noscript>
<!-- End of DoubleClick Spotlight Tag: Please do not remove-->

<!-- end retargeting_pixel.htm -->


</body>
</html>


<!-- PAGE GEN URL:  /public/page/0_0002_public-20080329215614044.html -->


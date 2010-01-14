#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 41;

BEGIN { use_ok('SL::AdParser') or die }

# slurp the test webpage
my $content = do { local $/; <DATA> };

use Time::HiRes qw(tv_interval gettimeofday);

use SL::Subrequest;
use SL::AdParser;

my $base_url   = 'http://stason.org';
my $subreq     = SL::Subrequest->new();

# clear out the cache
$subreq->{cache}->clear;

my $start      = [gettimeofday];
my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);
my $interval = tv_interval( $start, [gettimeofday] );

use SL::AdParser;

my $ads = SL::AdParser->parse_all($subreq_ref->{ads});

my $code = <<'CODE';
<!--/* OpenX Javascript Tag v2.8.2 */-->

<script type='text/javascript'><!--//<![CDATA[
   var m3_u = (location.protocol=='https:'?'https://www.urbanwireless.net/adserver/www/delivery/ajs.php':'http://www.urbanwireless.net/adserver/www/delivery/ajs.php');
   var m3_r = Math.floor(Math.random()*99999999999);
   if (!document.MAX_used) document.MAX_used = ',';
   document.write ("<scr"+"ipt type='text/javascript' src='"+m3_u);
   document.write ("?zoneid=38");
   document.write ('&amp;cb=' + m3_r);
   if (document.MAX_used != ',') document.write ("&amp;exclude=" + document.MAX_used);
   document.write (document.charset ? '&amp;charset='+document.charset : (document.characterSet ? '&amp;charset='+document.characterSet : ''));
   document.write ("&amp;loc=" + escape(window.location));
   if (document.referrer) document.write ("&amp;referer=" + escape(document.referrer));
   if (document.context) document.write ("&context=" + escape(document.context));
   if (document.mmm_fo) document.write ("&amp;mmm_fo=1");
   document.write ("'><\/scr"+"ipt>");
//]]>--></script><noscript><a href='http://www.urbanwireless.net/adserver/www/delivery/ck.php?n=a46ba856&cb=INSERT_RANDOM_NUMBER_HERE' target='_blank'><img src='http://www.urbanwireless.net/adserver/www/delivery/avw.php?zoneid=38&cb=INSERT_RANDOM_NUMBER_HERE&n=a46ba856' border='0' alt='' /></a></noscript>
CODE

my $testad = $ads->[0]->{ad};

$testad = quotemeta($$testad);

$content =~ s/(<\s*?script.*?$testad.*?\/\s*?script\s*?>)/$code/;

open(FH, '>', '/tmp/foo');
print FH $content;
close(FH);


=cut

is( scalar( @{$subreq_ref} ), scalar(@{test_urls()}), 'num subrequests extracted' );
diag("extraction took $interval seconds");
my $limit = 0.15;
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
diag("replacement took $interval seconds");
cmp_ok( $interval, '<', $limit, "replace_subrequests took $interval seconds" );

sub test_urls {
    return [
    ];
}

=cut


__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
    <head><script type="text/javascript" src="http://s2.slwifi.com/js/horizontal.js"></script>
<link rel="stylesheet" type="text/css" href="http://s2.slwifi.com/css/sl_floating_microbar.css" />



        
        <link href="http://stason.org/style.css" rel="stylesheet" type="text/css" title="refstyle">
        <meta name="description" content="There is a group of vitamins, minerals, and enzymes called
'Antioxidants' that help to protect the body from the formation of
free radicals. Free radicals are atoms or groups of atoms that can
cause damage to cells, impairing the immunity system and leading to
infections and various degenerative diseases such as heart disease,
and cancer. Free radical damage is thought by scientists to be the
basis for the aging process as well.">
        <meta name="keywords" content="vitamin E, tocopherol, Antioxidant,
    herb, natural medicine, health, balance, herbal care, natural
    approach">
        <meta name="author" content="Stas Bekman: stas (at) stason.org">
        <meta name="classification" content="information">
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta name="robots" content="index,follow"> 
        <style type="text/css">
                img.noborder { border: none;}
                body {
                    background-color: #ffffff;
                    background-image: url(../../../images/bgline.gif);
                    background-attachment: fixed;  /* needed for mac/ie5*/
                    color: #000000;
                    font-family: arial, helvetica, verdana, sans-serif;
                    /* font-size: 0.85em; */
                    position: relative !important; /* needed for ie5*/
                }
         </style>
         <title>Vitamin E (Tocopherol) - A Powerful Antioxidant</title>
        <link rel="shortcut icon" href="http://stason.org/images/favicon.ico" type="image/x-icon">

<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-145457-1";
urchinTracker();
</script>


    </head>
<body class="body-margins"><div id="silver_lining_ad_horizontal"><div id="silver_lining_text_ad"><a href="http://www.silverliningnetworks.com/" id="silver_lining_bug" style="background:url(http://s1.slwifi.com/images/ads/sln/micro_bug.gif);"></a><div id="silver_lining_client_ad">It's almost Friday!!</div><a onClick="silverLiningClose(); return false;" id="silver_lining_close" href="#"><img src="http://s1.slwifi.com/images/icons/close_blue.png" title="Hide Advertisement" alt="close" /></a><div class="silver_lining_clear"></div></div></div><div id="silver_lining_webpage">

<a name="top"></a>

<!-- Swishcommand noindex -->

<!-- logobox begin -->
<div class="logobox">
    <table border="0" cellspacing="0" cellpadding="0" width="100%">
        <tr valign="top">
            <td rowspan="12"><a href="http://stason.org/"><img src="http://stason.org/images/logo/logo_blend.gif" border="0" alt="stason.org logo" width="195" height="52"></a></td>


        <!-- breadcrumb and topline begin -->
        
        <!-- this silly width is needed for ns4 due to its default paddings in divs, notably rightbox-div -->
        <td width="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>

        <td class="navbarglobal" height="31" width="100%" valign="bottom">
            <!-- breadcrumb start -->
            <a href="../../.././index.html"><b>Articles</b></a> / 
            <a href="../.././index.html"><b>Articles</b></a> / 
            <a href=".././index.html"><b>WellBeing+Healing</b></a> / 
            <a href="./index.html"><b>Your Health</b></a> / 
            <!-- breadcrumb end -->

        </td>
        <!-- camel begin -->
        <td rowspan="2" align="right" valign="bottom"><a href="http://stason.org/"><img src="http://stason.org/images/logo/lotus.gif" border="0" alt="lotus" width="37" height="37"></a></td>
        <td rowspan="2" width="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        <!-- camel end -->
    </tr>
    <tr valign="top" class="noPrint">
        <td colspan="2" height="6"><img src="http://stason.org/images/trans_pix.gif"></a></td>
    </tr>

    <!-- topline begin -->
    <tr valign="top" class="noPrint">
        <td colspan="3" height="1" class="camel-line-top"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        <td><img src="http://stason.org/images/trans_pix.gif"></a></td>
   </tr>
    <tr valign="top" class="noPrint">
        <td colspan="3" height="1" class="camel-line-bottom"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        <td><img src="http://stason.org/images/trans_pix.gif"></a></td>
    </tr>
    <!-- topline end -->

    <tr valign="top" class="noPrint">
        <td height="3" colspan="4"><img src="http://stason.org/images/trans_pix.gif"></a></td>
    </tr>




        <!-- adlinks start -->
        <tr valign="top">
            <td colspan="4">



<script type="text/javascript"><!--
google_ad_client = "pub-2067667577988568";
/* chestofbooks horiz links top 728x15 */
google_ad_slot = "5008380137";
google_ad_width = 728;
google_ad_height = 15;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>





<br>
<br>
</td>
        </tr>
        <!-- adlinks end -->

        
        <!-- local navigation begin -->
        <tr valign="top">
            <!-- this particular first cell is here due to a strange bug in IE5 for mac -->
            <td><img src="http://stason.org/images/trans_pix.gif"></td>
            <td colspan="2" align="right" valign="top" height="16" nowrap><a href="Rosa-Mosqueta-Seed-Oil-Gift-From-Mother-Nature.html"><img src="http://stason.org/images/nav/page_prev.gif" alt="previous page: Rosa Mosqueta Seed Oil from Chile - Gift From Mother Nature" border="0" width="48" height="16"></a><a href="./index.html"><img src="http://stason.org/images/nav/page_parent.gif" alt="page up: Your Health" border="0" height="16" width="25"></a><img src="http://stason.org/images/nav/page_nonext.gif" alt="no next page" border="0" width="48" height="16"></td>
            <td width="1"><img src="http://stason.org/images/trans_pix.gif"></td>
        </tr>
        <!-- local navigation end -->


        <!-- some space -->
        <tr>
            <td height="20" colspan="4"><br></td>
        </tr>

        <tr>
            <!-- title begin -->
            <td><img src="http://stason.org/images/trans_pix.gif"></td>
            <td colspan="2" class="headline" valign="bottom" width="100%"><h1>Vitamin E (Tocopherol) - A Powerful Antioxidant</h1></td>
            <td width="1"><img src="http://stason.org/images/trans_pix.gif"></td>
            <!-- title end -->
        </tr>

        <tr>
            <td height="2" colspan="4"><img src="http://stason.org/images/trans_pix.gif"></td>
        </tr>

        <tr>
            <td><img src="http://stason.org/images/trans_pix.gif"></td>
            <!-- title line begin -->
            <td colspan="2" class="blue-bg" height="4"><img src="http://stason.org/images/trans_pix.gif"></td>
            <td width="1"><img src="http://stason.org/images/trans_pix.gif"></td>
            <!-- title line end -->
        </tr>
        <tr>
            <td height="2" colspan="4"><img src="http://stason.org/images/trans_pix.gif"></td>
        </tr>
    </table>
</div>
<!-- logobox end -->

<!-- left box begin -->
<div class="leftbox">


    <!-- menu main begin -->
    <table border="0" cellspacing="0" cellpadding="0" width="150" align="center">
        <tr>
            <td class="menu-border" width="1" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
            <td class="menu-border" width="148"><img src="http://stason.org/images/trans_pix.gif"></a></td>
            <td class="menu-border" width="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>

        <tr>
            <td class="menu-border"><br></td>
            <td align="center" class="menu-title-bg">
                <div class="menu-title"><a rel="nofollow" href="http://stason.org/">stason.org</a></div>
            </td>
            <td class="menu-border"><br></td>
        </tr>

        <tr>
            <td class="menu-border" colspan="3" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>

        <tr>
            <td class="menu-border"><br></td>
            <td class="sel-bg">
                <div class="selectedmenuitem">
                    &nbsp;<a href="../../../articles/index.html">Articles</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../works/index.html">Development</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../books/index.html">Books</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../talks/index.html">Teaching</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../..//photos/gallery/index.html">Photography</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../stuff/index.html">Bits and Pieces</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../TULARC/index.html">TULARC</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../me.html">Contact Us</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                    &nbsp;<a href="../../../sitemap.html">Site Map</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border" colspan="3" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>
    </table>
    <!-- menu main end -->

    <br>


    <!-- menu google search begin -->

    <table border="0" cellspacing="0" cellpadding="0" width="150" align="center">
        <tr>
            <td class="menu-border" width="1" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
            <td class="menu-border" width="148"><img src="http://stason.org/images/trans_pix.gif"></a></td>
            <td class="menu-border" width="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>

        <tr>
            <td class="menu-border"><br></td>
            <td align="center" class="menu-title-bg">
                <div class="menu-title">Search</div>
            </td>
            <td class="menu-border"><br></td>
        </tr>

        <tr>
            <td class="menu-border" colspan="3" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>

        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">


<!-- Google CSE Search Box Begins -->
  <div align="center">
  <br>
  <form id="searchbox_000348145676127462126:lfdbdo5qnx4" action="http://stason.org/search.html">
    <input type="hidden" name="cx" value="000348145676127462126:lfdbdo5qnx4" />
    <input type="hidden" name="cof" value="FORID:10" />
    <input name="q" type="text" size="14" maxlength="255" /><br>
    <input type="submit" name="sa" value="Search" />
  </form>
  <script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=searchbox_000348145676127462126%3Alfdbdo5qnx4"></script>
  </div>
<!-- Google CSE Search Box Ends -->

            </td>
            <td class="menu-border"><br></td>
        </tr>

        <tr>
            <td class="menu-border" colspan="3" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>
    </table>
    <!-- menu google search end -->

    <br>


    <!-- menu links begin -->

    <table border="0" cellspacing="0" cellpadding="0" width="150" align="center">
        <tr>
            <td class="menu-border" width="1" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
            <td class="menu-border" width="148"><img src="http://stason.org/images/trans_pix.gif"></a></td>
            <td class="menu-border" width="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>

        <tr>
            <td class="menu-border"><br></td>
            <td align="center" class="menu-title-bg">
                <div class="menu-title">Favorites</div>
            </td>
            <td class="menu-border"><br></td>
        </tr>

        <tr>
            <td class="menu-border" colspan="3" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>

        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                &nbsp;
                    <a href="http://chestofbooks.com/">Free Online Books</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                &nbsp;
                    <a href="http://meta-religion.com/">Meta Religion</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                &nbsp;
                    <a href="http://healingcloud.com/">Healing Info</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border"><br></td>
            <td class="non-sel-bg">
                <div class="nonselectedmenuitem">
                &nbsp;
                    <a href="http://contentdig.com/">Article Collection</a>
                </div>
            </td>
            <td class="menu-border"><br></td>
        </tr>
        <tr>
            <td class="menu-border" colspan="3" height="1"><img src="http://stason.org/images/trans_pix.gif"></a></td>
        </tr>
    </table>
    <!-- menu links end -->

    <br>


    <br />
    <br />
    <br />
    <br />
    <br />

    <br />







</div>
<!-- left box end -->

<!-- right box begin-->
<div class="rightbox">
    <!-- content begin -->
    <br>
    <div class="index-section">
    <!-- SwishCommand index -->
    

    
<br>
<br>
<br>

<div class="" style="margin: 0px 0px 0px 40px;" align="left">




<script type="text/javascript"><!--
google_ad_client = "pub-2067667577988568";
/* 336x280, created 2/20/09 */
google_ad_slot = "1789566035";
google_ad_width = 336;
google_ad_height = 280;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>


<script type="text/javascript"><!--
google_ad_client = "pub-2067667577988568";
/* 336x280_2, created 2/20/09 */
google_ad_slot = "3113661380";
google_ad_width = 336;
google_ad_height = 280;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>




</div>

<br clear="all">
<br>
<br>
<br>
<br>
<br>
<br>



<!-- google_ad_section_start -->

    <h2>Description</h2>

    <img width="108" align="right" src="http://stason.org/klaus-ferlow.jpg" height="137">

    <p>The following article was authored by Klaus Ferlow, HMH (Honorary Master Herbalist, Dominion Herbal College, Burnaby, B.C. est. 1926), 
    innovator, lecturer, researcher, writer, President, founder and
    co-owner with his two sons Peter and Harald, CH (chartered
    Herbalist) of Ferlow Botanicals, Div. of Ferlow Brothers Ltd,
    Vancouver, B.C. manufacturing/distributing <b>organic</b> <b>toxin-free</b>
    medicinal herbal and personal care products to professional health
    & wellness practitioners in Canada and parts of USA since
    1993. The company was founded in 1975. Klaus is also President of the "Hearts to Health Foundation" and on the Board of Directors of the Health Action Network Society (HANS), Burnaby, B.C. est. 1984. <a href="http://www.ferlowbotanicals.com">www.ferlowbotanicals.com<a/>,
    email: <a href="mailto:kferlow@shaw.ca">kferlow@shaw.ca</a>.</p>

    <p>His educational articles have been published in dozens of
    Canadian Health Magazines, Newsletters, Newspapers and numerous
    websites around the world.</p>

    <p></p>

    <h1>Vitamin E (Tocopherol) - A Powerful Antioxidant</h1>

    <p>There is a group of vitamins, minerals, and enzymes called
<b>Antioxidants</b> that help to protect the body from the formation
of free radicals. Free radicals are atoms or groups of atoms that can
cause damage to cells, impairing the immunity system and leading to
infections and various degenerative diseases such as heart disease,
and cancer. Free radical damage is thought by scientists to be the
basis for the aging process as well.</p>

<p>Although many antioxidants can be obtained from food sources such as
sprouted grains and fresh fruits and vegetables, it is difficult to
get enough of them from these sources to hold back the free radicals
constantly being generated from our polluted environment.</p>

<p>Powerful antioxidants are (just to mention a few): Vitamin E, Vitamin
C, Vitamin A and Beta Carotene, Green Tea, Grapeseed Extract, Ginkgo
Biloba, Coenzyme Q10.</p>

<p>Vitamins are divided into two groups. Fat-soluble and water-soluble,
depending on how they are absorbed. Vitamin E is a fat-soluble vitamin
which require the presence of fat carriers to be absorbed, and not as
easily assimilated as water-soluble vitamins. Vitamin E is best known
as the anti-sterility vitamin and as a powerful
antioxidant. Protecting the body from effects of pollution, other
toxins and free radicals, it helps premature aging, cancer and other
chronic, degenerative diseases. Vitamin E even protects other
nutrients from damage. The immune system is dependent upon this
vitamin for strength and stability. Adequate Vitamin E is needed to
heal injured tissues and prevent scarring.</p>

<p>Vitamin E possesses some anticoagulant activity to prevent the
formation of blood clots. The natural form of vitamin E d-alpha
tocopherol is highly superior to the synthetic form known as dl-alpha
tocopherol. We use only the natural d-alpha tocopherol in our Vitamin
E cream. Our Vitamin E cream is absorbed through the cells into the
bloodstream, nourishing your skin inside and out.</p>

<!-- google_ad_section_end -->

<p>This information is offered for its educational value only and should not be used in the diagnose, treatment, or prevention of disease. Any attempt to diagnose and treat illness should come under the direction of your health care practitioner.</p>

    



    <h1>Related Articles</h1>

    <ol>
                <li><a href="/articles/wellbeing/health/Neem-Toothpaste-The-Healthy-Solution-For-Your-Teeth-Gums.html">Neem Toothpaste - The Healthy Solution For Your Teeth & Gums</a></li>

            <li><a href="/articles/wellbeing/health/The-Healing-Power-Of-Garlic-Allium-Sativum.html">The Healing Power Of Garlic (Allium Sativum)</a></li>

            <li><a href="/articles/wellbeing/health/How-To-Avoid-Heart-Problems.html">How To Avoid Heart Problems</a></li>

            <li><a href="/articles/wellbeing/health/The-Miraculous-Neem.html">The Miraculous Neem</a></li>

            <li><a href="/articles/wellbeing/health/Think-Hemp-For-Food-Clothing-Body-Care-More.html">Think Hemp! For Food, Clothing, Body Care & More</a></li>

            <li><a href="/articles/wellbeing/health/Himalayan-Alexander-Crystal-Salt-A-Gift-From-Mother-Nature.html">Himalayan Alexander Crystal Salt - A Gift From Mother Nature</a></li>
    </ol>
  





    

<br clear="all">

    <h1>Share and Enjoy</h1>

    <div class="sociable">

        <div style="float:right"></div>Bookmark this story so others can enjoy it:
        <br/>

      <ul>

  <li><a href="http://digg.com/submit?phase=2&amp;url=http%3A%2F%2Fstason.org%2Farticles%2Fwellbeing%2Fhealth%2FVitamin-E-Tocopherol-A-Powerful-Antioxidant.html&amp;title=Vitamin%20E%20(Tocopherol)%20-%20A%20Powerful%20Antioxidant" title="digg"><img src="http://stason.org/images/sociable/digg.png" alt="digg"
  /></a></li>
  
  <li><a href="http://reddit.com/submit?url=http%3A%2F%2Fstason.org%2Farticles%2Fwellbeing%2Fhealth%2FVitamin-E-Tocopherol-A-Powerful-Antioxidant.html&amp;title=Vitamin%20E%20(Tocopherol)%20-%20A%20Powerful%20Antioxidant" title="Reddit"><img src="http://stason.org/images/sociable/reddit.png" alt="Reddit" /></a></li>
  
  <li><a href="http://del.icio.us/post?url=http%3A%2F%2Fstason.org%2Farticles%2Fwellbeing%2Fhealth%2FVitamin-E-Tocopherol-A-Powerful-Antioxidant.html&amp;title=Vitamin%20E%20(Tocopherol)%20-%20A%20Powerful%20Antioxidant&amp;notes=There%20is%20a%20group%20of%20vitamins%2C%20minerals%2C%20and%20enzymes%20called%20'Antioxidants'%20that%20help%20to%20protect%20the%20body%20from%20the%20formation%20of%20free%20radicals.%20Free%20radicals%20are%20atoms%20or%20groups%20of%20atoms%20that%20can%20cause%20damage%20to%20cells%2C%20impairing%20the%20immunity%20system%20and%20leading%20to%20infections%20and%20various%20degenerative%20diseases%20such%20as%20heart%20disease%2C%20and%20cancer.%20Free%20radical%20damage%20is%20thought%20by%20scientists%20to%20be%20the%20basis%20for%20the%20aging%20process%20as%20well.&amp;tags=vitamin%20E%20tocopherol%20Antioxidant%20herb%20natural%20medicine%20health%20balance%20herbal%20care%20natural%20approach"
  title="del.icio.us"><img src="http://stason.org/images/sociable/delicious.png" alt="del.icio.us" /></a></li>

  <li><a href="http://www.furl.net/storeIt.jsp?u=http%3A%2F%2Fstason.org%2Farticles%2Fwellbeing%2Fhealth%2FVitamin-E-Tocopherol-A-Powerful-Antioxidant.html&amp;t=Vitamin%20E%20(Tocopherol)%20-%20A%20Powerful%20Antioxidant&amp;keywords=vitamin%20E%2C%20tocopherol%2C%20Antioxidant%2C%20herb%2C%20natural%20medicine%2C%20health%2C%20balance%2C%20herbal%20care%2C%20natural%20approach&amp;rating=5&amp;description=There%20is%20a%20group%20of%20vitamins%2C%20minerals%2C%20and%20enzymes%20called%20'Antioxidants'%20that%20help%20to%20protect%20the%20body%20from%20the%20formation%20of%20free%20radicals.%20Free%20radicals%20are%20atoms%20or%20groups%20of%20atoms%20that%20can%20cause%20damage%20to%20cells%2C%20impairing%20the%20immunity%20system%20and%20leading%20to%20infections%20and%20various%20degenerative%20diseases%20such%20as%20heart%20disease%2C%20and%20cancer.%20Free%20radical%20damage%20is%20thought%20by%20scientists%20to%20be%20the%20basis%20for%20the%20aging%20process%20as%20well." title="Furl"><img src="http://stason.org/images/sociable/furl.png" alt="Furl" /></a></li>
  
  <li><a href="http://wists.com/r.php?c=There%20is%20a%20group%20of%20vitamins%2C%20minerals%2C%20and%20enzymes%20called%20'Antioxidants'%20that%20help%20to%20protect%20the%20body%20from%20the%20formation%20of%20free%20radicals.%20Free%20radicals%20are%20atoms%20or%20groups%20of%20atoms%20that%20can%20cause%20damage%20to%20cells%2C%20impairing%20the%20immunity%20system%20and%20leading%20to%20infections%20and%20various%20degenerative%20diseases%20such%20as%20heart%20disease%2C%20and%20cancer.%20Free%20radical%20damage%20is%20thought%20by%20scientists%20to%20be%20the%20basis%20for%20the%20aging%20process%20as%20well.;&amp;r=http%3A%2F%2Fstason.org%2Farticles%2Fwellbeing%2Fhealth%2FVitamin-E-Tocopherol-A-Powerful-Antioxidant.html&amp;title=Vitamin%20E%20(Tocopherol)%20-%20A%20Powerful%20Antioxidant&amp;description=There%20is%20a%20group%20of%20vitamins%2C%20minerals%2C%20and%20enzymes%20called%20'Antioxidants'%20that%20help%20to%20protect%20the%20body%20from%20the%20formation%20of%20free%20radicals.%20Free%20radicals%20are%20atoms%20or%20groups%20of%20atoms%20that%20can%20cause%20damage%20to%20cells%2C%20impairing%20the%20immunity%20system%20and%20leading%20to%20infections%20and%20various%20degenerative%20diseases%20such%20as%20heart%20disease%2C%20and%20cancer.%20Free%20radical%20damage%20is%20thought%20by%20scientists%20to%20be%20the%20basis%20for%20the%20aging%20process%20as%20well.&amp;tags=vitamin%20E%20tocopherol%20Antioxidant%20herb%20natural%20medicine%20health%20balance%20herbal%20care%20natural%20approach" title="Wists"><img src="http://stason.org/images/sociable/wists.png" alt="Wists" /></a></li>

        
      </ul>
    </div>


    


<h1>Tags</h1>
<p><a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=vitamin%20E">vitamin E</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=tocopherol">tocopherol</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=Antioxidant">Antioxidant</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=herb">herb</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=natural%20medicine">natural medicine</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=health">health</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=balance">balance</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=herbal%20care">herbal care</a>, <a rel="nofollow" href="http://stason.org/search.html?cx=000348145676127462126%3Alfdbdo5qnx4&cof=FORID%3A10&sa=Search&q=natural%20approach">natural approach</a></p>



    

      
    <!-- SwishCommand noindex -->
    </div>
    

    <br>

    <!-- content end -->
<br>
<br>

<table border="0" cellspacing="0" cellpadding="0" width="100%">
        <tr>
           <td> 



<script type="text/javascript"><!--
google_ad_client = "pub-2067667577988568";
/* 728x15, created 2/20/09 */
google_ad_slot = "0267506126";
google_ad_width = 728;
google_ad_height = 15;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>



            </td>
        </tr>
        <tr>
            <td height="4"></td>
        </tr>
        <tr>
            <td class="blue-bg" height="4"><img src="http://stason.org/images/trans_pix.gif"></td>
        </tr>
        <tr>
            <td height="4"></td>
        </tr>
        <tr>
            <td align="right">
<!-- Google CSE Search Box Begins -->

  <div align="right">
  <form id="searchbox_000348145676127462126:lfdbdo5qnx4" action="http://stason.org/search.html">
    <input type="hidden" name="cx" value="000348145676127462126:lfdbdo5qnx4" />
    <input type="hidden" name="cof" value="FORID:10" />
    <input name="q" type="text" size="50" maxlength="255" />
    <input type="submit" name="sa" value="Search" />
  </form>
  <script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=searchbox_000348145676127462126%3Alfdbdo5qnx4"></script>
  </div>

<!-- Google CSE Search Box Ends -->
            </td>
        </tr>
</table>


<br><br>
</div>
<!-- right box end -->


<!-- tailbox start -->
<div class="tailbox">
   <table width="100%" border="0" cellspacing="0" cellpadding="0">
       <tr>
           <!-- this height must be 1px more than the highest gif ns6/mac -->
           <td width="195" nowrap height="17">

               <table width="195" border="0" cellspacing="0" cellpadding="0">
                   <tr>
                       <td><img src="http://stason.org/images/trans_pix.gif"></a></td>
                   </tr>
               </table>
            </td>
           <td width="1"><br></td>
           <td align="left" nowrap><a href="#top"><img src="http://stason.org/images/nav/page_top.gif" width="48" height="16" border="0" alt="TOP"></a></td>
           <td width="100%"><br></td>
           <td align="right" nowrap><a href="Rosa-Mosqueta-Seed-Oil-Gift-From-Mother-Nature.html"><img src="http://stason.org/images/nav/page_prev.gif" alt="previous page: Rosa Mosqueta Seed Oil from Chile - Gift From Mother Nature" border="0" width="48" height="16"></a><a href="./index.html"><img src="http://stason.org/images/nav/page_parent.gif" alt="page up: Your Health" border="0" height="16" width="25"></a><img src="http://stason.org/images/nav/page_nonext.gif" alt="no next page" border="0" width="48" height="16"></td>
           <td width="1"><br></td>
        </tr>
    </table>



</div>
<!-- tailbox end -->


        <div class="footer">

            <hr noshade size="1">
            <!-- footer (tail )-->
            <p class="modified">Last modified Fri Feb 20 18:52:22 2009</p>

            <p>Created by 
            <a rel="nofollow" href="../../../me.html#email">Stas Bekman</a>
            and his 
            <a rel="nofollow" href="../../../works/modules.html#docset">DocSet</a>.</p>

<div>
[ <a rel="nofollow" href="../../../privacy-policy.html">Privacy Policy</a> ]
[ <a rel="nofollow" href="../../../copyright.html">Copyright</a> ]
[ <a rel="nofollow" href="../../../about.html">About Us</a> ]
[ <a rel="nofollow" href="../../../advertise.html">Advertise on This Site</a> ]
[ <a rel="nofollow" href="../../../search.html">Search</a> ]
</div>
             <!-- end footer (tail)-->
            <br><br>



        </div>






<script type="text/javascript" src="http://stason.us.intellitxt.com/intellitxt/front.asp?ipid=17682"></script>








</div></body>
</html>

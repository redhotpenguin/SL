#!perl

use strict;
use warnings FATAL => 'all';

#################################
#
# http://www.hogwild.net/Bubbles/20070715-megan-fox-transformers-jodie-sweetin-funny-myspace-pictures-02-b.htm
#
# this web page broke because it has no head tag so we could not insert
# the css link, thank you digg
#
###################################


use Test::More tests => 5;

BEGIN {
    use_ok('SL::Model::Ad');
}

my $content = do { local $/ = undef; <DATA> };

my $ad       = _ad_content();
my $css_link = 'http://www.redhotpenguin.com/css/local.css';

use Time::HiRes qw(tv_interval gettimeofday);

my $start = [gettimeofday];
ok(!SL::Model::Ad::container( \$css_link, \$content, \$ad ));
my $interval = tv_interval( $start, [gettimeofday] );

unlike( $content, qr/$ad/s,       'ad not inserted ok' );
unlike( $content, qr/$css_link/, 'css link not inserted ok' );
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
<html>
<title>
Jodie Sweetin has huge boobies! Funny MySpace Pictures. Funny Pictures for Myspace. Myspace jokes.
</title>
<meta NAME="keywords"
CONTENT="
Jodie Sweetin, crazy, jokes, pictures, myspace, dirty, funny, hilarious, comedy, humor, parody
">

<meta name="description" content="
Jodie Sweetin has huge boobies! Funny MySpace Pictures. Funny Pictures for Myspace. Myspace jokes.
">

<!-- 
Jodie Sweetin has huge boobies! Funny MySpace Pictures. Funny Pictures for Myspace. Myspace jokes.
-->

<style type="text/css">
a {
text-decoration: none;
}

 A:hover {color:red} 

a:hover {
text-decoration: underline;
}
 
 </style>  


</head>

<body background="../images/hogwildnet-logo-pig-bg.jpg" link="#FF0000" vlink="#FF0000">

 
  
  <table border="4" width="100%" bordercolor="#000080" bgcolor="#000080" height="45" id="table1">

    <tr>
      <td width="100%" bgcolor="#FFFFFF" height="31">
      <p align="center"><big><font face="Arial">
		<strong><span style="letter-spacing: 2pt"><font size="3" color="#000080">
		HOGWILD.NET</font><font size="3">&nbsp;
      </font>
      </span></strong><span style="letter-spacing: 2pt"><b>
		<em>

		<font color="#FF0000" size="3">semi-hilarious comedy</font></em></b></span></font></big><b></font>
      </b>
      <br>
      <em>
		<font face="Arial" size="2"><b>Jodie Sweetin has huge boobies!&nbsp;</b>Dirty 
		Jokes. Funny MySpace Pictures!</font></em></td>
      
  </tr>
  	<tr>

    <td width="100%" bgcolor="#FFFFFF" height="2" align="center">
      <p align="center"><b><font color="#000000" face="Arial"><small><small>| 
		<a href="http://www.hogwild.net" style="text-decoration: none">TWISTED 
		HUMOR </a>| 
		<a href="http://www.hogwild.net/Bubbles/Bubbles.htm" style="text-decoration: none">FUNNY 
		MYSPACE
      PICTURES</a> | 
		<a href="http://www.hogwild.net/Rants/Rants-HOME.htm" style="text-decoration: none">
		FUNNY RANTS</a> |&nbsp;<a href="http://www.hogwild.net/audio/funny-videos.htm" style="text-decoration: none">COMEDY 
		VIDEOS</a> 
		| 
		<a href="http://www.hogwild.net/News/newshome.htm" onMouseOver="window.status='HogWild Wordz of Wizdum: It is not polite to HUMP OTHERS to show your dominance';return true" onMouseOut="window.status='  '" style="text-decoration: none">NEWS</a>

      | 
		<a href="http://www.hogwild.net/askhog/askhog.htm" onMouseOver="window.status='Women enjoy getting their hair brushed by a man.  But not Pro Bowlers.  That is why they keep it short and spiky.';return true" onMouseOut="window.status='  '" style="text-decoration: none">
		DATING ADVICE MAN</a><font color="#000000"> </font>| 
		<a href="http://www.hogwild.net/cartoon/Cartoons.htm" style="text-decoration: none">CARTOONS</a> | 
		<a href="http://www.hogwild.net/Misc/chat-home.htm" style="text-decoration: none">CHATS</a> |&nbsp;<a href="http://www.hogwild.net/games2.htm" style="text-decoration: none">GAMES</a> | 
		<a href="http://www.hogwild.net/Misc/links.htm" style="text-decoration: none">LINKS</a> | 
		<a href="http://www.hogwild.net/Misc/stand-up-comedy-new-york-city-free.htm" style="text-decoration: none">COMEDY
      SHOWS</a> | 
		<a href="http://www.hogwild.net/Misc/Contacts.htm" style="text-decoration: none">CONTACT</a> |</small></small></font></b></td>

  	</tr>
</table>

	<table border="1" width="100%" id="table2">
		<tr>
    <td width="303" bgcolor="#FFFFFF" align="left" valign="top"><p align="center">
         <!-- HOGWILD NEWSLETTER FORM -->		
		<form method="post" action="http://www.hogwild.net/cgi-bin/FormMailer.pl">
<input type="hidden" name="recipient" value="hogwild@hogwild.net" />
</b>
<p align="left"><b><font face="Arial" size="2">Get my Funny Pictures in 
Your Email!</font></b></p>

<p><font face="Arial" size="2">Your email address:</font></p>
<b>
<p><font face="Arial"> <input type="text" name="email" size="17"></font></p>
<input type="hidden" name="page" value="bubbles" />
<input type="submit" />
</form>
&nbsp;<p>
<!-- HOGWILD NEWSLETTER FORM -->

<p align="center">
<br>			
		<!-- FASTCLICK.COM 160x600 and 120x600 SKYSCRAPER CODE for hogwild.net -->
<script language="javascript"  src="http://media.fastclick.net/w/get.media?sid=10453&m=3&tp=7&d=j&t=n"></script>
<noscript><a href="http://media.fastclick.net/w/click.here?sid=10453&m=3&c=1"  target="_blank">
<img src="http://media.fastclick.net/w/get.media?sid=10453&m=3&tp=7&d=s&c=1"
width=160 height=600 border=1></a></noscript>

<!-- FASTCLICK.COM 160x600 and 120x600 SKYSCRAPER CODE for hogwild.net -->
<br>
<br>
<!-- FASTCLICK.COM 300x250 MEDIUM RECTANGLE CODE for hogwild.net -->
<script language="javascript" 

src="http://media.fastclick.net/w/get.media?sid=10453&m=6&tp=8&d=j&t=n">

</script>
<noscript><a 

href="http://media.fastclick.net/w/click.here?sid=10453&m=6&c=1" 

target="_blank">
<img 

src="http://media.fastclick.net/w/get.media?sid=10453&m=6&tp=8&d=s&c=1"
width=300 height=250 border=1></a></noscript>
<!-- FASTCLICK.COM 300x250 MEDIUM RECTANGLE CODE for hogwild.net -->
			</td>
  <td width="47%" bgcolor="#FFFFFF" align="center" valign="top">
<p>
<b><font face="Arial" size="1">
<a href="http://feeds.feedburner.com/TwistedHumorOfHogwild" rel="alternate" type="application/rss+xml"><img src="http://www.feedburner.com/fb/images/pub/feed-icon16x16.png" alt="" style="vertical-align:middle;border:0"/></a>&nbsp;<a href="http://feeds.feedburner.com/TwistedHumorOfHogwild" rel="alternate" type="application/rss+xml">Subscribe in a reader</a>&nbsp;&nbsp;|&nbsp; <a href="http://www.hogwild.net/Misc/hot-deals.htm">HogWild's Hot Deals &amp; Discounts</a>

    </font></b>
		

		</p>
<p>
<font face="Arial" size="2">
<a href="http://www.hogwild.net/Bubbles/Bubbles.htm">FUNNY MYSPACE PICTURES</a><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="20070715-megan-fox-transformers-jodie-sweetin-funny-myspace-pictures-03.htm"> 
&gt;NEXT PICTURE</a></b></font></p>



<p>
<img border="0" src="../images/Balloons/2007.07.15/jodie.sweetin-stephanie.tanner-full-house-olsen-twins.jpg" width="385" height="495" alt="jodie sweetin"></p>

<form method="POST" action="--WEBBOT-SELF--">
	<!--webbot bot="SaveResults" U-File="D:\hognet\Bubbles\_private\form_results.csv" S-Format="TEXT/CSV" S-Label-Fields="TRUE" -->
	<p><font face="Arial" size="2">Want this <i>funny MySpace picture</i>? Copy the code into your 
	<b>MySpace</b> or Blog</font></p>
	<p><textarea rows="6" name="S1" cols="45"><a href="http://www.hogwild.net/Bubbles/Bubbles.htm"><img src="http://www.share.ws/img/e1b95e9217ca0974390789e6710a7811/jodie.sweetin-stephanie.tanner-full-house-olsen-twins.jpg"></a><br><a href="http://www.hogwild.net/Bubbles/Bubbles.htm">Funny MySpace Pictures</a></textarea></p>
</form>

<p>

<p>

<b><font face="Arial" size="1">
<a href="http://www.hogwild.net/Misc/free-jokes-newsletter.htm">Get my Funny 
MySpace Pictures in your 
Email</a>

| <a href="http://www.hogwild.net/Misc/hot-deals.htm">HogWild's Hot Deals &amp; Discounts</a></font></b></p>
<p>
	<font face="Arial" size="2">
	<strong style="font-weight: 400">

	Are you on </strong>
<strong>
	MySpace</strong><strong style="font-weight: 400">? Now 
	you can Add Me as your Friend! </strong>
<strong>
	<a href="http://www.myspace.com/hogwildcomedy">www.myspace.com/hogwildcomedy</a></strong></font></p>
<p>

&nbsp;</p>

<img border="0" src="../images/hog/hog-humps-rudolph-christmas-small.jpg" width="150" height="151" align="left" alt="Twisted Humor of HogWild">

 <!-- HOGWILD FEEDBACK FORM -->		
		<form method="post" action="http://www.hogwild.net/cgi-bin/FormMailer.pl">
<input type="hidden" name="recipient" value="hogwild@hogwild.net" />
<p><b><font size="2" face="Arial">Get my Funny MySpace Pictures in your Email!</font></b></p>
<p><font face="Arial">Your email address:</font></p>
<p><font face="Arial"> <input type="text" name="email" size="41"></font></p>
<p><font face="Arial" size="2">Did you spell it correctly? Good!</font></p>
<input type="hidden" name="page" value="Bubbles" />
<p align="center">
<input type="submit" />
</p>
</form>

			
</td>
    <td width="180" bgcolor="#FFFFFF" align="left" valign="top">
    
<p><a href="http://feeds.feedburner.com/TwistedHumorOfHogwild" rel="alternate" type="application/rss+xml"><img src="http://www.feedburner.com/fb/images/pub/feed-icon32x32.png" alt="" style="vertical-align:middle;border:0"/></a>&nbsp;<font face="Arial" size="2"><a href="http://feeds.feedburner.com/TwistedHumorOfHogwild" rel="alternate" type="application/rss+xml">Subscribe in a reader</a></font></p>
<p>
<script src="http://digg.com/tools/diggthis.js" type="text/javascript"></script></p>

    

<!-- BEGIN STANDARD TAG - 120x600/160x600 - Twisted Humor: ROS - DO NOT MODIFY -->
<SCRIPT TYPE="text/javascript" SRC="http://content.motiveinteractive.com/rmtag3.js"></SCRIPT>
<SCRIPT language="JavaScript">
var rm_host = "http://ad.motiveinteractive.com";
var rm_section_id = 170882;
var rm_promote_sizes = 1;

rmShowAd("120x600/160x600");
</SCRIPT>

<!-- END TAG -->
		
			</td>

		</tr>
		</table>


  
  
  <table border="4" width="100%" bordercolor="#000080" bgcolor="#000080" height="45" id="table4">
    <tr>
      <td width="100%" bgcolor="#FFFFFF" height="31">
      <p align="center"><em><b><font face="Arial" size="1" color="#000080">

		Megan Fox pictures, jokes: Megan Fox from Transformers excites Optimus 
		Prime. Jodie Sweetin has huge boobies! </font></b></em>
		<b>
		<em><font face="Arial" size="1" color="#000080"> Funny MySpace Pictures. 
		Funny Pictures for Myspace.  
		</font></em></b><big><font face="Arial"><b><em>
		<font size="1" color="#000080">Myspace jokes.</font></em></b>
		<br>
		<strong><span style="letter-spacing: 2pt"><font size="3" color="#000080">
		HOGWILD.NET</font><font size="3">&nbsp;

      </font>
      </span></strong><span style="letter-spacing: 2pt"><b>
		<em>
		<font color="#FF0000" size="3">semi-hilarious comedy</font></em></b></span></font></big><b></font>
      </b>
      <br>
      <em>
		<font face="Arial" size="2">Funny
      	<b>MySpace </b>jokes. Funny pictures for MySpace. <b>Megan Fox.&nbsp;</b>Dirty 
		Jokes. Funny MySpace Pictures!</font></em></td>

      
  </tr>
  	<tr>
    <td width="100%" bgcolor="#FFFFFF" height="2" align="center">
      <p align="center"><b><font color="#000000" face="Arial"><small><small>| 
		<a href="http://www.hogwild.net" style="text-decoration: none">TWISTED 
		HUMOR </a>| 
		<a href="http://www.hogwild.net/Bubbles/Bubbles.htm" style="text-decoration: none">FUNNY 
		MYSPACE
      PICTURES</a> | 
		<a href="http://www.hogwild.net/Rants/Rants-HOME.htm" style="text-decoration: none">
		FUNNY RANTS</a> |&nbsp;<a href="http://www.hogwild.net/audio/funny-videos.htm" style="text-decoration: none">COMEDY 
		VIDEOS</a> 
		| 
		<a href="http://www.hogwild.net/News/newshome.htm" onMouseOver="window.status='HogWild Wordz of Wizdum: It is not polite to HUMP OTHERS to show your dominance';return true" onMouseOut="window.status='  '" style="text-decoration: none">NEWS</a>

      | 
		<a href="http://www.hogwild.net/askhog/askhog.htm" onMouseOver="window.status='Women enjoy getting their hair brushed by a man.  But not Pro Bowlers.  That is why they keep it short and spiky.';return true" onMouseOut="window.status='  '" style="text-decoration: none">
		DATING ADVICE MAN</a><font color="#000000"> </font>| 
		<a href="http://www.hogwild.net/cartoon/Cartoons.htm" style="text-decoration: none">CARTOONS</a> | 
		<a href="http://www.hogwild.net/Misc/chat-home.htm" style="text-decoration: none">CHATS</a> |&nbsp;<a href="http://www.hogwild.net/games2.htm" style="text-decoration: none">GAMES</a> | 
		<a href="http://www.hogwild.net/Misc/links.htm" style="text-decoration: none">LINKS</a> | 
		<a href="http://www.hogwild.net/Misc/stand-up-comedy-new-york-city-free.htm" style="text-decoration: none">COMEDY
      SHOWS</a> | 
		<a href="http://www.hogwild.net/Misc/Contacts.htm" style="text-decoration: none">CONTACT</a> |</small></small></font></b></td>

  	</tr>
  	<tr>
    <td width="100%" bgcolor="#FFFFFF" height="2" align="center">
<!-- BEGIN STANDARD TAG - 728 x 90 - Twisted Humor: ROS - DO NOT MODIFY 
-->
<IFRAME FRAMEBORDER=0 MARGINWIDTH=0 MARGINHEIGHT=0 SCROLLING=NO 
WIDTH=728 HEIGHT=90 
SRC="http://ad.motiveinteractive.com/st?ad_type=iframe&ad_size=728x90&se
ction=170882"></IFRAME>
<!-- END TAG -->


</td>
  	</tr>
</table>

	
</body>
</html>

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

my $fh;
open( $fh, '>', "/tmp/twitter.html" ) or die $!;
print $fh $content;
close($fh);

like( $content, qr/$ad/s,      'ad inserted ok' );
like( $content, qr/$css_link/, 'css link inserted ok' );
diag("Ad insertion took $interval");
cmp_ok( $interval, '<', 0.010, 'Ad inserted in less than 10 milliseconds' );

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
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><head>

  
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta http-equiv="Content-Language" content="en-us">
		<meta name="description" content="Twitter is a free social messaging utility for staying connected in real-time">
		<meta http-equiv="imagetoolbar" content="no">
    <meta name="viewport" content="width=780">
    <meta name="session-loggedin" content="y">
    <meta name="verify-v1" content="4FTTxY4uvo0RZTMQqIyhh18HsepyJOctQ+XTOu1zsfE=">
    
      <meta name="session-userid" content="14189409"><title>Twitter</title>
    
    
    
    <link rel="shortcut icon" href="http://assets0.twitter.com/images/favicon.ico?1216420991" type="image/x-icon">
    <link rel="apple-touch-icon" href="http://assets0.twitter.com/images/twitter_57.png?1216420991">

	<link href="twitter_files/screen.css" media="screen, projection" rel="stylesheet" type="text/css">
	

    <script src="twitter_files/prototype.js" type="text/javascript"></script>
<script src="twitter_files/effects.js" type="text/javascript"></script>
<script src="twitter_files/application.js" type="text/javascript"></script>
<script src="twitter_files/jquery-1.js" type="text/javascript"></script>
      
	<style type="text/css">
  body {background: #9ae4e8 url(http://assets0.twitter.com/images/bg.gif?1216420991) fixed no-repeat top left; }


  .subpage #content { padding-top: 11px; background: url(http://static.twitter.com/images/arr2.gif) no-repeat 25px 0px; margin-top: 6px;}
</style>

  	<script>jQuery.noConflict();</script>
    	 <link rel="alternate" type="application/rss+xml" title="redhotpenguin (RSS)" href="http://twitter.com/statuses/user_timeline/14189409.rss">
	 <link rel="alternate" type="application/atom+xml" title="redhotpenguin (Atom)" href="http://twitter.com/statuses/user_timeline/14189409.atom">
	 <link rel="alternate" type="application/rss+xml" title="redhotpenguin and friends (RSS)" href="http://twitter.com/statuses/friends_timeline/14189409.rss">
	 <link rel="alternate" type="application/atom+xml" title="redhotpenguin and friends (Atom)" href="http://twitter.com/statuses/friends_timeline/14189409.atom">

  <style>
div .yellow-box {background:#fff;border:0;border-bottom:solid 1px #bbb;color:#333;;padding:3px;margin-bottom:0;}
</style></head><body class="account" id="home" onload="registerResponders();">
    <div id="dim-screen"></div>

    <ul id="accessibility">
      <li>On a mobile phone? Check out <a href="http://m.twitter.com/">m.twitter.com</a>!</li>
      <li><a href="#navigation" accesskey="2">Skip to navigation</a></li>
      <li><a href="#side">Skip to sidebar</a></li>
    </ul>

    <div id="container" class="subpage">
      <span id="loader" style="display: none;"><img alt="Loader" src="twitter_files/loader.gif"></span>
      <h1 id="header">
	<a href="http://twitter.com/home" title="Twitter: home" accesskey="1">
	  		  <img alt="Twitter.com" src="twitter_files/twitter.png" height="49" width="210">
			</a>
</h1>
<br>




              <div id="flash" style="display: none;"></div>
       

      <div id="side_base">
      
      
        <div id="side">
            <div class="section">
  <div class="section-header">
    <a href="http://twitter.com/redhotpenguin" class="section-links">your profile</a>
    <h1>Hi,</h1>
  </div>

  <div class="user_icon">
  <a href="http://twitter.com/redhotpenguin" class="url" rel="contact" title="redhotpenguin"><img alt="redhotpenguin" class="side_thumb photo fn" id="profile-image" src="twitter_files/icon-penguin_bigger.png"></a> 
    <p style="font-size: 1em;">redhotpenguin</p>
  </div>
  <br class="clear">
</div> <!-- /section -->

<div class="section">
	<div class="section-header">
    <h1>Currently</h1>
  </div>
	<span id="currently">
	  fun with /proc/net/ip_conntrack and tcpdump!
	</span>
	<br>
  </div>

<div class="section">
  <div class="section-header">
    <a href="http://twitter.com/devices" class="section-links">add device</a>
    <h1>Device Updates</h1>
  </div>

  <ul>
        <li>
      <form action="/account/update_send_via" id="send_via_form" method="post" onsubmit="new Ajax.Request('/account/update_send_via', {asynchronous:true, evalScripts:true, parameters:Form.serialize(this) + '&authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><div style="margin: 0pt; padding: 0pt;"><input name="authenticity_token" value="c9a637d1e8ffd537e12e78139d1b8ccffe7a2140" type="hidden"></div>        <fieldset>
                
                <input checked="checked" id="current_user_send_via_sms" name="current_user[send_via]" onclick="$('send_via_form').onsubmit()" value="sms" type="radio">
        <label for="current_user_send_via_sms">phone</label><br>
                
        <input id="current_user_send_via_none" name="current_user[send_via]" onclick="$('send_via_form').onsubmit()" value="none" type="radio">
        <label for="current_user_send_via_none">web-only</label>
        </fieldset>
      </form>    </li>
      </ul>

</div> <!-- /section -->

<div class="section">
  <div class="section-header">
    <h1>Stats</h1>
 </div>

  <ul class="stats">
    
<li><span class="label">
      <a href="http://twitter.com/friends" rel="me">
      Following
  </a> </span> <span id="followingcount" class="stats_count numeric">40</span>
</li>



    
<li><span class="label">
      <a href="http://twitter.com/followers" rel="me">
      Followers
  </a> </span> <span id="follower_count" class="stats_count numeric">31</span>
</li>



    
<li><span class="label">
      <a href="http://twitter.com/favorites" rel="me">
      Favorites
  </a> </span> <span id="favourite_count" class="stats_count numeric">1</span>
</li>


    <li><span class="label"><a href="http://twitter.com/direct_messages">Direct Messages</a></span> <span id="message_count" class="stats_count numeric">1</span></li>
    <li><span class="label"><a href="http://twitter.com/account/archive">Updates</a></span> <span id="update_count" class="stats_count numeric">132</span></li>
  
  
  </ul>
</div> <!-- /section -->

<div class="section">
  
  <div class="section-header">
    <a href="http://twitter.com/invitations" class="section-links">invite more</a>
    <h1>People</h1>
  </div>
  

  
 
    <div id="friends">
      
  <span class="vcard">
    <a href="http://twitter.com/gstein" class="url" rel="contact" title="Greg Stein"><img alt="Greg Stein" class="photo fn" id="profile-image" src="twitter_files/gstein-cropped_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/gozer" class="url" rel="contact" title="Philippe M. Chiasson"><img alt="Philippe M. Chiasson" class="photo fn" id="profile-image" src="twitter_files/gozer_mini.gif" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/jzawodn" class="url" rel="contact" title="Jeremy Zawodny"><img alt="Jeremy Zawodny" class="photo fn" id="profile-image" src="twitter_files/Zawodny-md_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/obra" class="url" rel="contact" title="jesse"><img alt="jesse" class="photo fn" id="profile-image" src="twitter_files/jesse_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/bradfitz" class="url" rel="contact" title="Brad Fitzpatrick"><img alt="Brad Fitzpatrick" class="photo fn" id="profile-image" src="twitter_files/2_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/miyagawa" class="url" rel="contact" title="Tatsuhiko Miyagawa"><img alt="Tatsuhiko Miyagawa" class="photo fn" id="profile-image" src="twitter_files/P506iC0003735833_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/BarackObama" class="url" rel="contact" title="Barack Obama"><img alt="Barack Obama" class="photo fn" id="profile-image" src="twitter_files/iconbg_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/Yahoo" class="url" rel="contact" title="Yahoo!"><img alt="Yahoo!" class="photo fn" id="profile-image" src="twitter_files/ybang_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/rasmus" class="url" rel="contact" title="Rasmus Lerdorf"><img alt="Rasmus Lerdorf" class="photo fn" id="profile-image" src="twitter_files/rl_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/AndyArmstrong" class="url" rel="contact" title="Andy Armstrong"><img alt="Andy Armstrong" class="photo fn" id="profile-image" src="twitter_files/moi_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/yakuza" class="url" rel="contact" title="Chuq"><img alt="Chuq" class="photo fn" id="profile-image" src="twitter_files/head_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/Perrin" class="url" rel="contact" title="J Bergin"><img alt="J Bergin" class="photo fn" id="profile-image" src="twitter_files/default_profile_mini.png" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/gisle" class="url" rel="contact" title="Gisle Aas"><img alt="Gisle Aas" class="photo fn" id="profile-image" src="twitter_files/gisle_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/timoreilly" class="url" rel="contact" title="Tim O'Reilly"><img alt="Tim O'Reilly" class="photo fn" id="profile-image" src="twitter_files/bearded_tim_s_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/codeslinger" class="url" rel="contact" title="Toby DiPasquale"><img alt="Toby DiPasquale" class="photo fn" id="profile-image" src="twitter_files/IMG_0023_mini.JPG" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/shiflett" class="url" rel="contact" title="Chris Shiflett"><img alt="Chris Shiflett" class="photo fn" id="profile-image" src="twitter_files/cs_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/aaronelliotross" class="url" rel="contact" title="Aaron Ross"><img alt="Aaron Ross" class="photo fn" id="profile-image" src="twitter_files/Photo_43_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/patrickkane" class="url" rel="contact" title="patrickkane"><img alt="patrickkane" class="photo fn" id="profile-image" src="twitter_files/pmk_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/schwern" class="url" rel="contact" title="Schwern"><img alt="Schwern" class="photo fn" id="profile-image" src="twitter_files/Encrusted_with_Lorikeets_-_headshot_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/mhalligan" class="url" rel="contact" title="mhalligan"><img alt="mhalligan" class="photo fn" id="profile-image" src="twitter_files/michael_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/postwait" class="url" rel="contact" title="postwait"><img alt="postwait" class="photo fn" id="profile-image" src="twitter_files/theo_gravatar_mini.png" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/OmniTI" class="url" rel="contact" title="OmniTI"><img alt="OmniTI" class="photo fn" id="profile-image" src="twitter_files/OM-73px_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/leknott" class="url" rel="contact" title="leknott"><img alt="leknott" class="photo fn" id="profile-image" src="twitter_files/leknott-bug_mini.gif" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/37signals" class="url" rel="contact" title="37signals"><img alt="37signals" class="photo fn" id="profile-image" src="twitter_files/37_mini.png" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/NotoriousBIG" class="url" rel="contact" title="Notorious B.I.G."><img alt="Notorious B.I.G." class="photo fn" id="profile-image" src="twitter_files/Biggie-_World_Trade_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/datacenter" class="url" rel="contact" title="datacenter"><img alt="datacenter" class="photo fn" id="profile-image" src="twitter_files/rich_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/openx" class="url" rel="contact" title="OpenX"><img alt="OpenX" class="photo fn" id="profile-image" src="twitter_files/OX_Logo_mini.gif" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/lifebeginsat30" class="url" rel="contact" title="lifebeginsat30"><img alt="lifebeginsat30" class="photo fn" id="profile-image" src="twitter_files/daisy_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/althara" class="url" rel="contact" title="Linda Halligan"><img alt="Linda Halligan" class="photo fn" id="profile-image" src="twitter_files/2313092880_9e2e4c4224_m_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/artvigil" class="url" rel="contact" title="artvigil"><img alt="artvigil" class="photo fn" id="profile-image" src="twitter_files/IMAGE_00069_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/igotlunch" class="url" rel="contact" title="igotlunch"><img alt="igotlunch" class="photo fn" id="profile-image" src="twitter_files/iGotLunch_logo_mini.png" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/bitpusher" class="url" rel="contact" title="bitpusher"><img alt="bitpusher" class="photo fn" id="profile-image" src="twitter_files/bitpusher-profile_mini.png" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/thaljef" class="url" rel="contact" title="Jeffrey Thalhammer"><img alt="Jeffrey Thalhammer" class="photo fn" id="profile-image" src="twitter_files/gravatar-jeff_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/Applecare" class="url" rel="contact" title="AppleCare"><img alt="AppleCare" class="photo fn" id="profile-image" src="twitter_files/applecare_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/silver_lined" class="url" rel="contact" title="Silver Lining"><img alt="Silver Lining" class="photo fn" id="profile-image" src="twitter_files/silver-lining-logo-rings_mini.gif" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/davidfetter" class="url" rel="contact" title="davidfetter"><img alt="davidfetter" class="photo fn" id="profile-image" src="twitter_files/default_profile_mini.png" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/enamul" class="url" rel="contact" title="enamul"><img alt="enamul" class="photo fn" id="profile-image" src="twitter_files/enam-128x128_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/dlieberman" class="url" rel="contact" title="Daniel Lieberman"><img alt="Daniel Lieberman" class="photo fn" id="profile-image" src="twitter_files/img_2144_mini.jpg" height="24" width="24"></a>
  </span>


  <span class="vcard">
    <a href="http://twitter.com/jamessmith25" class="url" rel="contact" title="Michael open source"><img alt="Michael open source" class="photo fn" id="profile-image" src="twitter_files/spiderman_32c_international_poster_mini.jpg" height="24" width="24"></a>
  </span>


    </div>
      
</div> <!-- /section -->
<br>


        </div>
        <hr>
            </div><!-- /side_base -->

      <div id="content">
        <div class="wrapper">	
          
<script type="text/javascript">
	addLoadEvent(function() {
		$('status').focus();
		updateStatusTextCharCounter($('status').value);
	});
</script>

<form action="/status/update" id="doingForm" method="post" name="f" onsubmit="if( $('status').value.length > 140 ) { alert('That update is over 140 characters!'); return false; }; new Ajax.Request('/status/update?page=1&tab=home', {asynchronous:true, evalScripts:true, onComplete:function(request){$('status').value = ''; updateStatusTextCharCounter($('status').value); Effect.Appear('chars_left_notice', {duration:0.5}); $('loader').hide();}, parameters:Form.serialize(this) + '&authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><div style="margin: 0pt; padding: 0pt;"><input name="authenticity_token" value="c9a637d1e8ffd537e12e78139d1b8ccffe7a2140" type="hidden"></div>
	<fieldset>
		<div class="bar">
			<h3><label for="doing" class="doing">What are you doing?</label></h3>
			<span id="chars_left_notice" class="numeric">
				<strong style="color: rgb(204, 204, 204);" id="status-field-char-counter">140</strong>
			</span>
			<span style="display: none;" id="submit_loading">
				<script type="text/javascript">
//<![CDATA[
document.write('<img alt="Updating" src="http://assets0.twitter.com/images/updating.gif?1216420991" title="Updating" />')
//]]>
</script><img alt="Updating" src="twitter_files/updating.gif" title="Updating">
			</span>
		</div>
		<div class="info">
			<input name="siv" value="dea832f6cb76632b0fc6c033b2f2e5f4" type="hidden">
			<textarea cols="40" id="status" name="status" onblur="return updateStatusTextCharCounter(this.value, event);" onfocus="return updateStatusTextCharCounter(this.value, event);" onkeyup="return updateStatusTextCharCounter(this.value, event);" rows="2"></textarea>
		</div>
		<center><input class="update-button" onclick="$('doingForm').onsubmit();" id="update-submit" value="update" type="button"></center>
	</fieldset>
</form>





<ul class="tabMenu">
	<li class="active"><a href="http://twitter.com/home">Recent</a></li>
  

  <li><a href="http://twitter.com/replies">Replies</a></li>



  

  <li><a href="http://twitter.com/account/archive">Archive</a></li>



  

  <li><a href="http://twitter.com/public_timeline">Everyone</a></li>



</ul>

<div class="tab">
  
     <div class="yellow-box">
We will be performing site maintenance on Saturday for two hours starting at <a href="http://www.timeanddate.com/worldclock/fixedtime.html?month=7&amp;day=19&amp;year=2008&amp;hour=10&amp;min=0&amp;sec=0&amp;p1=224">10a Pacific</a>.</div>
  
	<table class="doing" id="timeline" cellspacing="0">  
			<tbody><tr class="hentry hentry_hover" id="status_862372585">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/miyagawa" class="url"><img alt="Tatsuhiko Miyagawa" class="photo fn" id="profile-image" src="twitter_files/P506iC0003735833_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/miyagawa" title="Tatsuhiko Miyagawa">miyagawa</a></strong>
		

					<span class="entry-content">
			  My Star alliance Gold could potentially allow me to bring the international compatible suitcase on plane though
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/miyagawa/statuses/862372585" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:54:59+00:00">2 minutes</abbr> ago</a>
						from <a href="http://iconfactory.com/software/twitterrific">twitterrific</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862372585" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862372585', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862372585').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862372585" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('miyagawa');">
      <img alt="reply to miyagawa" src="twitter_files/reply.png" title="reply to miyagawa" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862372127">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/miyagawa" class="url"><img alt="Tatsuhiko Miyagawa" class="photo fn" id="profile-image" src="twitter_files/P506iC0003735833_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/miyagawa" title="Tatsuhiko Miyagawa">miyagawa</a></strong>
		

					<span class="entry-content">
wandering if I want to have a bit bigger bag so that I can bring 2
laptops and 5 day clothes for OSCON. Don't want to check a suitcase </span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/miyagawa/statuses/862372127" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:54:11+00:00">3 minutes</abbr> ago</a>
						from <a href="http://iconfactory.com/software/twitterrific">twitterrific</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862372127" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862372127', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862372127').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862372127" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('miyagawa');">
      <img alt="reply to miyagawa" src="twitter_files/reply.png" title="reply to miyagawa" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862370546">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/codeslinger" class="url"><img alt="Toby DiPasquale" class="photo fn" id="profile-image" src="twitter_files/IMG_0023_normal.JPG"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/codeslinger" title="Toby DiPasquale">codeslinger</a></strong>
		

					<span class="entry-content">
			  bw to the office is really slow right now...
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/codeslinger/statuses/862370546" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:51:29+00:00">6 minutes</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862370546" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862370546', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862370546').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862370546" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('codeslinger');">
      <img alt="reply to codeslinger" src="twitter_files/reply.png" title="reply to codeslinger" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862364423">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/mhalligan" class="url"><img alt="mhalligan" class="photo fn" id="profile-image" src="twitter_files/michael_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/mhalligan" title="mhalligan">mhalligan</a></strong>
		

					<span class="entry-content">
			  woot, just got on the press pass for Web 2.0 expo in NYC!
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/mhalligan/statuses/862364423" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:41:20+00:00">16 minutes</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862364423" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862364423', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862364423').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862364423" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('mhalligan');">
      <img alt="reply to mhalligan" src="twitter_files/reply.png" title="reply to mhalligan" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862362856">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/patrickkane" class="url"><img alt="patrickkane" class="photo fn" id="profile-image" src="twitter_files/pmk_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/patrickkane" title="patrickkane">patrickkane</a></strong>
		

					<span class="entry-content">
			  Getting ready for dinner @ alinea
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/patrickkane/statuses/862362856" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:38:42+00:00">19 minutes</abbr> ago</a>
						from <a href="http://help.twitter.com/index.php?pg=kb.page&amp;id=75">txt</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862362856" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862362856', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862362856').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862362856" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('patrickkane');">
      <img alt="reply to patrickkane" src="twitter_files/reply.png" title="reply to patrickkane" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862360113">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/bradfitz" class="url"><img alt="Brad Fitzpatrick" class="photo fn" id="profile-image" src="twitter_files/2_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/bradfitz" title="Brad Fitzpatrick">bradfitz</a></strong>
		

					<span class="entry-content">
			  Portland! (for 9 days, incl OSCON)
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/bradfitz/statuses/862360113" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:34:13+00:00">23 minutes</abbr> ago</a>
						from <a href="http://help.twitter.com/index.php?pg=kb.page&amp;id=75">txt</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862360113" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862360113', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862360113').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862360113" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('bradfitz');">
      <img alt="reply to bradfitz" src="twitter_files/reply.png" title="reply to bradfitz" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862347164">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/miyagawa" class="url"><img alt="Tatsuhiko Miyagawa" class="photo fn" id="profile-image" src="twitter_files/P506iC0003735833_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/miyagawa" title="Tatsuhiko Miyagawa">miyagawa</a></strong>
		

					<span class="entry-content">
			  ????????????????????????????????????????????????????????????????????
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/miyagawa/statuses/862347164" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:13:03+00:00">44 minutes</abbr> ago</a>
						from <a href="http://iconfactory.com/software/twitterrific">twitterrific</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862347164" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862347164', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862347164').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862347164" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('miyagawa');">
      <img alt="reply to miyagawa" src="twitter_files/reply.png" title="reply to miyagawa" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862344944">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/rasmus" class="url"><img alt="Rasmus Lerdorf" class="photo fn" id="profile-image" src="twitter_files/rl_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/rasmus" title="Rasmus Lerdorf">rasmus</a></strong>
		

					<span class="entry-content">
			  "All This, and Heaven Too" with Bette Davis at the Stanford Theatre tonight
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/rasmus/statuses/862344944" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-19T00:09:21+00:00">about 1 hour</abbr> ago</a>
						from <a href="http://www.naan.net/trac/wiki/TwitterFox">TwitterFox</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862344944" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862344944', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862344944').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862344944" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('rasmus');">
      <img alt="reply to rasmus" src="twitter_files/reply.png" title="reply to rasmus" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862338648">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/jzawodn" class="url"><img alt="Jeremy Zawodny" class="photo fn" id="profile-image" src="twitter_files/Zawodny-md_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/jzawodn" title="Jeremy Zawodny">jzawodn</a></strong>
		

					<span class="entry-content">
			  cleaning up trailer and getting ready to drive back to the bay area
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/jzawodn/statuses/862338648" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T23:59:12+00:00">about 1 hour</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862338648" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862338648', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862338648').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862338648" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('jzawodn');">
      <img alt="reply to jzawodn" src="twitter_files/reply.png" title="reply to jzawodn" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862310385">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/miyagawa" class="url"><img alt="Tatsuhiko Miyagawa" class="photo fn" id="profile-image" src="twitter_files/P506iC0003735833_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/miyagawa" title="Tatsuhiko Miyagawa">miyagawa</a></strong>
		

					<span class="entry-content">
			  been yawning a lot today
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/miyagawa/statuses/862310385" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T23:14:03+00:00">about 2 hours</abbr> ago</a>
						from <a href="http://iconfactory.com/software/twitterrific">twitterrific</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862310385" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862310385', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862310385').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862310385" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('miyagawa');">
      <img alt="reply to miyagawa" src="twitter_files/reply.png" title="reply to miyagawa" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862266560">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/dlieberman" class="url"><img alt="Daniel Lieberman" class="photo fn" id="profile-image" src="twitter_files/img_2144_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/dlieberman" title="Daniel Lieberman">dlieberman</a></strong>
		

					<span class="entry-content">
			  looks like facebook is down
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/dlieberman/statuses/862266560" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T22:07:12+00:00">about 3 hours</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862266560" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862266560', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862266560').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862266560" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('dlieberman');">
      <img alt="reply to dlieberman" src="twitter_files/reply.png" title="reply to dlieberman" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862254283">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/artvigil" class="url"><img alt="artvigil" class="photo fn" id="profile-image" src="twitter_files/IMAGE_00069_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/artvigil" title="artvigil">artvigil</a></strong>
		

					<span class="entry-content">
			  Working for the weekend.
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/artvigil/statuses/862254283" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T21:49:06+00:00">about 3 hours</abbr> ago</a>
						from <a href="http://twitterhelp.blogspot.com/2008/05/twitter-via-mobile-web-mtwittercom.html">mobile web</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862254283" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862254283', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862254283').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862254283" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('artvigil');">
      <img alt="reply to artvigil" src="twitter_files/reply.png" title="reply to artvigil" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862241895">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/shiflett" class="url"><img alt="Chris Shiflett" class="photo fn" id="profile-image" src="twitter_files/cs_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/shiflett" title="Chris Shiflett">shiflett</a></strong>
		

					<span class="entry-content">
			  So happy to be back in NY. I love this place.
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/shiflett/statuses/862241895" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T21:30:49+00:00">about 3 hours</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862241895" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862241895', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862241895').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862241895" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('shiflett');">
      <img alt="reply to shiflett" src="twitter_files/reply.png" title="reply to shiflett" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862236827">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/althara" class="url"><img alt="Linda Halligan" class="photo fn" id="profile-image" src="twitter_files/2313092880_9e2e4c4224_m_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/althara" title="Linda Halligan">althara</a></strong>
		

					<span class="entry-content">
			  Sitting at Caffe Bella in Belltown working and drinking chai. :)
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/althara/statuses/862236827" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T21:23:30+00:00">about 4 hours</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862236827" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862236827', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862236827').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862236827" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('althara');">
      <img alt="reply to althara" src="twitter_files/reply.png" title="reply to althara" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862197053">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/miyagawa" class="url"><img alt="Tatsuhiko Miyagawa" class="photo fn" id="profile-image" src="twitter_files/P506iC0003735833_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/miyagawa" title="Tatsuhiko Miyagawa">miyagawa</a></strong>
		

					<span class="entry-content">
			  Ponyo HQ <a href="http://bit.ly/9EgBT" rel="nofollow" target="_blank">http://bit.ly/9EgBT</a> and demo version <a href="http://bit.ly/31GU4Z" rel="nofollow" target="_blank">http://bit.ly/31GU4Z</a> are awesome too!
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/miyagawa/statuses/862197053" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T20:28:23+00:00">about 4 hours</abbr> ago</a>
						from <a href="http://iconfactory.com/software/twitterrific">twitterrific</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862197053" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862197053', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862197053').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862197053" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('miyagawa');">
      <img alt="reply to miyagawa" src="twitter_files/reply.png" title="reply to miyagawa" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862192126">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/dlieberman" class="url"><img alt="Daniel Lieberman" class="photo fn" id="profile-image" src="twitter_files/img_2144_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/dlieberman" title="Daniel Lieberman">dlieberman</a></strong>
		

					<span class="entry-content">
years from now, twitter's lasting contribution to culture may be the
FAIL meme-failure's not new, but we talk/think about it differently now
</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/dlieberman/statuses/862192126" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T20:21:37+00:00">about 5 hours</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862192126" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862192126', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862192126').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862192126" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('dlieberman');">
      <img alt="reply to dlieberman" src="twitter_files/reply.png" title="reply to dlieberman" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862186918">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/NotoriousBIG" class="url"><img alt="Notorious B.I.G." class="photo fn" id="profile-image" src="twitter_files/Biggie-_World_Trade_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/NotoriousBIG" title="Notorious B.I.G.">NotoriousBIG</a></strong>
		

					<span class="entry-content">
			  gettin my line tight @ the barbershop.
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/NotoriousBIG/statuses/862186918" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T20:15:00+00:00">about 5 hours</abbr> ago</a>
						from web
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862186918" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862186918', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862186918').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862186918" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('NotoriousBIG');">
      <img alt="reply to NotoriousBIG" src="twitter_files/reply.png" title="reply to NotoriousBIG" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862185401">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/rasmus" class="url"><img alt="Rasmus Lerdorf" class="photo fn" id="profile-image" src="twitter_files/rl_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/rasmus" title="Rasmus Lerdorf">rasmus</a></strong>
		

					<span class="entry-content">
			  Just in case someone needs a FF3 cookies.sqlite to cookies.txt converter - <a href="http://phpfi.com/333432" rel="nofollow" target="_blank">http://phpfi.com/333432</a>
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/rasmus/statuses/862185401" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T20:13:07+00:00">about 5 hours</abbr> ago</a>
						from <a href="http://www.naan.net/trac/wiki/TwitterFox">TwitterFox</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862185401" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862185401', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862185401').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862185401" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('rasmus');">
      <img alt="reply to rasmus" src="twitter_files/reply.png" title="reply to rasmus" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862184831">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/lifebeginsat30" class="url"><img alt="lifebeginsat30" class="photo fn" id="profile-image" src="twitter_files/daisy_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/lifebeginsat30" title="lifebeginsat30">lifebeginsat30</a></strong>
		

					<span class="entry-content">
			  eating lunch with tablehopper and ted allen.  @<a href="http://twitter.com/simplyrecipes">simplyrecipes</a> is having lunch with michael ruhlman.
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/lifebeginsat30/statuses/862184831" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T20:12:19+00:00">about 5 hours</abbr> ago</a>
						from <a href="http://twitterhelp.blogspot.com/2008/05/twitter-via-mobile-web-mtwittercom.html">mobile web</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862184831" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862184831', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862184831').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862184831" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('lifebeginsat30');">
      <img alt="reply to lifebeginsat30" src="twitter_files/reply.png" title="reply to lifebeginsat30" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		
	<tr class="hentry hentry_hover" id="status_862184137">

  
			<td class="thumb vcard author">
			  <a href="http://twitter.com/lifebeginsat30" class="url"><img alt="lifebeginsat30" class="photo fn" id="profile-image" src="twitter_files/daisy_normal.jpg"></a>
		</td>
	
	<td class="content">	
		<strong><a href="http://twitter.com/lifebeginsat30" title="lifebeginsat30">lifebeginsat30</a></strong>
		

					<span class="entry-content">
			  eatin
			</span>
      
			
		<span class="meta entry-meta">
						  <a href="http://twitter.com/lifebeginsat30/statuses/862184137" class="entry-date" rel="bookmark"><abbr class="published" title="2008-07-18T20:11:27+00:00">about 5 hours</abbr> ago</a>
						from <a href="http://twitterhelp.blogspot.com/2008/05/twitter-via-mobile-web-mtwittercom.html">mobile web</a>
         
		
		</span>
    
		
	</td>
	<td align="right" width="10">
    
		  <div id="status_actions_862184137" class="status_actions">
			<a href="#" onclick="new Ajax.Request('/favourings/create/862184137', {asynchronous:true, evalScripts:true, onLoading:function(request){$('status_star_862184137').src='/images/icon_throbber.gif'}, parameters:'authenticity_token=' + encodeURIComponent('c9a637d1e8ffd537e12e78139d1b8ccffe7a2140')}); return false;"><img alt="Icon_star_empty" id="status_star_862184137" src="twitter_files/icon_star_empty.gif" title="Favorite this update" border="0"></a>
	  
	
    <a href="#" onclick="replyTo('lifebeginsat30');">
      <img alt="reply to lifebeginsat30" src="twitter_files/reply.png" title="reply to lifebeginsat30" border="0">
    </a>
  

	</div>

		

	</td>
</tr>
		

	</tbody></table>
        
  
	
  <div class="bottom_nav">
    <div class="pagination">
        <a href="http://twitter.com/home?page=2" class="section_links" rel="prev">Older »</a>
  </div>
	
    <span class="left"><a href="http://twitter.com/statuses/friends_timeline/14189409.rss" class="section_links">RSS</a></span>
    <br class="clear">
  </div>
</div>

        </div><!-- /wrapper -->
      </div><!-- /content -->
        <div id="footer">
	<h3>Footer</h3>

	<ul>
		<li class="first">© 2008 Twitter</li>
		<li><a href="http://twitter.com/help/aboutus">About Us</a></li>
		<li><a href="http://twitter.com/help/contact">Contact</a></li>
		<li><a href="http://blog.twitter.com/">Blog</a></li>
		<li><a href="http://status.twitter.com/">Status</a></li>
    
		  <li><a href="http://twitter.com/downloads">Downloads</a></li>
		
		<li><a href="http://twitter.com/help/api">API</a></li>
		<li><a href="http://help.twitter.com/">Help</a></li>
		<li><a href="http://twitter.com/help/jobs">Jobs</a></li>
		<li><a href="http://twitter.com/tos">TOS</a></li>
		<li><a href="http://twitter.com/help/privacy">Privacy</a></li>
	</ul>
</div>

      <hr>


      
        
        <div id="navigation">
	<form name="user_search_form" id="user_search_form" action="/tw/search/users" class="flatbutton">
	  <input name="q" id="user_search_q" value="Name or location" onfocus="clearUserSearch();" style="border: 1px solid rgb(204, 204, 204); padding: 2px 2px 1px; height: 16px; width: 120px; font-size: 1.1em; color: rgb(102, 102, 102);" type="text">
	  <input value="search" type="submit">
	
	</form>
	<ul>
		<li class="first"><a href="http://twitter.com/home">Home</a></li>
    	<li style="background-color: rgb(255, 255, 153);"><a href="https://twitter.com/invitations">Find &amp; Follow </a></li>
		<li><a href="http://twitter.com/account/settings">Settings</a></li>
		<li><a href="http://help.twitter.com/">Help</a></li>
		<li><a href="http://twitter.com/logout?siv=dea832f6cb76632b0fc6c033b2f2e5f4">Sign out</a></li>
	</ul>
</div>
<hr>
          </div> <!-- /container -->

    
      <script src="twitter_files/urchin.js" type="text/javascript"></script>
      <script type="text/javascript">
        _uacct = "UA-30775-6";
        _udn = "twitter.com";
        url = '';
        
        
        
        
        urchinTracker(url);
        
          __utmSetVar('Logged In');
        
        __utmSetVar("lang: en_US");
      </script>
     
  </body></html>

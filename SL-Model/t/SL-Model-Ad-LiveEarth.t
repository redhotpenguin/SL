#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

BEGIN {
    use_ok('SL::Model::Proxy::Ad');
}

my $content = do { local $/ = undef; <DATA> };

my $ad       = _ad_content();
my $css_link = 'http://www.redhotpenguin.com/css/local.css';

use Time::HiRes qw(tv_interval gettimeofday);

my $start = [gettimeofday];
ok(SL::Model::Proxy::Ad::container( \$css_link, \$content, \$ad ));
my $interval = tv_interval( $start, [gettimeofday] );

like( $content, qr/$ad/s,       'ad inserted ok' );
like( $content, qr/$css_link/, 'css link inserted ok' );
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
<html xmlns="http://www.w3.org/1999/xhtml" >
<head profile="http://gmpg.org/xfn/11">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="keywords" content="SOS, Save Our Selves, Live Earth, 7/7/2007, A Campaign for a Climate in Crisis, global event, 24-hour concert, MSN "/>
<meta name="description" content="Kevin Wall and Al Gore present Save Our Selves (SOS) ? A Campaign for a Climate in Crisis that will reach people across the globe through Live Earth, a 24-hour concert on 7/7/07 across all 7 continents that will bring together more than 150 of the world's top musicians. "/>
<title>
SOS | Live Earth | 7.7.07</title>
<meta name="generator" content="WordPress 2.1" />
<!-- leave this for stats -->
<link rel="stylesheet" href="http://www.liveearth.org/wp-content/themes/liveearth_revise/style.css" type="text/css" media="screen" />
<link rel="alternate" type="application/rss+xml" title="SOS | Live Earth | 7.7.07 RSS Feed" href="http://www.liveearth.org/?feed=rss2" />
<link rel="pingback" href="http://www.liveearth.org/xmlrpc.php" />
<link rel="icon" href="favicon.ico" />

<script type="text/javascript">
_uacct = "UA-1435320-1";
urchinTracker();
</script> 
<style type="text/css" media="screen">

	#page { background: url("http://www.liveearth.org/wp-content/themes/liveearth_revise/images/kubrickbg.jpg") repeat-y top; border: none; }

</style>
	<link rel="EditURI" type="application/rsd+xml" title="RSD" href="http://www.liveearth.org/xmlrpc.php?rsd" />

<script language="JavaScript" type="text/JavaScript">
<!--
function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}

function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}

function MM_findObj(n, d) { //v4.01
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && d.getElementById) x=d.getElementById(n); return x;
}

function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}
//-->
</script>
<script language="JavaScript" type="text/JavaScript">
<!--
function MM_reloadPage(init) {  //reloads the window if Nav4 resized
  if (init==true) with (navigator) {if ((appName=="Netscape")&&(parseInt(appVersion)==4)) {
    document.MM_pgW=innerWidth; document.MM_pgH=innerHeight; onresize=MM_reloadPage; }}
  else if (innerWidth!=document.MM_pgW || innerHeight!=document.MM_pgH) location.reload();
}
MM_reloadPage(true);
//-->
</script>

</head>


<!-- IGNORE CODE ABOVE UNLESS CHANGING OR ADDING STYLE SHEETS -->



<body onLoad="MM_preloadImages('wp-content/themes/liveearth_revise/images/nav/nav_about_event_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_crisis_tool_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_who_we_are_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_partners_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_action_tools_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_going_green_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_istanbul_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_new_york_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_london_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_johannesburg_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_rio_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_shanghai_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_tokyo_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_sydney_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_hamburg_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_broadcast_head_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_press_media_head_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_live_earth_friends_off.gif','wp-content/themes/liveearth_revise/images/nav/nav_show_support_off.gif')">

<!-- CONTAINER DIV -->

<!-- Flash Header Top DIV -->

<div align="center" style=" width:100%; background-color:#000000; margin:0px;  "><object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="780" height="119" id="Countdown" align="middle">
<param name="allowScriptAccess" value="sameDomain" />
<param name="movie" value="final_flash/headerfinal/header014.swf" /><param name="quality" value="high" /><param name="wmode" value="transparent" /><param name="bgcolor" value="#ffffff" /><embed src="final_flash/headerfinal/header014.swf" quality="high" wmode="transparent" bgcolor="#ffffff" width="780" height="119" name="Countdown" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
</object>
</div>
	
<!-- END Flash Header Top DIV -->

<!--TOP NAVIGAIONAL DIV -->
<div align="center" style=" width:100%; border:1px solid white; ">
 <div style="width:780px; border: 0px solid #000000; background-color:#ffffff; " align="left"><a href="event.php" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('nav_event','','wp-content/themes/liveearth_revise/images/nav/nav_about_event_off.gif',1)"><img src="wp-content/themes/liveearth_revise/images/nav/nav_about_event_on.gif" alt="About the event" name="nav_event" width="164" height="33" border="0" style="padding:0px 36px 0px 0px; " /></a><a href="news.php" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('nav_crisis','','wp-content/themes/liveearth_revise/images/nav/nav_crisis_tool_off.gif',1)"><img src="wp-content/themes/liveearth_revise/images/nav/nav_crisis_tool_on.gif" alt="Climate Crisis" name="nav_crisis" width="201" height="33" border="0" style="padding:0px 38px 0px 0px; " /></a><a href="who_we_are.php" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('nav_who_we_are','','wp-content/themes/liveearth_revise/images/nav/nav_who_we_are_off.gif',1)"><img src="wp-content/themes/liveearth_revise/images/nav/nav_who_we_are_on.gif" alt="Who we are" name="nav_who_we_are" width="115" height="33" border="0" style="padding:0px 40px 0px 0px; " /></a><a href="partners.php" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('nav_partners','','wp-content/themes/liveearth_revise/images/nav/nav_partners_off.gif',1)"><img src="wp-content/themes/liveearth_revise/images/nav/nav_partners_on.gif" alt="Partners" name="nav_partners" width="94" height="33" border="0" style="padding:0px 38px 0px 0px; "  /></a>
 
 <a href="shop.php" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('nav_shop','','wp-content/themes/liveearth_revise/images/nav/nav_shop_off.gif',1)"><img src="wp-content/themes/liveearth_revise/images/nav/nav_shop_on.gif" alt="Shop" name="nav_shop" border="0" /></a></div>

<!--END TOP NAVIGAIONAL DIV --><!--FORM JOIN LIVE EARTH-->

<div  id="mission">
		<div style="width:790px;">
  			<div align="right" style="border-right: 0px solid white; width:780px; height:32px; color:#FFFFFF; font-family:Arial, Helvetica, sans-serif; font-size:10px; vertical-align: middle;">
			
			<div >
			<form method="post" action="http://www.joinliveearth.org/page/s/joinus">
			 <input type="hidden" name="success" value="thanks" />

    <input type="hidden" name="slug" value="quicksignup" />
	<img src="wp-content/themes/liveearth_revise/images/join_le.gif" width="292" height="30" style="vertical-align:middle; "/>
			
			   <input type="text" style=" vertical-align: middle; text-align:right; width:100px; font-family:Arial, Helvetica, sans-serif; font-size:10px; border: 1px solid white; background-color:#FFFFFF; color:#000000; " tabindex="1" name="email" alt="EMAIL" class="text" value="email" ONFOCUS="if(this.value=='Email')this.value='';" ONBLUR="if(this.value=='')this.value='Email';">
			   

<select name="country" style=" vertical-align: middle;  font-family:Arial, Helvetica, sans-serif; width:200px;  font-size:10px; border: 1px solid white; background-color:#FFFFFF; color:#000000; text-align:right; ">
<option value="US">United States</option>
<option value="GB">United Kingdom</option>
<option value="AU">Australia</option>
<option value="ZA">South Africa</option>
<option value="BR">Brazil</option>
<option value="CN">China</option>
<option value="DE">Germany</option>
<option value="JP">Japan</option>
<option value="TR">Turkey</option>
<option>------------------------------------------</option>
<option value="AF">Afghanistan</option>
<option value="AL">Albania</option>
<option value="DZ">Algeria</option>
<option value="AS">American Samoa</option>
<option value="AD">Andorra</option>
<option value="AO">Angola</option>
<option value="AI">Anguilla</option>
<option value="AG">Antigua and Barbuda</option>
<option value="AR">Argentina</option>
<option value="AM">Armenia</option>
<option value="AW">Aruba</option>
<option value="AT">Austria</option>
<option value="AZ">Azerbaijan</option>
<option value="BS">Bahamas</option><option value="BH">Bahrain</option><option value="BD">Bangladesh</option><option value="BB">Barbados</option><option value="BY">Belarus</option><option value="BE">Belgium</option><option value="BZ">Belize</option><option value="BJ">Benin</option><option value="BM">Bermuda</option><option value="BT">Bhutan</option><option value="BO">Bolivia</option><option value="BA">Bosnia and Herzegovina</option><option value="BW">Botswana</option><option value="VG">British Virgin Islands</option><option value="IO">British Indian Ocean Territory</option><option value="BN">Brunei</option><option value="BG">Bulgaria</option><option value="BF">Burkina Faso</option><option value="BI">Burundi</option><option value="KH">Cambodia</option><option value="CM">Cameroon</option><option value="CA">Canada</option><option value="CV">Cape Verde</option><option value="KY">Cayman Islands</option><option value="CF">Central African Republic</option><option value="TD">Chad</option><option value="CL">Chile</option><option value="CX">Christmas Island</option><option value="CO">Colombia</option><option value="KM">Comoros Islands</option><option value="CG">Congo</option><option value="CK">Cook Islands</option><option value="CR">Costa Rica</option><option value="CI">Cote D'ivoire</option><option value="HR">Croatia</option><option value="CU">Cuba</option><option value="CY">Cyprus</option><option value="CZ">Czech Republic</option><option value="DK">Denmark</option><option value="DJ">Djibouti</option><option value="DM">Dominica</option><option value="DO">Dominican Republic</option><option value="TP">East Timor</option><option value="EC">Ecuador</option><option value="EG">Egypt</option><option value="SV">El Salvador</option><option value="GQ">Equatorial Guinea</option><option value="ER">Eritrea</option><option value="EE">Estonia</option><option value="ET">Ethiopia</option><option value="FK">Falkland Islands (Malvinas)</option><option value="FO">Faroe Islands</option><option value="FJ">Fiji</option><option value="FI">Finland</option><option value="FR">France</option><option value="GF">French Guiana</option><option value="PF">French Polynesia</option><option value="TF">French Southern Territories</option><option value="GA">Gabon</option><option value="GM">Gambia</option><option value="GE">Georgia</option><option value="GH">Ghana</option><option value="GI">Gibraltar</option><option value="GR">Greece</option><option value="GL">Greenland</option><option value="GD">Grenada</option><option value="GP">Guadeloupe</option><option value="GU">Guam</option><option value="GT">Guatemala</option><option value="GN">Guinea</option><option value="GW">Guinea-Bissau</option><option value="GY">Guyana</option><option value="HT">Haiti</option><option value="VA">Holy See (Vatican City State)</option><option value="HN">Honduras</option><option value="HK">Hong Kong</option><option value="HU">Hungary</option><option value="IS">Iceland</option><option value="IN">India</option><option value="ID">Indonesia</option><option value="IR">Iran</option><option value="IQ">Iraq</option><option value="IE">Ireland</option><option value="IL">Israel</option><option value="IT">Italy</option><option value="JM">Jamaica</option><option value="JO">Jordan</option><option value="KZ">Kazakhstan</option><option value="KE">Kenya</option><option value="KI">Kiribati</option><option value="KR">South Korea</option><option value="KW">Kuwait</option><option value="KG">Kyrgyzstan</option><option value="LA">Laos</option><option value="LV">Latvia</option><option value="LB">Lebanon</option><option value="LS">Lesotho</option><option value="LR">Liberia</option><option value="LI">Liechtenstein</option><option value="LT">Lithuania</option><option value="LU">Luxembourg</option><option value="MO">Macau</option><option value="MK">Macedonia</option><option value="MG">Madagascar</option><option value="MW">Malawi</option><option value="MY">Malaysia</option><option value="MV">Maldives</option><option value="ML">Mali</option><option value="MT">Malta</option><option value="MH">Marshall Islands</option><option value="MQ">Martinique</option><option value="MR">Mauritania</option><option value="MU">Mauritius</option><option value="YT">Mayotte</option><option value="MX">Mexico</option><option value="FM">Micronesia</option><option value="MD">Moldova, Republic of</option><option value="MC">Monaco</option><option value="MN">Mongolia</option><option value="MS">Montserrat</option><option value="MA">Morocco</option><option value="MZ">Mozambique</option><option value="MM">Myanmar</option><option value="NA">Namibia</option><option value="NR">Nauru</option><option value="NP">Nepal</option><option value="NL">Netherlands</option><option value="AN">Netherlands Antilles</option><option value="NC">New Caledonia</option><option value="NZ">New Zealand</option><option value="NI">Nicaragua</option><option value="NE">Niger</option><option value="NG">Nigeria</option><option value="NU">Niue</option><option value="NF">Norfolk Island</option><option value="MP">Northern Mariana Islands</option><option value="NO">Norway</option><option value="OM">Oman</option><option value="PK">Pakistan</option><option value="PW">Palau</option><option value="PA">Panama</option><option value="PG">Papua New Guinea</option><option value="PY">Paraguay</option><option value="PE">Peru</option><option value="PH">Philippines</option><option value="PN">Pitcairn Island</option><option value="PL">Poland</option><option value="PT">Portugal</option><option value="PR">Puerto Rico</option><option value="QA">Qatar</option><option value="RE">Reunion</option><option value="RO">Romania</option><option value="RU">Russian Federation</option><option value="RW">Rwanda</option><option value="KN">Saint Kitts and Nevis</option><option value="LC">Saint Lucia</option><option value="VC">Saint Vincent and the Grenadines</option><option value="WS">Samoa</option><option value="SM">San Marino</option><option value="ST">Sao Tome and Principe</option><option value="SA">Saudi Arabia</option><option value="SN">Senegal</option><option value="CS">Serbia and Montenegro</option><option value="SC">Seychelles</option><option value="SL">Sierra Leone</option><option value="SG">Singapore</option><option value="SK">Slovakia</option><option value="SI">Slovenia</option><option value="SB">Solomon Islands</option><option value="SO">Somalia</option><option value="ES">Spain</option><option value="LK">Sri Lanka</option><option value="SH">St. Helena</option><option value="PM">St. Pierre and Miquelon</option><option value="SD">Sudan</option><option value="SR">Suriname</option><option value="SZ">Swaziland</option><option value="SE">Sweden</option><option value="CH">Switzerland</option><option value="TW">Taiwan</option><option value="TJ">Tajikistan</option><option value="TZ">Tanzania</option><option value="TH">Thailand</option><option value="TG">Togo</option><option value="TK">Tokelau</option><option value="TO">Tonga</option><option value="TT">Trinidad and Tobago</option><option value="TN">Tunisia</option><option value="TM">Turkmenistan</option><option value="TC">Turks and Caicos Islands</option><option value="TV">Tuvalu</option><option value="UG">Uganda</option><option value="UA">Ukraine</option><option value="AE">United Arab Emirates</option><option value="UY">Uruguay</option><option value="UZ">Uzbekistan</option><option value="VU">Vanuatu</option><option value="VE">Venezuela</option><option value="VN">Viet Nam</option><option value="VI">Virgin Islands (U.S.)</option><option value="WF">Wallis and Futuna Islands</option><option value="EH">Western Sahara</option><option value="YE">Yemen</option><option value="ZM">Zambia</option><option value="ZW">Zimbabwe</option>

</select>
			 
			 <input align="bottom" type="image" name="submit" src="wp-content/themes/liveearth_revise/images/join_black.gif" width="61" height="30" style=" vertical-align: middle; text-align:center; "></form></div>
			 
			 </div>
		</div>
	</div>
	</div>

<!--FORM JOIN LIVE EARTH-->
<!--wrap-->
<div id="wrap" style="padding: 10px 0px 40px 0px;">
<div id="midcolumn">	

  <table cellpadding="0" cellspacing="0" border="0" width="777px">
    <tr>
      <td valign="top" width="385px"><style type="text/css">
<!--
.style1 {color: #FFFFFF}
-->
</style>

<div style="padding: 0px 0px 10px 0px; width:395px; border:0px solid #669999; height:inherit; " align="left">

<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=7,0,0,0" width="385" height="244" id="intro" align="middle">
<param name="allowScriptAccess" value="sameDomain" />
<param name="movie" value="wp-content/themes/liveearth_revise/images/gallery7.swf" /><param name="quality" value="high" /><param name="bgcolor" value="#ffffff" /><embed src="wp-content/themes/liveearth_revise/images/gallery7.swf" quality="high" bgcolor="#ffffff" width="385" height="244" name="intro" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
</object>
</div>
<div><a href="friends_of_le.php"><img src="wp-content/themes/liveearth_revise/images/fole_after_head.jpg" width="385" height="30" border="0" /></a></div>

 <div style="background-image:url(wp-content/themes/liveearth_revise/images/friends_of_after_bg.jpg); background-repeat:no-repeat; height:inherit; width:385px; border:0px solid #000000; padding: 0px 0px 0px 0px; font-family:Arial, Helvetica, sans-serif; font-size:10px; height:auto; ">
 
 <div style="padding: 10px 20px 0px 240px; height: 156px; line-height: 16px;">
   <div align="left"><span class="style3 style1"><strong>MORE THAN 10,000 &lsquo;FRIENDS OF LIVE EARTH&rsquo; EVENTS NOW REGISTERED IN 129 COUNTRIES, ALL 50 STATES&hellip;AND GROWING</strong></span><br />
       <strong>[<a href="friends_of_le.php" style="color:#000000">read more</a>]</strong></div>
 </div>
 
 </div>
  
  <div style="padding: 0px 0px 10px 0px; border:0px solid #669999;  width:385px; height:inherit; ">
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr>
      <td width="156" valign="top">
	  
	<div style="padding: 0px 10px 0px 0px; ">  
	  <table width="146" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td><a href="http://liveearth.msn.com/concerts/US" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('press','','wp-content/themes/liveearth_revise/images/after/pressroom_on.jpg',1)"><img src="wp-content/themes/liveearth_revise/images/after/pressroom_off.jpg" alt="Press Room" name="press" border="0"></a></td>
        </tr>
        <tr>
          <td><img src="wp-content/themes/liveearth_revise/images/after/press_top.jpg" width="146" height="10" /></td>
        </tr>
        <tr>
          <td><a href="event.php#press"><img src="wp-content/themes/liveearth_revise/images/after/press_rel.jpg" width="146" height="19" border="0" /></a></td>
        </tr>
        <tr>
          <td><a href="event.php#pressmed"><img src="wp-content/themes/liveearth_revise/images/after/press_mat.jpg" width="146" height="22" border="0" /></a></td>
        </tr>
        <tr>
          <td><img src="wp-content/themes/liveearth_revise/images/after/press_base.jpg" width="146" height="40" /></td>
        </tr>
      </table>
	  
	  </div>
	  
	  
	  </td>
      <td valign="top"><table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td><a href="http://www.themerchandisingshop.co.uk/shop/liveearth/index.php" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('merch','','wp-content/themes/liveearth_revise/images/after/merch_on.jpg',1)"><img src="wp-content/themes/liveearth_revise/images/after/merch_off.jpg" alt="Live Earth Merchandise" name="merch" border="0"></a></td>
        </tr>
        <tr>
          <td><img src="wp-content/themes/liveearth_revise/images/after/merchcontent.jpg" /></td>
        </tr>
      </table></td>
    </tr>
  </table>
</div>
 <div style="padding: 0px 0px 0px 5px; border:0px solid black;" align="left">

<table id="Table_01" width="269" height="13" border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td><div align="left" style="font-family:Arial, Helvetica, sans-serif; font-size:12px; ">language:</div></td>
		<td><a href="international/home_es.html"><img src="wp-content/themes/liveearth_revise/images/es_after.gif" alt="" width="28" height="13" border="0"></a></td>
		<td><a href="international/home_fr.html"><img src="wp-content/themes/liveearth_revise/images/fr_after.gif" alt="" width="27" height="13" border="0"></a></td>
		<td><a href="international/home_de.html"><img src="wp-content/themes/liveearth_revise/images/de_after.gif" alt="" width="28" height="13" border="0"></a></td>
		<td><a href="international/home_pt-BR.html"><img src="wp-content/themes/liveearth_revise/images/br_after.gif" alt="" width="24" height="13" border="0"></a></td>
		<td><a href="international/home_zh-CN.html"><img src="wp-content/themes/liveearth_revise/images/cn_after.gif" alt="" width="27" height="13" border="0"></a></td>
		<td><a href="international/home_jp.html"><img src="wp-content/themes/liveearth_revise/images/jp_after.gif" alt="" width="27" height="13" border="0"></a></td>
		<td><a href="international/home_tr.html"><img src="wp-content/themes/liveearth_revise/images/tur_after.gif" alt="" width="26" height="13" border="0"></a></td>
		<td><a href="international/home_za.html"><img src="wp-content/themes/liveearth_revise/images/sa_after.gif" alt="" width="28" height="13" border="0"></a></td>
	</tr>
</table>
</div> 
  <div style="padding: 0px 0px 0px 5px; border:0px solid black;" align="left">

<table border="0" cellpadding="0" cellspacing="0"><tr><td><div style="font-family:Arial, Helvetica, sans-serif; font-size:11px; padding:10px 0px 30px 0px; height:100px; width:inherit; border:0px solid black; "><a href="privacy.php" style=" font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000;" >privacy policy</a> | <a href="terms.php" style=" font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000;" >terms of use</a> | <a href="contact_us.php" style=" font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000;" >contact us</a> | <a href="green_hosting.php" style=" font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000;" >green hosting</a> | <a href="green_policy.php" style=" font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000;" >green policy</a> | <a href="copyright.php" style=" font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000;" >copyright info</a>
</div></td></tr></table>

 </div> 
  
</div>

       </td>
      <td valign="top" align="left" width="392px"><body onLoad="MM_preloadImages('wp-content/themes/liveearth_revise/images/after/going_green_day_after_on.jpg')"><div style="padding:0px 0px 0px 0px; ">
<script type="text/JavaScript">
<!--
function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}

function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}

function MM_findObj(n, d) { //v4.01
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && d.getElementById) x=d.getElementById(n); return x;
}

function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}
//-->
</script>




<div style="padding: 0px 0px 0px 0px; width:383px; border:0px solid #000000; height:inherit; ">


<div id="flashheader" align="center" style="border:0px solid black; padding: 0px 0px 10px 0px; "><object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=7,0,0,0" width="383" height="120" id="intro" align="middle">
<param name="allowScriptAccess" value="sameDomain" />
<param name="movie" value="wp-content/themes/liveearth_revise/images/day-after2.swf" /><param name="quality" value="high" /><param name="bgcolor" value="#ffffff" /><embed src="wp-content/themes/liveearth_revise/images/day-after2.swf" quality="high" bgcolor="#ffffff" width="383" height="120" name="intro" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
</object>
     
  </div>

<div style="padding: 0px 0px 10px 0px; border:0px solid #669999; height:inherit; ">
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr>
      <td valign="top">
	  
	<div style="padding: 0px 10px 0px 0px; ">  
	  <table width="186" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td><a href="http://www.earthlab.com/liveearth" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('live_impact','','wp-content/themes/liveearth_revise/images/after/live_impact_on.jpg',1)"><img src="wp-content/themes/liveearth_revise/images/after/live_impact_off.jpg" alt="Whats your live impact?" name="live_impact" border="0"></a></td>
        </tr>
        <tr>
          <td><img src="wp-content/themes/liveearth_revise/images/after/impact_text_12.jpg" width="186" height="98"></td>
        </tr>
      </table>
	  
	  </div>
	  
	  
	  </td>
      <td valign="top"><table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td><a href="http://www.climateprotect.org/blog/feed" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('podcast','','wp-content/themes/liveearth_revise/images/after/podcasts_on.jpg',1)"><img src="wp-content/themes/liveearth_revise/images/after/podcasts_off.jpg" alt="Live Earth Podcasts" name="podcast" border="0"></a></td>
        </tr>
        <tr>
          <td><img src="wp-content/themes/liveearth_revise/images/after/podcast_text_11.jpg" width="186" height="112" /></td>
        </tr>
      </table></td>
    </tr>
  </table>
</div>
  
  <div style="background-color:#FFFFFF; padding: 10px 10px 0px 10px; height:inherit; border-left: 1px solid #669999; border-top: 1px solid #669999; border-right:  1px solid #669999;">
	
		<div style="background-color:#E7F0F1; height:inherit; width:359px; border-left: 1px solid #A6C4C5; border-top: 1px solid #A6C4C5; border-right: 1px solid #A6C4C5;">
		
		
		
		 
		
		 
	      <div style="padding: 10px 10px 0px 10px; font-family:Arial, Helvetica, sans-serif; font-size:10px; height:auto;">
	        <a href="news.php#greenblog" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('greenblog','','wp-content/themes/liveearth_revise/images/after/going_green_day_after_on.jpg',1)"><img src="wp-content/themes/liveearth_revise/images/after/going_green_day_after_off.jpg" alt="Going Green" name="greenblog" border="0" style="font-family: Arial, Helvetica, sans-serif; padding:0px 0px 4px 0px;></a>
	      <div style="font-family: Arial, Helvetica, sans-serif; padding:4px 0px 4px 0px;><div id="greentitle" style="font-family: Arial, Helvetica, sans-serif; padding:4px 0px 0px 0px; "><a href="http://www.liveearth.org/?p=82" rel="bookmark" title="Permanent Link to Looking For Eco-friendly Ways Travel To Live Earth?" style="color:#CC0000; font-family: Arial, Helvetica, sans-serif;">Looking For Eco-friendly Ways Travel To Live Earth?</a></div><div id="greencontent" style=" font-family: Arial, Helvetica, sans-serif; line-height:1.6; "><p>Live Earth is committed to producing the most eco-friendly series of concerts possible. To do this, we are taking important steps to minimize each concert&#8217;s carbon footprint &#8212; from powering the stage with clean energy, transporting artists to the venue in low-emission, alternative fuel vehicles, and encouraging ticket holders to take advantage of their public transportation options.</p>
<a href="http://www.liveearth.org/?p=82" rel="bookmark" style=" font-family:Arial, Helvetica, sans-serif; font-size: 10px; color:#CC0000;" title="Permanent Link to Looking For Eco-friendly Ways Travel To Live Earth?"> [more]</a><div id="greentitle" style="font-family: Arial, Helvetica, sans-serif; padding:4px 0px 0px 0px; "><a href="http://www.liveearth.org/?p=192" rel="bookmark" title="Permanent Link to John Mayer Blogs In!" style="color:#CC0000; font-family: Arial, Helvetica, sans-serif;">John Mayer Blogs In!</a></div><div id="greencontent" style=" font-family: Arial, Helvetica, sans-serif; line-height:1.6; "><p>I woke up this morning with hope. Excitement, even. Live Earth is taking place in 48 hours, and I&#8217;m starting to feel the first ripples of what could become a revolution.</p>
<a href="http://www.liveearth.org/?p=192" rel="bookmark" style=" font-family:Arial, Helvetica, sans-serif; font-size: 10px; color:#CC0000;" title="Permanent Link to John Mayer Blogs In!"> [more]</a><br/><br/></div>
</div>
		 	 
		
  </div>		
  </div>
  
  
  
</div>
</div><div>
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td colspan="4"><img src="wp-content/themes/liveearth_revise/images/after/day-after_base_top.gif" width="383" height="12" /></td>
        </tr>
      <tr>
        <td><a href="http://www.allianceforclimateprotection.org/"><img src="wp-content/themes/liveearth_revise/images/after/day-after_base_alliancelogo.gif" width="83" height="53" border="0" /></a></td>
        <td><a href="http://www.liveearth.org/who_we_are.php"><img src="wp-content/themes/liveearth_revise/images/after/day-after_base_soslogo.gif" width="83" height="53" border="0" /></a></td>
        <td><img src="wp-content/themes/liveearth_revise/images/after/day-after_base_arrow.gif" width="123" height="53" /></td>
        <td><a href="http://www.liveearth.org/green_hosting.php"><img src="wp-content/themes/liveearth_revise/images/after/day-after_base_greenhosting.gif" width="94" height="53" border="0" /></a></td>
      </tr>
    </table>
  </div>      </td>
    </tr>
  </table>
</div>
 
</div>
<!--wrap-->

<!-- Gorgeous design by Michael Heilemann - http://binarybonsai.com/kubrick/ -->



</body>
</html>

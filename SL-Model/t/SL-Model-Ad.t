#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 30;

BEGIN {
    use_ok('SL::Model::Ad');
}
my $HTML = <<HTML;
<html>
   <head>
     <title>sup maing</title>
     <link rel="stylesheet" href="/igotstyle.css" type="text/css" />
     <script type="text/javascript">
       do some scripty shit
     </script>
   </head>
   <body>
     <div id="originalstyle">
       <p>Hizzah!</p>
     </div>
   </body>
 </html>
HTML

my $content = do { local $/ = undef; <DATA> };

my $ad       = 'Hoo haa biz bang';
my $css_link = 'http://www.redhotpenguin.com/css/sl.css';
my $template = 'text_ad.tmpl';

use Time::HiRes qw(tv_interval gettimeofday);

# bring in dbix::class to save us some typing
use SL::Model::App;

my $start = [gettimeofday];
ok(SL::Model::Ad::container( \$css_link, \$content, \$ad ));
my $interval = tv_interval( $start, [gettimeofday] );

like( $content, qr/$ad/,       'Yahoo ad inserted ok' );
like( $content, qr/$css_link/, 'css link inserted ok' );
diag("Time was $interval");
cmp_ok( $interval, '<', 0.010,
    'Yahoo Ad inserted in less than 10 milliseconds' );

$start = [gettimeofday];
SL::Model::Ad::container( \$css_link, \$HTML, \$ad );
$interval = tv_interval( $start, [gettimeofday] );

like( $HTML, qr/$ad/,       'ad inserted ok' );
like( $HTML, qr/$css_link/, 'css link inserted ok' );
diag("Time was $interval");
cmp_ok( $interval, '<', 0.010,
    'HTML Ad inserted in less than 10 milliseconds' );
cmp_ok( $interval, '<', 0.005, 'HTML Ad inserted in less than 5 milliseconds' );
cmp_ok( $interval, '<', 0.002, 'HTML Ad inserted in less than 2 milliseconds' );

diag('check the default ad serving logic');

diag('put a test router in place');
use SL::Model::Proxy::Router::Location;
use SL::Model;
my $ip      = '127.0.0.1';
my $macaddr = '00:02:B3:4D:BD:87';

# get rid of routers and locations
my $dbh = SL::Model->connect;
$dbh->do("DELETE FROM location WHERE ip = '$ip'")         or die $DBI::errstr;
$dbh->do("DELETE FROM router WHERE macaddr = '$macaddr'") or die $DBI::errstr;
$dbh->do("DELETE FROM ad_group where ad_group_id > 1")    or die $DBI::errstr;

# get a registered router
my $router;
unless (
    $router = SL::Model::Proxy::Router::Location->get_registered(
        { ip => $ip, macaddr => $macaddr }
    )
  )
{
    $router =
      SL::Model::Proxy::Router::Location->register(
        { ip => $ip, macaddr => $macaddr } )
      or die 'could not register';
}

##############################

diag('make sure that the default works');

# make sure we have a default ad
my ($default_adgroup) = SL::Model::App->resultset('AdGroup')->search({
        is_default => 't' });
unless ($default_adgroup) {
  $default_adgroup = SL::Model::App->resultset('AdGroup')->find_or_create({
       name => 'default_test',
       is_default => 't',});
  my $test_ad = SL::Model::App->resultset('Ad')->find_or_create({ 
        active => 't',
        ad_group_id => $default_adgroup->ad_group_id });
  my $ad_sl = SL::Model::App->resultset('AdSl')->create({
         ad_id => $test_ad->ad_id,
        text => 'default test ad',
        uri => 'http://www.redhotpenguin.com/', });
}

my $test_ad = SL::Model::Ad->_sl_default($ip);

# evil evil copied from Ad.pm
use constant AD_ID_IDX       => 0;
use constant TEXT_IDX        => 1;
use constant MD5_IDX         => 2;
use constant URI_IDX         => 3;
use constant TEMPLATE_IDX    => 4;
use constant CSS_URL_IDX     => 5;
use constant IMAGE_HREF_IDX  => 6;
use constant LINK_HREF_IDX   => 7;

like( $test_ad->[TEXT_IDX], qr/\w+/, 'text present' );
cmp_ok( $test_ad->[CSS_URL_IDX], 'eq', $css_link );
cmp_ok( $test_ad->[TEMPLATE_IDX], 'eq', $template );

################################

diag('which means random better work');
my ( $ad_id, $ad_content_ref, $css_url_ref ) = SL::Model::Ad->random($ip);
like( $ad_id, qr/^\d+$/, 'ad_id is a number' );
cmp_ok( ref $ad_content_ref, 'eq', 'SCALAR', 'ad_content_ref isa scalar' );
cmp_ok( $$css_url_ref, 'eq', $css_link, 'css default link ok' );

#############################

diag('check the no_default feature');
my $sth =
  $dbh->prepare("update location set default_ok = 'f' where ip = '$ip'");
$sth->execute;
$test_ad = SL::Model::Ad->_sl_default($ip);
ok( !exists $test_ad->[TEXT_IDX], 'text not present' );

#################################

diag('test the router sticky feature');

# make a new ad group
my $css      = 'http://example.com/sl.css';
my $name     = 'testadgroup';
my $ad_group = SL::Model::App->resultset('AdGroup')->create(
    {
        name     => $name,
        css_url  => $css,
        template => $template,
    }
);
print STDERR "created ad_group_id " . $ad_group->ad_group_id . "\n";

# make an ad (cover your eyes unless you want to witness pain)
$ad = SL::Model::App->resultset('Ad')->create( { 
    active => 't',
    ad_group_id => $ad_group->ad_group_id,
 } );

my $reg =
  SL::Model::App->resultset('Reg')->new( { email => 'flimflam@foo.com' } )
  ->insert->update;

my $test_text = 'testzimzimfoobar';
my $sl_ad     = SL::Model::App->resultset('AdSl')->create(
    {
        ad_id  => $ad->ad_id,
        text   => $test_text,
        uri    => 'http://foo.com',
        reg_id => $reg->reg_id,
    }
);
print STDERR "created sl_ad id " . $sl_ad->ad_sl_id . "\n";

# put it in the ad group for this router
print STDERR "router is " . $router->[0]->[0] . "\n";
my $router__ad_group = SL::Model::App->resultset('RouterAdGroup')->create(
    {
        router_id   => $router->[0]->[0],
        ad_group_id => $ad_group->ad_group_id,
    }
);

################################

# Now get the ad
my $limit = 0.015;
$start = [gettimeofday];
$test_ad = SL::Model::Ad->_sl_router($ip);
$interval = tv_interval( $start, [gettimeofday] );
cmp_ok( $interval, '<', $limit, "_sl_router() took $interval seconds" );
#use Data::Dumper;
#print STDERR "obj is " . Dumper($test_ad) . "\n";
cmp_ok( $test_ad->[TEXT_IDX],   'eq', $test_text, 'ad text is what we put in' );
cmp_ok( $test_ad->[CSS_URL_IDX],  'eq', $css,       'css oky doky' );
cmp_ok( $test_ad->[TEMPLATE_IDX], 'eq', $template, 'template came through ok' );

###############################

diag('test out location override');
my $location__ad_group = SL::Model::App->resultset('LocationAdGroup')->new(
    {
        location_id => $router->[0]->[1],
        ad_group_id => $ad_group->ad_group_id
    }
)->insert->update;

# change the text
$test_text = 'flooberflobber';
$sl_ad->text($test_text);
$sl_ad->update;
$start    = [gettimeofday];
$test_ad  = SL::Model::Ad->_sl_location($ip);
$interval = tv_interval( $start, [gettimeofday] );
$limit = 0.01;
cmp_ok( $interval, '<', $limit, "_sl_location took $interval seconds" );
cmp_ok( $test_ad->[TEXT_IDX], 'eq', $test_text, 'ad text is what we put in' );
cmp_ok( $test_ad->[TEMPLATE_IDX], 'eq', $template );
cmp_ok( $test_ad->[CSS_URL_IDX],  'eq', $css );

############################

diag('random should return the location default');
$test_text = 'bimbamboom';
$sl_ad->text($test_text);
$sl_ad->update;
$start = [gettimeofday];
( $ad_id, $ad_content_ref, $css_url_ref ) = SL::Model::Ad->random($ip);
$interval = tv_interval( $start, [gettimeofday] );
cmp_ok( $interval, '<', $limit, "random() took $interval seconds" );
is( $ad_id, $ad->ad_id, 'ad_id is a number' );
cmp_ok( ref $ad_content_ref, 'eq', 'SCALAR', 'ad_content_ref isa scalar' );
cmp_ok( $$css_url_ref, 'eq', $css, 'css url ok' );
like( $$ad_content_ref, qr/$test_text/, 'ad text found' );

1;

__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<script type="text/javascript">
var now=new Date,t1=t2=t3=t4=t5=t6=t7=t8=t9=t10=t11=t12=0,cc=\'\',ylp=\'\';t1=now.getTime();
</script>
<script language=javascript><!--
lck=\'\',sss=1179009477,ylp=\'p.gif?t=1179009477&_ylp=A9GDJJbFQUZGdmoBeWf1cSkA\',_lcs=\'\',crumb=\'d663a3ce907759646dc37907352e9ffc,1179009477,2kjHeBfFxXm\';
--></script><script language="javascript" type="text/javascript">
_lcs = decodeURIComponent(_lcs);
var YAHOO=window.YAHOO||{};YAHOO.namespace=function(ns){if(!ns||!ns.length){return null;}var _2=ns.split(".");var _3=YAHOO;for(var i=(_2[0]=="YAHOO")?1:0;i<_2.length;++i){_3[_2[i]]=_3[_2[i]]||{};_3=_3[_2[i]];}return _3;};YAHOO.log=function(_5,_6,_7){var l=YAHOO.widget.Logger;if(l&&l.log){return l.log(_5,_6,_7);}else{return false;}};YAHOO.extend=function(_9,_10){var f=function(){};f.prototype=_10.prototype;_9.prototype=new f();_9.prototype.constructor=_9;_9.superclass=_10.prototype;if(_10.prototype.constructor==Object.prototype.constructor){_10.prototype.constructor=_10;}};YAHOO.namespace("util");YAHOO.namespace("widget");YAHOO.namespace("example");
YAHOO.namespace("Fd");
YAHOO.namespace("Fp");
YAHOO.Fp.nScreenWidth = (screen && typeof(screen.availWidth)==\'number\') ? screen.availWidth : false;
YAHOO.Fp.bNarrow = (YAHOO.Fp.nScreenWidth ? (YAHOO.Fp.nScreenWidth<1024 ? 1 : 0) : -1);
YAHOO.Fp.d = document;
YAHOO.Fp.$ = function(id){
return (typeof(id)==\'string\') ? YAHOO.Fp.d.getElementById(id) : false;
};
YAHOO.Fp.beacon = function(sUrl, clearUlt, useYlh){
if(sUrl.indexOf(\'http\')<0 && YAHOO.Fp._ylh!=\'\'){
if(clearUlt){
YAHOO.cookie.set("D","","-1","/","yahoo.com");
}
sUrl=((clearUlt||useYlh)&&YLH)? \'/\'+YLH+\'/\'+ sUrl : sUrl;
}
var oImage = new Image();
oImage.src = sUrl+\'?t=\' + new Date().getTime();
setTimeout(function(){oImage = null;}, 1e4);
};
YAHOO.Fp.becon=YAHOO.Fp.beacon;
YAHOO.cookie = {
get : function(n){
var v = \'\',
c = \' \' + document.cookie + \';\',
s = c.indexOf((\' \' + n + \'=\'));
if (s >= 0) {
s += n.length + 2;
v = unescape(c.substring(s, c.indexOf(\';\', s)));
}
return v;
},
set : function(n,v){
var a=arguments,al=a.length;
document.cookie = n + "=" + v +
((al>2&&a[2]!="") ? ";expires=" + (typeof(a[2])=="object" ? a[2] : (new Date(a[2] * 1000)).toGMTString()) : "") +
";path="    + ((al>3&&a[3]!="") ? a[3] : "/") +
";domain="  + ((al>4&&a[4]!="") ? a[4] : "www.yahoo.com");
},
checksub : function(sCookie,s){
var aParts = sCookie.split(\'&\'),nParts = aParts.length,aKeyVal;
if (nParts==1) {
return sCookie.indexOf(s);
} else {
for(var i=0; i<nParts; i++){
aKeyVal = aParts[i].split(\'=\');
if(aKeyVal[0]==s){
return i;
}
}
}
return -1;
},
getsub : function(n,s){
var sCookie = this.get(n);
var nExists = this.checksub(sCookie,s);
if (nExists>-1) {
return sCookie.split(\'&\')[nExists].split(\'=\')[1];
} else if (sCookie.indexOf(s)>0) {
return sCookie.split(\'=\')[1];
}
return \'\';
},
setsub : function(n,s,v){
var sCookie = this.get(n),a=arguments,al=a.length;
var aParts = sCookie.split(\'&\');
var nExists = this.checksub(sCookie,s);
if (sCookie==\'\') {
sNewVal=(s+\'=\'+v).toString();
} else {
if(nExists==-1){nExists=aParts.length;}
aParts[nExists]=s+\'=\'+v;
sNewVal = aParts.join(\'&\');
}
return this.set(n,sNewVal,(a[3]||\'\'),(a[4]||\'/\'),(a[5]||\'www.yahoo.com\'));
}
}
YAHOO.Fp.changePageSize = function(bCheck){
if((location.search.indexOf(\'rs=\')!=1 && location.pathname.indexOf(\'cgi\')<0) || !bCheck){
if(bCheck){
var bcn=new Image;
bcn.src=\'http://www.yahoo.com/\'+(ylp?ylp:\'p.gif\')+\'&igpv=1\';
}
location.replace(\'http://\'+location.hostname+location.pathname+(bCheck ? \'?rs=1\' : \'\'));
}
}
YAHOO.Fp.sPhpFsCookie="";YAHOO.Fp.sFsCookie = YAHOO.cookie.get("FPS");
if(YAHOO.Fp.sFsCookie.indexOf("t")!=0 && YAHOO.Fp.bNarrow!=-1){
YAHOO.cookie.set("FPS",(YAHOO.Fp.bNarrow ? "ds" : "dl"),400*3600000);
if(YAHOO.Fp.bNarrow==1){
YAHOO.Fp.changePageSize(1);
}
}else if(YAHOO.Fp.sPhpFsCookie != YAHOO.Fp.sFsCookie){
YAHOO.Fp.changePageSize(1);
}
YAHOO.Fp.togglePageSize = function(sSize){
YAHOO.cookie.set("FPS",sSize,400*3600000);
YAHOO.Fp.changePageSize(0);
}
YAHOO.Fp.nPageSize = 0;
YAHOO.Fp._ie=YAHOO.Fp._ie7=YAHOO.Fp._ie55=0;
YAHOO.Fp._ff=1;
YAHOO.Fp._ffv=parseFloat("1.5.0",10);
YAHOO.Fp._ns=0;
YAHOO.Fp._nsv=parseFloat("0",10);
YAHOO.Fp._sf=0;
YAHOO.Fp._sfv=parseFloat("0",10);
YAHOO.Fp._op=0;
YAHOO.Fp._mac=0;
YAHOO.Fp._hostname=location.hostname;
YAHOO.Fp._ylh = typeof(YLH)!=\'undefined\'?YLH+\'/\':\'\';
</script>
<!--[if lt IE 6]><script language="javascript" type="text/javascript">YAHOO.Fp._ie55=1;</script><![endif]-->
<!--[if IE]><script language="javascript" type="text/javascript">YAHOO.Fp._ie=1;</script><![endif]-->
<!--[if IE 7]><script language="javascript" type="text/javascript">YAHOO.Fp._ie7=1;</script><![endif]-->
<script type="text/javascript">
var b,dt,l=\'\',n=\'0\',r,s,y;
y=\' \'+document.cookie+\';\';
if ((b=y.indexOf(\' Y=v\'))>=0) {
y=y.substring(b,y.indexOf(\';\',b))+\'&\';
if ((b=y.indexOf(\'l=\'))>=0) {
l=y.substring(b+2,y.indexOf(\'&\',b));
if((b=y.indexOf(\'n=\'))>=0)n=y.substring(b+2,y.indexOf(\'&\',b));
}
}
dt=new Date();
s=Math.round(dt.getTime()/1000);
r=Math.round(parseInt(n,32)%1021);
if (lck!=l) {
document.write(\'<meta http-equiv="Expires" content="-1">\');
if (location.search.indexOf(\'r\'+r+\'=\')!=1) {
location.replace(\'http://\'+location.hostname+location.pathname+\'?r\'+r+\'=\'+s);
}
}
var ver="501";
var frcode="yfp-t-501";function err(a,b,c) {
var img=new Image;
img.src=\'http://srd.yahoo.com/hp5-v\'+ver+\'-err/\'+escape(a)+\',\'+escape(b)+\',\'+escape(c)+\'/*1\';
return true;
}
window.onerror=err;
window.onbeforeunload=function(){
var img=new Image;
now=new Date;
t6=now.getTime();
img.src=\'http://www.yahoo.com/\'+(ylp?ylp:\'p.gif?t=0\')+cc+\'&tid=\'+ver+\'&ni=\'+document.images.length+\'&sss=\'+sss+\'&t1=\'+t1+\'&d1=\'+(t2-t1)+\'&d2=\'+(t3-t1)+\'&d3=\'+(t4-t1)+\'&d4=\'+(t5-t1)+\'&d5=\'+(t6-t1) +\'&d6=\'+(t7-t1)+\'&d7=\'+(t8-t1)+\'&d8=\'+(t9-t1)+\'&d9=\'+(t10-t1)+\'&d10=\'+(t11-t1)+\'&d11=\'+(t12-t1);
}
</script>
<title>Yahoo!</title>
<meta http-equiv="PICS-Label" content=\'(PICS-1.1 "http://www.icra.org/ratingsv02.html" l r (cz 1 lz 1 nz 1 oz 1 vz 1) gen true for "http://www.yahoo.com" r (cz 1 lz 1 nz 1 oz 1 vz 1) "http://www.rsac.org/ratingsv01.html" l r (n 0 s 0 v 0 l 0) gen true for "http://www.yahoo.com" r (n 0 s 0 v 0 l 0))\'>
<script language=javascript>var YLH=\'_ylh=X3oDMTFkNG1mZnB0BF9TAzI3MTYxNDkEcGlkAzExNzkwMDc1MzMEdGVzdAMwBHRtcGwDaW5kZXgtbA--\'; var PID=\'1179007533\'; document.write(\'<base href="http://www.yahoo.com/" target=_top>\');</script> <noscript><base href="http://www.yahoo.com/_ylh=X3oDMTFkNG1mZnB0BF9TAzI3MTYxNDkEcGlkAzExNzkwMDc1MzMEdGVzdAMwBHRtcGwDaW5kZXgtbA--/" target=_top></noscript>
<script type="text/javascript">
YAHOO.Fp.use_two_col=0;
YAHOO.Fp.use_bt5=0;
YAHOO.Fp.use_search_bt=0;
YAHOO.Fp.use_editable_trough=0;
YAHOO.Fp.use_static_pa=0;
</script>
<style type="text/css">
body{font:13px arial,helvetica,clean,sans-serif;*font-size:small;*font:x-small;}
table{font-size:inherit;font:100%;}
select,input,textarea{font:99% arial,helvetica,clean,sans-serif;}
pre,code{font:115% monospace;*font-size:100%;}
body *{line-height:1.22em;}

.more, .bullet, .audio, .video, .slideshow, .search, .minimantle li, #minimantle li, #localnewsct #newstop li, a#editpage, a#editpage.on,#vsearchtabs dl dt a,#sboxfooter a.yans{
  background-image:url(http://us.js2.yimg.com/us.js.yimg.com/i/ww/sp/icons_1.5.gif);
  background-repeat:no-repeat;
}
.btn-more-2, .hd li.on em, div.hd li.sparkle a, .hd, #mastheadbd .top, #mastheadbd, #doors li a, #today .ft li.on a{
  background-image:url(http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/grd-1px_1.1.gif);
  background-repeat:repeat-x;
}

div.minimantle, #minimantle, #sizetoggle, #trough ul, #pa{
  background-image:url(http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/grd-4px_1.1.gif);
  background-repeat:repeat-x;
}
.md{
  background:#fff;
  border:1px solid #b0bec7;
}
#left .md{
  border:1px solid #91a7b4;
  border-color:#b0bdc6 #91a7b4 #91a7b4 #b0bdc6;
}
.hd{
  color:#18397c;
  background-color:#fff;
  background-position:bottom left;
  border:1px solid #b0bec7;
  border-bottom:1px solid #93a6b4;
}
.hd li a{
  color:#18397c;
}
.hd li .pipe{
  background:#788a98;
  border-right:1px solid #fff;
}
.hd li.on em{
  border:1px solid #91a7b4;
  border-top-color:#778a98;
  border-bottom:1px solid #fff;
  background-color:#fff;
  background-position:0 -178px;
}
.hd li.first em{
  border-left:none;
}
.hd li.on a{
  color:#c63;
}
div.hd li.sparkle em{
  border:1px solid #768c9a;
  border-bottom:1px solid #93a6b4;
}
div.hd li.sparkle a{
  background-color:#b5cdd9;
  background-position:0 -530px;
  border:1px solid #fff;
}

  .minimantle,#sizetoggle{
    border:1px solid #9CAEBA;
    border-width:0 1px 1px 0;
    background-color:#91A7B4;
    background-position:0 -2041px;
  }
  .minimantle .md-sub, #sizetoggle .bd{
    border:1px solid #fff;
  }
  #sizetoggle .bd{
    border:1px solid #dde4ea;
    border-color:#afbdc6 #556b78 #556b78 #afbdc6;
  }.minimantle h2 a, #minimantle h2 a{
  color:#333;
}
.minimantle li, #minimantle li{
  background-position:-8px 1px;
  *background-position:-8px 2px;
}

#mastheadbd .top{
  background-color:#e2eaed;
}
#mastheadbd{
  background-color:#eef3f6;
  background-position:0 -30px;
  border:1px solid #dbe2e8;
  border-width:0 1px;
  border-bottom:1px solid #cad5db;
}

#searchIE{filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src="http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/search_1.1.png", sizingMethod="scale");}

#doors li{background:#dde6eb}
#doors li strong{
  border:1px solid #dee6e9;border-color:#dee6e9 #586b7a #586b7a #dee6e9}
#doors li a{
  border:1px solid #fff;
  background-color:#fff;
  background-position:bottom left;
}

.trough-promo .first{
  border-color:#B0BEC7;
}

.tpromo2 .hd,#new-on{
	border-color:#aec0ce #3d5360 #3d5360 #aec0ce;
}
  #trough{
    background:#91a7b4;
  }
  #trough .bd{
    border:1px solid #fff;
    border-width:0 1px 1px 0;
  }#trough span{    background:#f8f9fb;
    border-top:1px solid #91a7b5;
  }
  #trough ul{
    background-color:#f8f9fc;
  }
  span#edityservicescx{
    background:#ebeff2 url(http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/grd-1px_1.1.gif) 0 -757px repeat-x;
    border-bottom:1px solid #000;
    border-color:#b0bdc6 #91a7b4 #91a7b4 #b0bdc6;
  }
  #edityservices{
    background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/icons_1.1.gif) 0 -257px repeat-x;
  }a#editpage{
  background-position:100% -307px;
}
a#editpage.on{
  background-position:100% -361px;
}

#today .ft li.on{
  border:1px solid #afbec5;
  border-color:#afbec5 #afbdc5 #afbdc5 #b0bfc6;
}
#today .ft li.on a{
  color:#666;
  background-color:#fcfcfc;
  background-position:0 -296px;
}
#en-details{
  background:#F1F5F6;
  border:1px solid #b0bec7;
}
.mod-drop-down{
  background:#F1F5F6;
  border:1px solid #b0bec7;
  border-top:none;
}
#trough .borderbottom{
  border-bottom:1px solid #b0bec7;
  padding-bottom:5px;
}
#newsft{
  background:#F1F5F6;
  border-top:1px solid #b0bec7;
}
#newsbottom{
  border-top:1px solid #fff;
}

#marketplace hr{
  border-top:1px solid #dce3e9;
  color:#dce3e9;
}

#pa{
  border-color:#afbdc6 #556b78 #556b78 #afbdc6;
  background-position:0 -2700px;
}
#pabd{
  border:1px solid #c9d7e2;
  border-width:0 1px 1px 0;
}#patabs ul.patabs li div{
  background:#9dadc4;
}
#patabs ul.patabs li h4{
  background:#6b7fa0;
}
#patabs ul.patabs li a{
  border:1px solid #c9d6de;
  border-color:#aec0ce #3d5360 #3d5360 #aec0ce;
  background-color:#fff;
}
#patabs ul.patabs li.tab-on a, #patabs .papreviewdiv{
  border-color:#566c7a #c2d0d9 #c2d0d9 #c2d0d9;
  border-width:1px 1px 0 1px;
  background:#fff url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/pa-preview-shadow.gif) repeat-x;
}
#patabs ul.patabs li.tab-on div{
  background:#fff;
}
#patabs ul.patabs li.first a{
  border-left-width:1px;
}
#patabs ul.patabs li.last a{
  border-right-width:1px;
}
#patabs .papreviewdiv{
  border:1px solid #c4cfd5;
  border-top-color:#566c7a;
}

#footer{
  color:#16387c;
}
#footer li{
  border-left:1px solid #b0bec7;
}
#copyright{
  color:#666;
}
.feedback {
  border-right:1px solid #b0bec7;
}body{
text-align:center;
color:#333;
direction:ltr;
}
body,h1,h2,h3,h4,h5,h6,ul,ol,li,dl,dt,dd,p,form,fieldset,legend,input,img{margin:0;padding:0;}
img,fieldset{border:0;}
ul,ol{list-style:none;}
legend{height:0;font-size:0;}
label{cursor:pointer;cursor:hand;}
cite{font:normal 85% verdana;}
em{font-style:normal;}
cite span{font-weight:bold;}
a,#news .bd .btn-more a:visited{color:#16387c;}
a:link,a:visited{text-decoration:none;}
#today .bd a:visited,#news .bd a:visited{color:#69789C;}
a:hover{text-decoration:underline;}
.on a:hover{text-decoration:none;}
.a11y,legend{position:absolute;left:-5000px;width:100px;}
u{
text-decoration:none;
}
ol:after, ul:after,
.md:after, .md-sub:after, .hd:after, .bd:after, .ft:after, .fixfloat:after, .fbody:after,
#colcx:after, #rightcx:after, #eyebrow:after, #masthead:after, #search:after, #tabs:after,  #doors:after, #patabs:after, #patop:after, #trough-overlay-bd div:after, #newsft:after, #newsbottom:after{
content:".";
display:block;
font-size:0px;
line-height:0px;
height:0;
clear:both;
visibility:hidden;
}
ol, ul, dl, .md, .md-sub, .hd, .bd, .ft, .fixfloat, .fbody, #colcx, #rightcx, #eyebrow, #masthead, #search, #tabs, #sbox, #doors, #patabs, #patop, #newsft, #newsbottom{zoom:1;_height:1px;}
.iemw{
display:none;
width:950px;
font-size:0px;
line-height:0px;
height:0px;
*display:block;
}
.submit,.s2{
padding:2px 5px;
font:bold 77% verdana;
overflow:visible;
color:#000;
background:#ddd;
cursor:pointer;
cursor:hand;
}
.inputtext{
border:1px solid #f0f0f0;
border-color:#7c7c7c #cecece #c3c3c3 #7c7c7c;
background:#fff url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/sbox-bg.gif) no-repeat;
}
.more, .bullet, .audio, .video, .slideshow, .search, .minimantle li, #localnewsct #newstop li{
font:normal 77% verdana;
padding:2px 0 2px 18px;
}
#page .more{background:none;padding:2px 0 2px 5px;font-weight:bold;}
.plain{padding:2px 0;}
.bullet{background-position:-7px 1px;padding-left:9px;}
.video{background-position:-3px -50px;}
.audio{background-position:-3px -100px;}
.slideshow{background-position:-3px -151px;}
.search{background-position:-3px -200px;}
.btn-more{
position:absolute;
bottom:5px;
right:10px;
font:bold 77% verdana;
white-space:nowrap;
}
.btn-more-2{
padding:1px 10px 2px;
*padding:1px 5px 0;
font:bold 100% arial;
color:#000;
white-space:nowrap;
border:1px solid #999b9a;
background-color:#ce9200;
background-position:0 -450px;
}
.alert{
font:normal 77% verdana;
color:#f00;
}
a.norgie{
float:left;
width:19px;
height:20px;
margin:auto;
}
a.mover{
float:right;
margin:0 4px;
width:19px;
height:20px;
display:none;
}
.bd span,.ft span{display:none;}
.bd .current,.ft .current,.current span{display:block;}
.md{
position:relative;
margin:0 0 10px;
}
.hd{
position:relative;
margin:-1px -1px 0;
}
.hd h2{
position:relative;
font:bold 100% arial;
padding:1px 11px;
border-bottom:1px solid #fff;
}
.tabs{
padding:0;
}
.tabs .hd h2{
left:25px;
top:-2px;
}
.bd{
padding:5px 10px 10px;
}
.ft{
padding:9px;
}
.ad{
margin:0 0 10px;
}
.hide .bd,.hide .ft{display:none;}
.hd ul{
position:relative;
width:100%;
border-bottom:1px solid #fff;
}
.hd ul li{
position:relative;
float:left;
}
.hd li.last{
float:right;
_margin-right:-2px;
}
.hd li em{
position:relative;
display:block;
width:99%;
_width:99.5%;
min-height:14px;
_height:14px;
padding:2px 0 0px;
margin-right:-1px;
border-right:0;
}
.hd li a{
display:block;
font:normal 92% arial;
outline:none;
text-align:center;
white-space:nowrap;
z-index:50;
padding:1px;
margin-top:-1px;
}
.hd li.on{
z-index:60;
margin-bottom:-1px;
}
.hd li .pipe{
display:block;
position:absolute;
top:1px;
right:-1px;
height:1.15em;
width:1px;
_width:2px;
}
.hd li.on .pipe{
visibility:hidden;
}
.hd li.on em{
padding-bottom:1px;
_padding-bottom:2px;
margin:-1px 0 -1px;
*margin-bottom:-2px;
}
.hd li.on a{
font-weight:bold;
z-index:60;
border:0;
padding:1px;
}
.hd li.sparkle{
z-index:70;
}
div.hd li.sparkle em{
left:-1px;
padding:1px 0 0;
margin:-1px -1px -2px 0;
}
div.hd li.sparkle a{
font-weight:bold;
padding:1px;
z-index:70;
}
.hd li.off .pipe,.hd li.on .pipe,.hd li.last .pipe,.hd li.sparkle .pipe{visibility:hidden;}
#news .hd ul li{width:25%;*width:24.9%;}
#today .hd ul li{width:25%;*width:24.9%;}
.md-sub h3{
font-size:100%;
}
#client{
position:absolute;
visibility:hidden;
}
#page{
margin:0 auto;
border-bottom:1px solid transparent;
*border:0;
position:relative;
min-width:950px;
width:70em;
*width:71.3em;
text-align:left;
}
#colcx{
position:relative;
min-width:950px;
}
#left{
float:left;
width:15.79%;min-width:150px;
margin:0 0 10px 0;
}
#rightcx{
float:right;
width:84%;*width:84.21%;min-width:800px;
*margin-left:-200px;
}
.colpadding{
margin-left:10px;
}
#middle{
float:left;
position:relative;
z-index:10;
float:left;
width:55%;
min-width:440px;
*width:54.9%;
}
#middle .md{
min-width:340px;
}
#right{
float:left;
position:relative;
width:45%;
min-width:360px;
*margin-right:-200px;
}
#masthead{
min-width:950px;
*margin-right:1px;
}
#loading{
display:none;
position:absolute;
top:2px;
right:2px;
z-index:999;
}
.minimantle{
position:relative;
margin:10px 0;
}
#smallbiz.md-sub{
border-bottom:1px solid #fff;
}
.minimantle h2{
font:bold 100% arial;
margin-bottom:4px;
}
.minimantle ul{
padding:5px 0 5px 10px;
}
.minimantle li{
font:bold 85% verdana;
padding:1px 0 1px 8px;
*padding:0 0 0 8px;
voice-family:"\\"}\\"";
voice-family:inherit;
property:value;
*padding:0 0 0 8px;
}
.minimantle li a{
margin-left:-15px;
voice-family:"\\"}\\"";
voice-family:inherit;
property:value;
margin-left:0;
}
.minimantle .hd {margin:-2px;}
.minimantle .hd h2{margin:0;}
.minimantle .hd a{color:#16387C !important;}
#mantlecx{
margin:0 0 10px;
}
#xyz{
width:0;
height:0;
}
#eyebrow{
position:relative;
margin:0 auto;
font:normal 77% verdana;
padding:3px 10px;
}
#eyebrow li{
float:left;
}
#eyebrow ul,#eyebrow ul a{
float:left;
}
.eyebrowborder{
border-right:1px solid #B0BEC7;
padding-right:5px;
margin-right:5px;
}
#ffhpcx{
position:absolute;
}
#headline{
float:right;
right:0;
}
#toolbar{display:none;}
#eyebrow #shpd a{text-decoration:none; display:inline; float:none;}
.shdw{-moz-border-radius:4px;background:#ccc;z-index:1000;position:absolute;top:2em;left:1.5em;}
#shpd .bd{border:1px solid #4333BC;-moz-border-radius:4px;width:360px;background:#fff;position:relative;top:-2px;left:-2px;z-index:1001;color:#333;}
#pnt{position:absolute;top:-6px;left:30%;width:11px;height:6px;font-size:0px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/shpa1.gif);}
#shpd .shp{width:40px;height:37px;font-size:0px;line-height:0px;top:10px;left:10px;display:block;position:absolute;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/ydrag.gif);}
.shp strong{display:none;}
#shpd ol{margin:9px 9px 9px 60px;padding:0 0 0 1.5em;list-style:decimal;}
#shpd li{padding:0;}
#shpd p{border-top:1px solid #ccc; font-family:verdana !important; margin:0 9px 9px;text-align:center;}
#masthead{
z-index:90;
position:relative;
}
#mastheadbd .top{
display:block;
position:relative;
left:-1px;
margin-right:-2px;
height:4px;
font-size:0;
}
#mastheadbd .mh_footer{
position:absolute;
width:100%;
bottom:0;
clear:both;
}
#mastheadbd{
position:relative;
min-height:106px;
height:7.85em;
margin:0 auto 10px;
}
#masthead h1{
float:left;
margin:17px 0 0 18px;
*margin-left:8px;
*width:219px;
height:50px;
*height:45px;
}
#searchother{
*display:none;
position:absolute;
left:0;
height:100%;
max-height:120px;
min-height:85px;
width:100%;
}
#searchwrapper{
position:relative;
top:auto;
left:0;
margin-left:260px;
width:70%;
_width:90%;
height:6.1em;
padding:0 0 10px;
_z-index:100;
}
#searchIE{
display:none;
*display:block;
position:absolute;
width:100%;
height:113%;
_height:92%;
voice-family:"\\"}\\"";
voice-family:inherit;
property:value;
_height:90%;
}
#search{
position:relative;
z-index:200;
top:15px;
_height:89px;
zoom:1;
}
#scountry{
float:right;
position:relative;
margin-top:2px;
_margin-top:-2px;
top:0;
}
#scountry li{
display:inline;
position:relative;
white-space:norap;
}
#scountry li label{
margin:0 0 0 10px;
}
#scountry li.first label{
margin:0;
}
#scountry input{
margin:0 4px -3px 0;
_margin:0 2px -2px 0;
}
#vsearchtabs{
position:relative;
margin:0 0 5px;
_display:inline;
left:88px;
margin-left:3.6em;
_margin-left:0;
text-align:center;
z-index:100;
min-width:320px;
width:24em;
_width:30em;
overflow:visible;
min-height:16px;
height:1em;
}
#vsearchtabs li{
float:left;
_float:none;
_display:inline;
border-left:1px solid #b0bec7;
}
#vsearchtabs li.first, #vsearchtabs li.last{
border:0;
}
#vsearchtabs li a{
padding:0 7px;
font-size:92%;
border-right:1px solid #fff;
}
#vsearchtabs li.on a{
color:#333;
font-weight:bold;
}
.ignore{position:relative; }
#vsearchtabs dl{position:relative;display:inline;z-index:100;}
#vsearchtabs dt{display:inline;}
#vsearchtabs dl dt a{
position:relative;
border-left:1px solid #B0BEC7;
padding:1px 18px 0 5px;
_padding:2px 19px 0px 5px;
text-transform:lowercase;
background-position:2em -406px;
line-height:14px;
height:14px;
}
#vsearchtabs dt a:hover, #vsearchtabs dt a.on{
border:1px solid #B0BEc7;
text-decoration:none;
margin:-1px 0 -1px 0;
_margin:-2px 0 -2px 0;
background-position:2em -454px;
*background-position:2em -453px;
_background-position:2em -454px;
*top:1px;
}
#vsearchtabs dt a.on, #vsearchtabs dt a.on:hover{
background-position:2em -505px;
*background-position:2em -504px;
_background-position:2em -505px;
text-indent:0;
}
#mastheadbd{position:relative;z-index:100;}
#search{overflow:visible;}
#search fieldset{overflow:visible;}
#vslist{
position:absolute;
left:0;
top:17px;
_top:1.4em;
display:none;
background:#889AA7;
z-index:100;
background:#eee;
border:1px solid #889AA7;
font:92% arial;
width:12em;
text-align:left;
}
#vslist div{
position:relative;
margin:-2px -0px -0px -2px;
background:#fff;
border:1px solid #889AA7;
padding:5px 2px;
}
#vslist span{
position:relative;
display:block;
margin:8px 4px 5px;
border-top:1px solid #889AA7;
font-size:1px;
height:1px;
}
#vslist ul,#vslist li{
position:relative;
border:0;
display:block;
float:none;
}
#vsearchtabs #vslist a{
position:relative;
display:block;
padding:3px 4px;
}
#vslist a:hover{
background:#889AA7;
color:#fff;
text-decoration:none;
}
#sbox{
min-height:25px;
height:2em;
width:100%;
margin:0 0 1px;
}
#sbox label{
float:left;
}
#searchlabel{
position:relative;
margin:2px 8px 0 20px;
font:bold 122% arial;
color:#333;
}
#p,#scsz{
width:100%;
padding:3px 0 3px 3px;
_height:24px;
}
#searchbox .plong{
width:100%;
}
#search .btn-more-2{
float:left;
position:relative;
margin-left:-1px;
padding:2px 10px;
*padding:1px;
min-width:140px;
width:10em;
_width:140px;
*overflow:visible;
cursor:pointer;
z-index:50;
text-align:center;
}
#searchbox{
float:left;
width:62%;
text-align:left;
margin-bottom:0;
*margin-top:-1px;
}
#searchbox .plabel,#searchbox .cszlabel2{
width:44.5%;
}
#searchbox .cszlabel1{
text-align:center;
font-weight:bold;
padding-top:5px;
width:8.4%;
*width:7.0%;
}
#searchbox span{
font-size:77%;
}
#sboxfooter{
position:relative;
left:8.8em;
_left:8.5em;
width:62.5%;
padding-bottom:6px;
font:normal 77% verdana;
text-align:center;
white-space:nowrap;
zoom:1;
top:-2px;
_top:-3px;
z-index:10;
line-height:14px;
}
.ynarrow #sboxfooter{
  width:90%;
}
#sboxfooter{
  width:83.5%;
  text-align:left;
}
#sboxfooter .answers{
  float:left;
  margin-top:1px;
}#sboxfooter .answers a{
padding:2px 0;_padding:0;_width:1em;_line-height:18px;
}
#sboxfooter a.yans{
font-weight:bold;background-position:-15px -563px;_width:1em;padding-left:18px;
}
#sboxfooter .answers em{
padding:2px 0;*padding:0;_line-height:18px;
}
#sboxfooter em{font-style:italic;}
#mh_footer{z-index:9;}
#doors{
position:absolute;
left:20px;
*left:10px;
bottom:4px;
*bottom:3px;
border:0;
background:0;
}
#doors ul{
border:0;
}
#doors li{
float:left;
margin:0 0 0 5px;
}
#doors li strong{
display:block;
position:relative;
top:-1px;
left:-1px;
min-width:82px;
*width:5.5em;
_width:3em;
}
#doors li a{
position:relative;
min-width:60px;
_width:4.8em;
margin:0;
padding:1px 6px;
font:normal 100% arial;
}
#trough{
position:relative;
overflow:hidden;
*overflow:visible;
}
#trough .bd{
padding:0;
}
#trough span{
display:block;
}
#trough span{
position:relative;
margin:-1px -1px 0 0;
padding:5px;
}
#trough .btn-more-2{
display:block;
position:static;
padding:1px 2px;
font-size:92%;
text-align:center;
white-space:nowrap;
}
#trough li{
padding:3px 0 3px 5px;
p\\adding:3px 0;
margin-left:-15px;
ma\\rgin-left:0;
}
#trough li a{
display:block;
*display:inline;
min-height:12px;
padding:3px 0 3px 25px;
margin:-1px 0 -2px;
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/sp/trough_1.2.gif) 0 0 no-repeat;
font:bold 84% verdana;
voice-family:"\\"}\\"";
voice-family:inherit;
property:value;
_margin-left:0;
}
#trough li.adaptive{
padding:3px 0 3px 5px;
*padding:2px 0 2px 5px;
font:bold 122% arial;
}
#trough li.adaptive a{
padding:1px 0 1px 25px;
}
#trough .highlight a{
color:#C40007;
}
span#edityservicescx{
display:block;
position:relative;
padding:1px;
text-align:right;
margin-right:-1px;
}
#edityservices{
display:block;
width:43px;
height:11px;
font-size:0px;
text-indent:-5000px;
margin-left:auto;
}
#edityservices:hover{
text-decoration:none;
}
#trough small{
margin:-3px 0 0 1px;
*margin-top:1px;
position:absolute;
}
#trough #trough-promo small{
margin:-3px 0 0 1px;
*margin-top:1px;
position:absolute;
}
#trough-promo{
background-position:0 -300px;
border-top:1px solid #F3F6F9;
}
#trough-promo .first{
border-width:1px 0 0;
border-style:solid;
}
#pagesettingscx{
position:absolute;
right:10px;
bottom:3px;
zoom:1;
z-index:90;
}
a#editpage{
font:normal 77% verdana;
padding-right:15px;
zoom:1;
display:block;
*display:inline;
height:12px;
}
#pagesettings{
display:none;
position:absolute;
top:100%;
right:-3px;
min-width:160px;
margin:2px 0 0;
background:#acc0c9;
z-index:99;
}
#pagesettings .iemw{
width:150px;
}
#pscolors{
width:100%;
}
#pagesettings .bd{
position:relative;
top:-1px;
left:-1px;
padding:0;
background:#fffac6;
border:1px solid #000;
border-color:#cad5db #6b8792 #6b8792 #cad5db;
}
#pagesettings .bd span{
display:block;
padding:15px 5px;
font:bold 77% verdana;
white-space:nowrap;
border:1px solid #fff;
border-width:0 1px 1px 0;
text-align:center;
}
#pagesettings h4{
float:left;
_margin-right:-2px;
font:bold 100% verdana;
}
#pagesettings ol{
border:1px solid transparent;
margin:-1px;
*border:0;
*margin:0;
}
#pagesettings ol li{
float:left;
}
#themes li a,#psbca{
display:block;
margin-left:6px;
width:13px;
height:12px;
text-indent:-5000px;
font-size:0px;
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/sp/theme-icons_1.2.gif) no-repeat;
cursor:pointer;
cursor:hand;
zoom:1;
}
#themes li a:hover{
text-decoration:none;
}
#themes #t1{background-position:0 0;}
#themes #t2{background-position:-19px 0;}
#themes #t3{background-position:-38px 0;}
#themes #t4{background-position:-57px 0;}
#themes #t5{background-position:-75px 0;}
#themes #t7{background-position:-94px 0;}
#themes #t1.on{background-position:0 -15px;}
#themes #t2.on{background-position:-19px -15px;}
#themes #t3.on{background-position:-38px -15px;}
#themes #t4.on{background-position:-57px -15px;}
#themes #t5.on{background-position:-75px -15px;}
#themes #t7.on{background-position:-94px -15px;}
#pagesettingscx #sizetogglelink{
display:block;
margin-top:10px;
padding-top:8px;
border-top:1px solid #cbd4db;
zoom:1;
}
#today{
min-height:234px;
_height:234px;
}
#today h3{
font:bold 122% arial;
color:#16387c;
}
#today h3 a{
font:bold 100% arial;
}
#today h3 a.video{
padding-left:18px;
background-position:-3px -47px;
}
#today p{
margin:5px 0;
}
#today .bd{
position:relative;
padding:6px 0 4px 10px;
_padding:7px 0 5px 10px;
min-height:114px;
_height:116px;
background:#fff;
}
#today .timestamp{
margin-bottom:6px;
_margin:-1 0 6px;
}
#today .bd img{
float:left;
margin-right:10px;
width:154px;
height:115px;
padding:1px;
border:1px solid #9dafbd;
border-color:#9eb1c0 #677787 #677787 #9eb1c0;
}
#today .bd a.more{
white-space:nowrap;
}
#today .pencil,#today img.editor{
position:absolute;
width:auto;
height:auto;
}
#today .bd span.current span{
float:left;
width:57%;
*width:56.5%;
margin-bottom:9px;
_margin-bottom:-6px;
overflow:hidden;
_height:9.35em;
}
#today .bd h3,#today .bd p,#today .bd ul{
margin:0 0 6px;
}
#today .bd ol,#today .bd ul,#today .bd ul li{
float:left;
}
#today .bd ul{
width:100%;
}
#today .bd ul li a{
margin-right:10px;
white-space:nowrap;
zoom:1;
}
#newsbd dl dt a, #today .bd ul.inline li a{
margin-right:3px;
font:normal 77% verdana;
}
#today .bd ul.inline{
margin-left:-10px;
}
#today .bd ul.inline li{
display:inline;
float:none;
margin:-2px 0 -2px 4px;
padding-left:5px;
border-left:1px solid #B0BEC7;
}
#today .bd ol li a{
display:block;
*display:inline;
zoom:1;
}
#today .ft{
position:relative;
padding:0 5px 22px;
_padding:0 5px 23px;
background:#fff;
}
#today .ft ul{
float:left;
*float:none;
padding:2px 0 0;
width:100%;
}
#today .ft li{
position:relative;
float:left;
width:46%;
margin-right:2%;
min-height:30px;
_height:30px;
border:1px solid #fff;
}
#today .ft li img{
float:left;
margin:0 5px 0 2px;
padding:1px;
border:1px solid #9eb1c0;
border-color:#9eb1c0 #677787 #677787 #9eb1c0;
}
#today .ft li a{
display:block;
padding:2px 0;
margin:1px;
min-height:22px;
_height:22px;
font:normal 77% verdana;
}
#today .ft li a .editor{
position:absolute;
left:0;
}
#news{
background:#f5f7f6;
z-index:70;
}
#news.afterhours{
}
#page #news .btn-more{
bottom:10px;
_bottom:9px;
}
#newsbd{
position:relative;
padding:9px 0 0;
background:#fff;
}
#newstop{
position:relative;
_margin-top:4px;
padding:0 9px 18px;
_padding-bottom:1.2em;
min-height:139px;
_height:157px;
}
#newstop.special{
min-height:92px;
*min-height:95px;
_height:111px;
}
#news.afterhours #newstop{
min-height:157px;
_height:176px;
}
#news.afterhours #newstop.special{
min-height:110px;
*min-height:113px;
_height:130px;
}
#news .single-panel{
padding:0 0 1.4em 9px;
min-height:187px;
*min-height:186px;
_height:205px;
}
#news.afterhours .single-panel{
min-height:181px;
_height:201px;
}
#newstop i{
color:#dadada;
}
#newsft{
position:relative;
font:normal 77% verdana;
color:#333;
}
#newsbottom{
padding:4px 0 4px 10px;
}
#news.afterhours #newsbottom{
padding:4px 0 6px 10px;
}
#finance-data{
float:left;
}
#news-sponsor{
float:left;
display:inline;
margin-left:10px;
font-size:92%;
color:#333;
}
#news.afterhours #news-sponsor{
position:relative;
top:1px;
_top:0;
margin:-12px 0 0 10px;
_margin-top:-10px;
white-space:nowrap;
}
#news-sponsor img{
display:block;
margin:5px 0 0;
}
#news.afterhours #news-sponsor img{
display:inline;
position:relative;
top:3px;
*top:4px;
}
#markets, #markets span, #markets ul, #markets li, #quotes fieldset{
display:inline;
}
#news.afterhours #markets{
margin:0;
}
#markets h3{
font:normal 100% verdana;
display:inline;
}
#markets li{
white-space:nowrap;
margin-left:5px;
}
#quotes a{
color:#333;
}
#quotes{
margin-top:5px;
}
#quotes a,#s{
margin-right:5px;
}
input#s{
font-size:107%;
padding:1px;
}
#quotes .submit{
font-size:100%;
padding:0 3px;
}
#newsbd li a cite{
display:block;
font:normal 77% verdana;
color:#333;
}
#newsbd li a:hover cite{
text-decoration:none;
}
#newsbd dl dt a{
margin:0;
}
#newsbd dl{
display:inline;
margin:0 0 0 6px;
border-left:1px solid #B0BEC7;
}
#newsbd dl dt{
display:inline;
margin-left:5px;
}
#markets .up{color:#359c00;}
#markets .down{color:#c00;}
#videonewsct ul{
margin:7px 0 0 -5px;
}
#videonewsct li{
float:left;
margin:0 -1px 10px 2px;
padding:0 0 0 1px;
width:49%;
}
#videonewsct li img{
float:left;
margin-right:5px;
padding:1px;
border:1px solid #9dafbd;
border-color:#9eb1c0 #677787 #677787 #9eb1c0;
}
#page #news ul.btn-more, #more-today,#more-video{
position:absolute;
bottom:9px;
_bottom:8px;
margin:0;
padding:0 0 1px;
color:#16387c;
}
#more-today{
bottom:5px;
}
#news ul.btn-more li, #more-today span,#more-video span{
display:inline;
margin-right:5px;
padding-right:5px;
line-height:1em;
border-right:1px solid #94a1c3;
}
#news ul.btn-more li a, #more-today a,#more-video a{
line-height:1em;
}
#news ul.btn-more li.first, #more-today .first,#more-video .first{
border:0;
padding:0;
font-weight:normal;
}
#news ul.btn-more li.last, #more-today .last,#more-video .last{
border:0;
margin:0;
padding:0;
}
.timestamp{
display:block;
font:normal 77% verdana;
color:#999;
margin-bottom:4px;
}
#localnewsct li cite{font:normal 77% verdana;}
#localnewsct li cite a{color:#666;}
#localnewsulmcx{position:absolute;}
.ulmtrigger,.ulmtriggeron{position:absolute;top:0px;*top:-1px;right:10px;font:normal 77% verdana;}
.ulmtrigger a,.ulmtriggeron a{background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t1/ulm-norgie-dn.gif) no-repeat left 50%;padding-left:12px;}
.ulmtriggeron a{background-image:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t1/ulm-norgie-up.gif);}
#localnewsct #newstop{
z-index:3;
}
#localnewsct .nocookie dl{
display:block;
}
#localnewsct #newstop h4{
font-size:122%;
margin:0 0 1px;
}
#localnewsct .nocookie form.ulmform{
position:relative;
top:20px;
margin:0 0 20px;
}
#localnewsct #newstop .inputtext{
_height:22px;
width:75%;
}
#localnewsct #newstop li{
font:normal 100% arial;
padding:0 0 0 10px;
background-position:-7px 1px;
overflow:hidden;
white-space:nowrap;
*width:100%;
text-overflow:ellipsis;
}
#localnewsct #newstop li cite{
font-size:85%;
color:#666;
}
#localnewsct .ulmmarkets{
color:#333;
}
#localnewsct .nocookie fieldset{
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/sp/ulmln2.gif) 7px 12px no-repeat;
}
#localnewsct span.alert{
font-size:85%;
}
#patop{
position:relative;
padding:8px 9px 9px;
}
#patop .so{
padding:2px 0;
}
#patop .so a{
font-weight:bold;
}
#reg li{
_margin-left:-15px;
_ma\\rgin:0;
}
#reg h2{
font:normal 122% arial;
}
#reg h2 a{
font-weight:bold;
}
#signup,#signout{
position:absolute;
top:2px;
right:0;
t\\op:10px;
r\\ight:10px;
}
#signout{
top:11px;
right:10px;
font:normal 77% verdana;
}
#patabs{
padding:0 2px 2px 5px;
margin-top:-5px;
}
#patabs ul.patabs li{
color:#8899a9;
float:left;
min-width:113px;
width:33.2%;
}
#patabs ul.patabs{
position:relative;
z-index:10;
}
#patabs ul.patabs li div{
display:block;
position:relative;
z-index:2;
margin:4px 3px 0;
}
#patabs ul.patabs li.first div{
margin-left:2px;
}
#patabs ul.patabs li.last div{
margin-right:0;
}
#patabs ul.patabs li h4,#patabs ul.patabs li a{
display:block;
position:relative;
z-index:2;
top:-1px;
left:-1px;
font:bold 92% verdana;
}
#patabs ul.patabs li a{
z-index:20;
padding:1px 0;
*padding:0;
}
#patabs ul.patabs li.tab-on a{
margin:-1px -1px -3px;
top:0;
left:0;
*background-position:0 1px;
}
#patabs li a.details b{
display:block;
position:absolute;
bottom:5px;
*bottom:4px;
_bottom:8px;
left:40px;
padding-right:1px;
font-size:92%;
font-weight:normal;
}
#patabs li.tab-on a.details b{
bottom:13px;
*bottom:12px;
}
#patabs li.tab-on .icon{
padding-bottom:17px;
}
#patabs li .details .icon{
padding:3px 0 14px 40px;
}
#patabs li.tab-on .details .icon{
padding:3px 0 22px 40px;
}
#patabs li .icon{
display:block;
z-index:10;
padding:8px 0 9px 40px;
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t7/pa-icons2.gif) 5px 3px no-repeat;
}
#patabs .papreviewdiv{
position:relative;
z-index:1;
visibility:hidden;
margin-right:1px;
*margin-right:0;
_margin-right:1px;
}
#patabs .preview-on{
visibility:visible;
padding-top:4px;
}
#patabs .papreviewdiv span{
display:none;
}
#patabs .papreviewdiv span.current{
display:block;
}
#patabs #messenger .icon{
padding-left:31px;
background-position:2px -497px;
}
#patabs #music .icon{
background-position:5px -197px;
}
#patabs #answers .icon{
padding-left:36px;
background-position:5px -695px;
}
#patabs #weather .icon{
background-position:5px -297px;
}
#patabs #traffic .icon{
background-position:5px -397px;
}
#patabs #movies .icon{
background-position:5px -597px;
}
#patabs #horoscope .icon{
padding-left:29px;
background-position:3px -797px;
}
.nav a{position:absolute;z-index:90;top:40%;width:22px;height:18px;text-indent:-5000px;overflow:hidden;}
.nav a.back{left:3px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/back.gif) no-repeat;}
.nav a.frwd{right:3px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/next.gif) no-repeat;}
.nav a:hover{text-decoration:none;}
.pa-alert{text-align:center;color:#16387c;padding:0 20px;_padding:0;}
.pa-alert h3,.pa-alert ul{margin:5px auto 0;text-align:left;}
.pa-alert h3{_margin-left:20px;_padding-left:20px;}
.default{_margin-left:-20px;}
.default li{float:left;padding-left:20px;}
.default li.last{width:14em;padding-left:10px;margin-top:15px;}
.default li.last a{font-weight:bold;text-decoration:underline;margin-top:20px;}
.error,.promo{position:absolute;bottom:0;top:5px;_top:9px;left:0;right:0;background:#edf2f7 url(http://us.js2.yimg.com/us.js.yimg.com/i/ww/t9/error_bckgrnd.gif) repeat-x;}
.error ul{margin:15px 10px 15px 10px;_margin-left:15px;padding:10px 0 0 80px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/sp/error_msg.gif) no-repeat;}
.error li{float:none;margin:0;}
.error li.first{padding:5px 0 15px;_height:50px;min-height:35px;}
.error li.first a{text-decoration:underline;font-weight:bold;}
.error li.last{text-align:right;font:bold 77% verdana;}
.promo{
_top:auto;
padding-right:0;
_padding-bottom:10px;
}
.promo h4{
font:normal 107% arial;
color:#434343;
margin:10px 0 0 0;
_margin-left:20px;
padding:15px 0 65px 50px;
_padding-left:40px;
zoom:1;
}
#page .promo h4 a{
font-weight:bold;
text-decoration:underline;
}
.promo p{
position:absolute;
top:50px;
right:20px;
font:normal 77% verdana;
text-align:right;
color:#434343;
}
.promo p .more{
display:block;
font:bold 100% verdana;
text-decoration:none;
}
.promo p .more:hover{
text-decoration:underline;
}
#mailpreview .error ul{background-position:0 10px;}
#messengerpreview .error ul{background-position:0 -150px;}
#musicpreview .error ul{background-position:0 -300px;}
#weatherpreview .error ul{background-position:0 -445px;}
#trafficpreview .error ul{background-position:0 -600px;}
#horoscopepreview .error ul{background-position:0 -750px;}
#answerspreview .error ul{background-position:0 -900px;}
.loading{margin-top:35px;text-align:center;color:#16387c;}
#pa .loading h3{font-size:122%;text-align:center;}
.papreviewdiv .btn-more{bottom:3px;right:10px;z-index:1;}
.papreviewfooter .fleft{float:left;}
.papreviewfooter .fright{float:right;}
#mailpreview table{margin-bottom:1.2em;width:100%;border-collapse:collapse;font:normal 100% arial;margin-top:3px;table-layout:fixed;border-bottom:1px solid #ebeff2;}
#mailpreview table td{height:152%;background:#fff;border-top:1px solid #ebeff2;white-space:nowrap;overflow:hidden;}
#mailpreview table td.left{padding-left:8px;}
#mailpreview table td.right{padding-left:18px;}
#mailpreview .left{width:33%;}
#mailpreview .center{width:44%;*width:38%;}
#mailpreview .right{width:23%;*width:29%;}
#mailpreview table td  a{float:left;white-space:nowrap;overflow:hidden;}
#mailpreview th{font:normal 85% verdana;text-align:left;}
#mailpreview .pamailfooter{position:absolute;bottom:5px;bottom:5px;left:10px;right:10px;font:77% verdana;}
.pamailfooter{font-size:85%;}
.pamailfooter  .fleft{float:left;}
.pamailfooter  .fright{float:right;}
#mailpreview .hdr{color:#333;}
#mailpreview .seen1{color:#666;}
#mailpreview .btn-more{font-size:85%;}
#mailpreview .hdr th.left{padding-left:8px;}
#mailpreview .hdr th.right{padding-left:18px;}
#mailpreview .seen0{color:#16387c;font-weight:bold;}
.linklist li{display:inline;padding-left:5px;margin-left:5px;border-left:1px solid #B0BEC7;}
.linklist li.first{padding-left:0;margin-left:0;border-left:0;}
#musicpreview,#horoscopepreview{padding-bottom:1em;_padding-bottom:.7em;}
#musicpreview{text-align:center;margin:0 auto;}
#musicpreview h3{font:bold 100% arial;text-align:left;margin:3px 0 3px 10px;color:#16387c;}
#musicpreview h3 em{font-weight:normal;}
.station{position:relative;left:1px;width:275px;margin:5px auto 10px;text-align:left;background:#F8F9FD;}
#horoscopepreview{text-align:center;margin:0 auto;min-height:7.6em;_height:7.6em;padding-bottom:0;}
#horoscopepreview h3{font-size:100%;text-align:left;}
#horoscopepreview .station{background:#fff;}
.station-bd{min-height:70px;*height:70px;padding-right:10px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/music-mask-1.gif) 100% 0 no-repeat;}
.station-hd,.station-ft{position:absolute;left:0;font-size:0px;width:275px;height:5px;}
.station-hd{top:0;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/music-mask-0.gif) no-repeat;}
.station-ft{bottom:-1px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/music-mask-2.gif) no-repeat;}
.station-name{float:left;min-height:15px;*height:15px;width:170px;font:bold 100% arial;*font-size:85%;margin:2px 0 0;}
.photo-link{float:left;margin:0 5px 0 0;border-right:1px solid #353535;width:70px;height:70px;text-align:center;}
#horoscopepreview .photo-link{background:#F1F5F6;border:0;_height:100%;}
.station-photo{width:70px;height:70px;}
#horoscopepreview .station-photo{width:35px;height:35px;margin-top:15px;}
#horoscopepreview .papreviewfooter{position:absolute;bottom:5px;left:10px;right:10px;bottom:5px;font:77% verdana;}
.artists{float:left;width:185px;min-height:28px;*height:28px;font:normal 77% verdana;color:#666;}
#horoscopepreview .artists{padding-bottom:5px;}
.artists a{display:block;overflow:hidden;color:#666;}
.listen{float:right;width:45px;height:15px;margin:5px -3px 5px 0;text-indent:-5000px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/music_button.gif) no-repeat;display:none;*display:inline;}
#horoscopepreview .lsigns ul{color:#16387c;font-weight:bold;text-align:left;}
#horoscopepreview .lsigns ul li{line-height:155%;padding-left:16px;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/icons_1.1.gif) no-repeat 0 4px;}
#horoscopepreview small{font-weight:normal;}
#horoscopepreview .bd{background:#FFFAC6;border-top:2px solid #97ADBA;}
#horoscopepreview .head{min-height:16px;_height:16px;}
#horoscopepreview .head a{font:bold 77% verdana;}
#horoscopepreview .fleft{float:left;}
#horoscopepreview .fright{float:right;}
#horoscopepreview .lsigns{background:#fff url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/pa-preview-shadow.gif) repeat-x top;border:1px solid #E7ECF0;border-top:1px solid #97ADBA;padding:3px 0 4px;}
#horoscopepreview .lsigns .fleft{width:46%;}
#horoscopepreview .lsigns .fright{float:left;}
.papreviewheader{
margin-top:4px;
padding:0 10px;
height:1.5em;
clear:both;
overflow:hidden;
}
.papreviewheader .fleft{float:left;font-size:100%;font-weight:bold;}
.papreviewheader .fright{float:right;font:85% verdana;}
.papreviewheader .fright a{background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t1/ulm-norgie-dn.gif) no-repeat left 50%;padding-left:15px;}
#pamssgr{
position:relative;
padding:1px 5px 2px;
}
#pamssgr span#panav{
display:block;
position:absolute;
top:1px;
right:5px;
white-space:nowrap;
}
#pamssgr .hdr{
color:#16387c;
}
#msgrcount{
display:inline;
float:none;
}
#panav a{
font:bold 77% verdana;
color:#16387c;
}
#panavprev{
padding-left:10px;
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/pointer-blue-left.gif) center left no-repeat;
}
#panavnext{
padding-right:10px;
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/pointer-blue-right.gif) center right no-repeat;
}
#pamssgr ol{
display:none;
}
#pamssgr ol li{
margin:3px 0 0;
}
#pamssgr .current{
display:block;
padding-bottom:20px;
*padding:auto;
}
#pamssgr .blast{
width:16px;
height:16px;
zoom:1;
}
#pamssgr .buddy{
margin-left:5px;
padding-left:18px;
font-weight:bold;
background:url(http://us.i1.yimg.com/us.yimg.com/i/us/msg/6/gr/online_12px_1.gif) 0 2px no-repeat;
}
#pamssgr .buddyop{
color:#16387c;
}
#pamssgr .ft{
position:absolute;
bottom:5px;
padding:0 5px;
*padding:0;
margin:0;
font:bold 77% verdana;
}
#pamssgr .three60{
float:left;
font-weight:normal;
}
#pamssgr .psmssgrlnch{
float:right;
_padding-right:10px;
}
#Ymsgr02{position:absolute;left:-1000px;}
.papreviewheader{
margin:0;
padding:0 10px;
height:1.4em;
clear:both;
overflow:hidden;
}
.papreviewheader .fleft{float:left;font-size:100%;font-weight:bold;line-height:150%;}
.papreviewheader .fleft a{line-height:150%;}
.papreviewheader .fright{float:right;font:85% verdana;display:inline !important;}
.papreviewheader .fright a{background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t1/ulm-norgie-dn.gif) no-repeat left 50%;padding-left:15px;line-height:170%;}
.papreviewheader .fright a.up{background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t1/ulm-norgie-up.gif) no-repeat left 50%;padding-left:15px;line-height:170%;}
#localfooter{height:1.2em;line-height:150%;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/pa-preview-shadow.gif) repeat-x;xbackground-position-y:-1px;padding:0 10px;position:relative;}
#weatherpreview .forcast{position:relative;top:4px;clear:both;margin:1px 10px;margin-bottom:1.3em;font-size:92%;height:5em;}
#weatherpreview .forcast div{position:relative;float:left;width:48%;background:#f0f0f0 url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/weather_bg.png) no-repeat 100% 100%;}
#weatherpreview .tr, #weatherpreview .bl, #weatherpreview .tl{
position:absolute;
width:10px;
height:10px;
background:#F7FAFC url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/weather_bg.png) no-repeat right bottom;
}
#weatherpreview .tr{
top:-3px;
right:0;
background-position:right top;
}
#weatherpreview .tl{
top:-4px;
left:-4px;
background-position:left top;
}
#weatherpreview .bl{
bottom:0;
left:-3px;
background-position:left bottom;
}
#weatherpreview .forcast .tomorrow{float:right;}
#weatherpreview dl{margin:7px 0 5px 12px;min-height:60px;*height:60px;}
#weatherpreview dt{padding:0;margin:0;font-weight:bold;padding-left:40px;font-size:107%;}
#weatherpreview dd{padding:3px 0;margin:0;padding-left:40px;line-height:150%;font:92% verdana;}
#weatherpreview dd.info{font:92% verdana;}
#weatherpreview dd em{font-style:normal;font-weight:bold;}
#weatherpreview .high{color:#F46227;padding-right:4px;}
#weatherpreview .low{color:#00B2EB;padding-right:4px;}
#weatherpreview .info{display:inline;}
#weatherfooter{position:absolute;bottom:5px;left:10px;right:10px;font:77% verdana;}
#weatherfooter .fleft{float:left;}
#weatherfooter .extended{float:right;font-weight:bold;text-align:right;}
.ulmform{
position:relative;
padding:9px;
margin:0;
border:2px solid #95ADB7;
background:#ffc;
zoom:1;
}
.nocookie form.ulmform{
margin:10px 10px 0;
}
.ulmform fieldset{
*position:relative;
padding:0 0 0 59px;
margin:0;
background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/t4/local_map.gif) no-repeat 10px 22px;
zoom:1;
}
#weatherpreview .ulmform fieldset{background:#ffc url(http://us.i1.yimg.com/us.yimg.com/i/ww/t1/weather-form-icon.gif) no-repeat 9px 50%;}
.ulmform fieldset.invalid{
margin:-5px 0 -4px;
}
.ulmform input{
margin:0 5px 0 0;
}
.ulmform label{
margin:3px 0;
_margin:2px 0;
display:block;
font:92% arial;
}
.ulmform fieldset.cl{
padding-top:4px;
padding-bottom:5px;
}
.ulmform #csz, .ulmform .inputtext{
width:13em;
*width:12.5em;
_width:13em;
_height:22px;
padding:2px;
margin-left:0;
}
#ulmdefault, input.ulmdefault{
*margin:-1px 0 0 -3px;
}
#ulmdefaultlbl, .ulmdefault, label.ulmdefaultlbl{
left:0;
margin:3px 0;
*margin:1px 0;
font-size:85%;
}
.ulmform fieldset.cl #ulmdefaultlbl, .ulmform fieldset.cl .ulmdefaultlbl{
maring:5px 0 7px;
}
.ulmform .alert, .cszlabelinvalid{
color:red;
}
.ulmform .nonus{
margin:-4px;
margin-top:-9px;
padding-left:35px;
background-position:0 30px;
}
.ulmform .nonus #csz{
margin-left:5px;
}
.ulmform .nonus #cszlabel{
margin-right:-5px;
}
.ulmform fieldset.picklist{
border:1px solid #ccc;
padding:10px 0 10px 65px;
}
#picklist dl{
margin:6px 0 10px;
padding:3px;
height:67px;
border:1px solid #ccc;
overflow:auto;
background:#fff;
}
#picklist dt{
font-weight:bold;
}
#picklist dd{
padding:0 0 0 20px;
}
#picklist a{
display:block;
}
.ad{
text-align:center;
margin-bottom:9px;
}
.ad table{
margin:0 auto;
}
#pulse{
position:relative;
min-height:202px;
_height:201px;
}
#pulse .btn-more{
z-index:50;
}
#popsearch span{font:normal 92% arial;}
#popsearch .bd{padding:8px 3px 0 3px;}
#popsearch ol{float:left;width:49.5%;}
#popsearch li:after{content:".";display:block;font-size:0px;line-height:0px;height:0;clear:both;visibility:hidden;}
#popsearch li{border:1px solid transparent;_border:0;padding-left:18px;padding-right:1px;margin-bottom:6px;font:bold 77%/150% verdana;background:url(http://us.i1.yimg.com/us.yimg.com/i/pulse/06q3/p_numb2.gif) 0 0 no-repeat;}
#popsearch li.tt1{background-position:0 -1px;}
#popsearch li.tt2{background-position:0 -39px;}
#popsearch li.tt3{background-position:0 -77px;}
#popsearch li.tt4{background-position:0 -115px;}
#popsearch li.tt5{background-position:0 -153px;}
#popsearch li.tt6{background-position:0 -190px;}
#popsearch li.tt7{background-position:0 -229px;}
#popsearch li.tt8{background-position:0 -267px;}
#popsearch li.tt9{background-position:0 -305px;}
#popsearch li.tt10{background-position:0 -343px;}
#popsearch li a{display:block;margin-top:1px;*margin-top:-1px;_margin-top:0;}
#popsearch li a{float:left;}
#footer{
clear:both;
text-align:center;
padding:10px 0;
border-left:0;border-right:0;border-bottom:0;
}
#footer .strong{
font-weight:bold;
}
#footer ul{
margin-bottom:6px;
width:100%;
}
#footer li{
display:inline;
padding:0 2px 0 5px;
margin:0;
border-left:1px solid;
font-family:verdana;
font-size:85%;
color:#999999;
}
#footer li.first{
border:0;
padding-left:0;
margin-left:4px;
}
#ws_ie7{font-size:69%;position:relative;border:1px solid #cad5db;border-width:0 1px 1px;margin-bottom:10px;cursor:pointer;}
#ws_ie7 h3 a{font-size:55%;text-decoration:none;color:#16387c;padding:3px;padding-left:26px;font-weight:bold;background:url(http://us.js2.yimg.com/us.js.yimg.com/i/ww/sp/toolbar.gif) no-repeat 0 2px;display:block;margin:0 auto 3px 11px;padding-top:4px;width:938px;}
#ws_button{font:bold 110% verdana;text-decoration:none;border:1px solid #cad5db;border-width:0 0 0 1px;padding-left:5px;padding-top:6px;position:absolute;top:0px;right:0;display:block;width:9em;background:url(http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/grd-1px_1.1.gif) repeat-x 0 -178px;height:1.7em;_height:2.2em;}
.ynarrow #ws_ie7 h3 a{width:758px};
.ynarrow #ws_button{right:0px;}
#eyebrow{display:none;}

</style>
<script type="text/javascript">
now=new Date;
t2=now.getTime();
</script>
</head>
<body class="ywide">
<div id="page">
<style type="text/css">
#ws_ie7{font-size:100%;}
#ws_ie7 h3 a{font-size:69%;*font-size:55%;}
#ws_button{font-size:77%;}
</style>
<div id="ws_ie7">
  <h3><a href="r/wc">Browse the Web - quickly and safely with Yahoo! Toolbar</a></h3>
  <a href="r/wc" id="ws_button">&#187; Get It Now</a>
</div>

<div id="masthead">
<div id="mastheadhd">
<div id="eyebrow">
<ul id="ypromo">
<li id="toolbar"><a id="dtba" class="eyebrowborder" href="r/tb"><span id="tba">Get</span> Y! Toolbar</a></li>
<li><a id="sethomepage" href="r/hp"><strong>Make Y! your home page</strong></a></li>
</ul>
<div id="ffhpcx"></div>
<div id="headline">
<span><a href="http://us.ard.yahoo.com/SIG=12ls7l3sa/M=589006.10656327.11316185.9641256/D=yahoo_top/S=2716149:HDLN/_ylt=A9GDJJbFQUZGdmoBemf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4585375/R=0/SIG=11799sn52/*http://mobile.yahoo.com/?refer=1OFHLX">Yahoo! oneSearch:</a><a href="http://us.ard.yahoo.com/SIG=12ls7l3sa/M=589006.10656327.11316185.9641256/D=yahoo_top/S=2716149:HDLN/_ylt=A9GDJJbFQUZGdmoBemf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4585375/R=1/SIG=11neg9kgp/*http://mobile.yahoo.com/mobileweb/sports?refer=1OFHLX"> Favorite sports team\'s scores & more on the phone.</a><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'OZavKNGDJG4-\']=\'&U=13b0bk09f%2fN%3dOZavKNGDJG4-%2fC%3d589006.10656327.11316185.9641256%2fD%3dHDLN%2fB%3d4585375\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=141if71uk%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d704747172%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13b0bk09f%2fN%3dOZavKNGDJG4-%2fC%3d589006.10656327.11316185.9641256%2fD%3dHDLN%2fB%3d4585375"></noscript></span>
</div>
</div>
<script language="javascript" type="text/javascript">
var eDs = document.getElementById(\'defaultsearch\');
if(eDs&&eDs.style.display==\'none\'){
document.getElementById(\'eyebrow\').style.display=\'block\';
}
YAHOO.Fp.hm=document.getElementById(\'sethomepage\');
YAHOO.Fp.hp=1;
YAHOO.Fp.cp=0;
YAHOO.Fp.checkToolbar = function(){
var cpre=/ CP=v=(\\d+)&br=(.)/,cpv,cpbr,c=\' \'+document.cookie;
if(c.match(cpre)){
YAHOO.Fp.cp=1;
cpv=RegExp.$1;
cpbr=RegExp.$2;
if((cpbr==\'i\'&&cpv<60100)||(cpbr==\'f\'&&cpv<10201)){
YAHOO.Fp.cp=0;
if (document.getElementById(\'tba\')) { document.getElementById(\'tba\').innerHTML=\'New\'; }
}else{
YAHOO.Fp.cp=1;
if (document.getElementById(\'toolbar\')) {document.getElementById(\'toolbar\').innerHTML=\'<a id="dtba" href=\\\'r\\/1m\\\'>Get Yahoo! DSL</a>\';}
}
}
}
YAHOO.Fp.checkToolbar();
</script>
<!--[if IE]>
<a id="ieshp"></a>
<script language="javascript" type="text/javascript">
YAHOO.Fp.checkHomePage = function(){
YAHOO.Fp.sp=\'http://\'+location.hostname;
_ieshp=document.getElementById("ieshp");
_ieshp.style.behavior=\'url(#default#homepage)\';
// rLink: onclick tracking, isWs: if clicked came from windowshade, true or false.
var setHomePage=function(rLink,isWs){
YAHOO.Fp.beacon(rLink, true);
_ieshp.setHomePage(YAHOO.Fp.sp);
YAHOO.Fp.checkSHP(isWs);
return false;
}
YAHOO.Fp.hm.onclick = function(){setHomePage(\'r/hz\'); return false;};
var eHp = document.getElementById(\'hp_set\');
if(eHp){eHp.onclick = function(){setHomePage(\'r/hg\', true); return false;};}
YAHOO.Fp.hp=(_ieshp.isHomePage(YAHOO.Fp.sp)||_ieshp.isHomePage(YAHOO.Fp.sp+\'/\')||_ieshp.isHomePage(YAHOO.Fp.sp+location.pathname+location.search));
}
YAHOO.Fp.checkHomePage();
YAHOO.Fp.checkSHP = function(isWs){
var _hp=(_ieshp.isHomePage(YAHOO.Fp.sp)||_ieshp.isHomePage(YAHOO.Fp.sp+\'/\'));
var rLink = (isWs)? (_hp?\'r/hl\':\'r/hm\') : (_hp?\'r/hy\':\'r/hx\');
YAHOO.Fp.beacon(rLink, true);
if(_hp){
YAHOO.Fp.shp=1;
YAHOO.cookie.set("HP","1","","","yahoo.com");
alert("Your home page is now Yahoo!\\nThe home button of your browser goes directly to Yahoo!");
YAHOO.Fp.eyebrow();
if(YAHOO.Fp.WindowShade){
YAHOO.Fp.WindowShade.hide();
}
}
}
</script>
<![endif]-->
<script language="javascript" type="text/javascript">
YAHOO.Fp.shp=1;
YAHOO.Fp._hpc=YAHOO.cookie.get("HP");
YAHOO.Fp._hlr=(window.history.length==((YAHOO.Fp._ie)?0:1));
if( (YAHOO.Fp._ie==1 && YAHOO.Fp.hp) ||
(YAHOO.Fp._ff==1 && YAHOO.Fp._hlr) ){
YAHOO.cookie.set("HP","1","","","yahoo.com");
}else if(YAHOO.cookie.get("HP")==""){
YAHOO.Fp.shp=0;
}
if(YAHOO.Fp.shp==1&&document.getElementById(\'ws_hp\')){
document.getElementById(\'ws_hp\').style.display=\'none\';document.getElementById(\'eyebrow\').style.display = \'block\';
}
YAHOO.Fp.scp=((YAHOO.Fp._ie&&!YAHOO.Fp._ns)||YAHOO.Fp._ffv>=parseFloat(\'1.0\',10))?YAHOO.Fp.cp:1;
YAHOO.Fp.eyebrow = function(){
document.getElementById(\'ypromo\').style.display=(!YAHOO.Fp.shp||!YAHOO.Fp.scp)?\'block\':\'none\';
document.getElementById(\'dtba\').className=(!YAHOO.Fp.shp)?\'eyebrowborder\':\'\';
document.getElementById(\'sethomepage\').parentNode.style.display=(!YAHOO.Fp.shp)?\'block\':\'none\';
if (document.getElementById(\'toolbar\')) {document.getElementById(\'toolbar\').style.display=(!YAHOO.Fp.scp)?\'block\':\'none\';}
}
YAHOO.Fp.eyebrow();
</script>
<![if !IE]>
<script language="javascript" type="text/javascript">
if(YAHOO.Fp._ff){
var hm=document.getElementById(\'sethomepage\');
hm.href=YAHOO.Fp._ylh+\'r/hq\';
if (typeof(app_c_pp)!=\'undefined\') app_c_pp(\'hpf\',YAHOO.Fp.shp?1:0);
cc=\'&hpf=\'+(YAHOO.Fp.shp?1:0);
hm.style.position = \'relative\';
hm.onclick=function(){
if(!YAHOO.util.Event){
document.location = hm.href;
return;
}
var shpd = document.getElementById(\'shpd\')
if(!shpd){
shpd=document.createElement(\'div\');
shpd.id=\'shpd\';
shpd.className=\'shdw\';
shpd.innerHTML=\'<div class=bd><div id=pnt></div><a title="Yahoo!" class=shp href="http://www.yahoo.com/"><strong>Yahoo!</strong></a><ol><li>Drag the "Y!" and drop it onto the "House" icon.</li><li>Select "Yes" from the pop up window.</li><li>Nothing, you&#39;re done.</li></ol><div class=hr></div><p>If this didn&#39;t work for you or you want more detailed instructions <a href=http://www.yahoo.com/r/hs>click here</a>.</p></div>\';
hm.parentNode.appendChild(shpd);
YAHOO.util.Event.addListener(document, \'click\', function(){document.getElementById(\'shpd\').style.display=\'none\';});
}
shpd.style.display = \'block\';
var bcn=new Image;bcn.src="r/hf";
return false;
}
}
</script>
<![endif]>
</div>
<div id="mastheadbd">
<span class="top"></span>
<h1><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/beta/y3.gif" border=0 width=232 height=44 alt="Yahoo!" id="ylogo"><script language=javascript>if(typeof(YAHOO)!=\'undefined\') {	document.write(\'<map name="yodel"><area shape="rect" coords="209,30,216,39" href="http://www.yahoo.com" onclick="callYodel();return false;"><area shape="poly" coords="211,0,222,1,215,26,211,25" href="http://www.yahoo.com" onclick="callYodel();return false;"></map><div id=l_fl style="position:absolute"></div>\');	var lr0=\'http://us.ard.yahoo.com/SIG=12l7jgil4/M=289534.5461226.11280333.5322130/D=yahoo_top/S=2716149:HEADR/_ylt=A9GDJJbFQUZGdmoBe2f1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4040821/R=0/*\';	var lcap=0,lncap=0,ad_jsl=0,lnfv=6,ylmap=0;	var ldir="http://us.i1.yimg.com/us.yimg.com/i/mntl/ww/06q3/";	var swfl1=ldir+"yodel.swf";	var swflw=1,swflh=1;}function loadYodel(p) {	var sp=(p==1)?[\'FlashVars\',\'startplay=1\']:[\'FlashVars\',\'startplay=0\'];	if(YAHOO.Fp._ie) ad_embedObj(\'swf\',\'l1\',\'l_fl\',swflw,swflh,ad_params(\'object\',[\'movie\',swfl1],[\'quality\',\'autohigh\'],[\'loop\',\'false\'],[\'play\',\'false\'],[\'wmode\',\'transparent\'],sp));	else		ad_embedObj(\'swf\',\'l1\',\'l_fl\',\'\',\'\',ad_params(\'embed\',[\'src\',swfl1],[\'height\',swflh],[\'width\',swflw],[\'quality\',\'autohigh\'],[\'play\',\'false\'],[\'loop\',\'false\'],[\'wmode\',\'transparent\'],sp,[\'type\',\'application/x-shockwave-flash\'],[\'pluginspage\',\'http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash\']));	if(!ylmap) { ad_el(\'ylogo\').useMap=\'#yodel\'; ylmap=1; }}function callYodel() {	var img=new Image;	img.src=\'http://srd.yahoo.com/\'+(lr0?lr0.substring(lr0.indexOf(\'/M=\')+1,lr0.length-5):\'\')+\'N=1/id=yodel/fv=\'+lnfv+\'/\'+Math.random()+\'/*1\';	loadYodel(1);}function yodelCheckFlash() {	if(YAHOO.Fp._ie) document.write(\'<scr\'+\'ipt language=vbscript\\>\\non error resume next\\nlcap=(IsObject(CreateObject("ShockwaveFlash.ShockwaveFlash."&lnfv)))\\n\\</scr\'+\'ipt\\>\\n\');	else {		var plugin=(window.navigator.plugins["Shockwave Flash"])?window.navigator.plugins["Shockwave Flash"].description:0;		if (plugin) {		if (plugin.charAt(plugin.indexOf(\'.\')-1)>=lnfv) lncap=1;		}	}	if (lcap||lncap)return true;	else return false;}</script><script language="javascript" type="text/javascript" src="http://us.js2.yimg.com/us.yimg.com/a/1-/java/promotions/js/ad_eo_1.1.js"></script><script language=javascript>if(typeof(YAHOO)!=\'undefined\'&&ad_jsl&&yodelCheckFlash()) { 	if (window.attachEvent) window.attachEvent(\'onload\', loadYodel);	else if (window.addEventListener) window.addEventListener(\'load\', loadYodel, 0);}</script><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'OpavKNGDJG4-\']=\'&U=13bdgq63b%2fN%3dOpavKNGDJG4-%2fC%3d289534.5461226.11280333.5322130%2fD%3dHEADR%2fB%3d4040821\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142rb3biv%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d3439803234%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13bdgq63b%2fN%3dOpavKNGDJG4-%2fC%3d289534.5461226.11280333.5322130%2fD%3dHEADR%2fB%3d4040821"></noscript></h1>
<div id="searchwrapper">
<div id="searchIE">
</div>
<img src="http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/search_1.1.png" id="searchother" alt=""><form name="sf1" id="search" action="r/sx/*-http://search.yahoo.com/search">
<fieldset>
<legend>Yahoo! Search</legend>
<ul id="vsearchtabs"><li class="first on"><a href="r/sx/*-http://search.yahoo.com/search">Web</a></li><li><a href="r/00/*-http://images.search.yahoo.com/search/images">Images</a></li><li><a href="r/14/*-http://video.search.yahoo.com/search/video">Video</a></li><li><a href="r/0w/*-http://local.yahoo.com/results;_ylc=X3oDMTEwNTByOW5sBF9TAzI3MTYxNDkEc2VjA2ZwLXRhYgRzbGsDc3Bpcml0">Local</a></li><li><a href="r/06/*-http://shopping.yahoo.com/search;_ylc=X3oDMTEwNTByOW5sBF9TAzI3MTYxNDkEc2VjA2ZwLXRhYgRzbGsDc3Bpcml0">Shopping</a></li><li class="last ignore"><dl id="vsearchm"><dt><a id="vsearchmore" href="r/bv">More</a></dt><dd id="vslist"></dd></dl></li></ul>
<div id="sbox">
<label id="searchlabel" for="p">Search:</label>
<div id="searchbox">
<input class="plong inputtext" type="text" id="p" name="p" accesskey="s">
</div>
<span id="searchbtn">
<input type="submit" id="searchsubmit" class="btn-more-2" value="Web Search">
</span>
<noscript><input name="u" type="hidden" value="http://search.yahoo.com/search?fr=yfp-t&p="></noscript>
<input type="hidden" name="fr" value="yfp">
<input type="hidden" name="toggle" value="1">
<input type="hidden" name="cop" value="mss">
<input type="hidden" name="ei" value="UTF-8">
<script language="javascript">
document.sf1.p.focus();
document.sf1.action = "r/sx/*-http://search.yahoo.com/search";
YAHOO.Fp.sFrPrefix = document.sf1.fr.value;
document.sf1.fr.value = frcode;
</script>
</div>
<div id="sboxfooter">
</div>
</fieldset>
</form>
</div>
<script type="text/javascript">
now=new Date;
t3=now.getTime();
</script>
<div class="mh_footer">
<div id="doors" class="hd">
<h3 class="a11y">Popular Yahoo! Properties</h3>
<ul id="doors-links" class="fixfloat">
<li><strong><a href="r/i1" title="Go to My Yahoo!">My Yahoo!</a></strong></li><!-- SpaceID=2716149 loc=FDMY noad -->
<li><strong><a href="r/m1" title="Go to Yahoo! Mail">My Mail</a></strong></li>
</ul>
</div>
<div id="pagesettingscx">
<a href="r/tp" id="editpage">Page Options</a>
<div id="pagesettings">
<div class="bd">
<span>
<div class="iemw"></div>
<div id="pscolors">
<h4>Color:</h4>
<ol id="themes">
<li><a id="t1" class="on" title="Ocean">Ocean</a></li>
<li><a id="t4"  title="Tangerine">Tangerine</a></li>
<li><a id="t3"  title="Violet">Violet</a></li>
<li><a id="t2"  title="Oyster">Oyster</a></li>
<li><a id="t5"  title="Grass">Grass</a></li>
<li><a id="t7"  title="Pink">Pink</a></li>
</ol>
</div>
<a id="sizetogglelink" href="r/ty">Switch to narrow layout</a>
</span>
</div>
</div>
</div>
</div>
</div>
<div id="mastheadft"></div>
</div>
<div id="colcx">
<div id="left">
<div id="trough" class="md">
<div class="bd">
<div id="trough-cols" class="fixfloat">
<ul id="trough-1" class="col1">
<li><a style="background-position:-400px -120px" href="r/4d">Answers<small class="updated"><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/sp/updated.gif"></small>
</a></li>
<li><a style="background-position:-400px -440px" href="r/2h">Autos</a></li>
<li><a style="background-position:0 -761px" href="r/25">Finance</a></li>
<li><a style="background-position:0 -1600px" href="r/28">Games</a></li>
<li><a style="background-position:0 -199px" href="r/44">GeoCities</a></li>
<li><a style="background-position:0 -1400px" href="r/2r">Groups</a></li>
<li><a style="background-position:0 -439px" href="r/3o">HotJobs</a></li>
<li><a style="background-position:0 -600px" href="r/24">Maps</a></li>
<li><a style="background-position:0 -559px" href="r/2i">Movies</a></li>
<li><a style="background-position:0 -1560px" href="r/3m">Music</a></li>
<li><a style="background-position:0 -40px" href="r/33">Personals</a></li>
<li><a style="background-position:-400px -159px" href="r/2p">Real Estate</a></li>
<li><a style="background-position:0 -1640px" href="r/2q">Shopping</a></li>
<li><a style="background-position:0 -800px" href="r/26">Sports</a></li>
<li><a style="background-position:-400px -241px" href="r/4c">Tech</a></li>
<li><a style="background-position:0 -79px" href="r/29">Travel<small class="updated"><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/sp/updated.gif"></small>
</a></li>
<li><a style="background-position:0 -1000px" href="r/2j">TV</a></li>
<li><a style="background-position:0 -121px" href="r/2k">Yellow Pages</a></li>

</ul>

<ul class="col1 trough-promo" id="trough-promo">
<li class="first"><a style="background-position: 0 -161px;" href=r/3a>Mobile Web<small class="new"><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/sp/new.gif" /></small></a></li>
</ul>
</div>
<span id="allyservicescx">
<a href="r/xy" id="allyservices" class="btn-more-2" title="View the complete list of Yahoo! Services">More Yahoo! Services</a>
</span>
</div>
</div>
<div id="minimantle" class="md minimantle">
<div id="smallbiz" class="md-sub">
<div class="hd"><h2><a href="r/c9">Small Business</a></h2></div>
<ul id="smallbiz-links">
<li><a href="r/h9">Get a Web Site</a></li>
<li><a href="r/d9">Domain Names</a></li>
<li><a href="r/e9">Sell Online</a></li>
<li><a href="r/o9">Search Ads</a></li>
</ul>
</div>
</div>
<div class="md minimantle">
<div id="advertising" class="md-sub">
<div class="hd"><h2><a href="r/b9">Featured Services</a></h2></div>
<ul id="advertising-links">
<li><a href="r/do">Downloads</a><!-- SpaceID=2716149 loc=TST1 noad-spid -->
</li>
<li><a href="r/wp">Health</a></li>
<li><a href="r/k3">Kids</a></li>
<li><a href="r/dh">Photos</a></li>
<li><a href="r/fb">Voice</a></li>
<li><a href="http://us.ard.yahoo.com/SIG=12ja82rav/M=387958.8166811.9095675.3595621/D=yahoo_top/S=2716149:FPC1/_ylt=A9GDJJbFQUZGdmoBfGf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=3455571/R=0/SIG=10t7f96oc/*http://promo.yahoo.com/att/">AT&T Y! HighSpeed</a><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'PZavKNGDJG4-\']=\'&U=139rn5edm%2fN%3dPZavKNGDJG4-%2fC%3d387958.8166811.9095675.3595621%2fD%3dFPC1%2fB%3d3455571\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142vdspfu%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d1375152928%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=139rn5edm%2fN%3dPZavKNGDJG4-%2fC%3d387958.8166811.9095675.3595621%2fD%3dFPC1%2fB%3d3455571"></noscript></li>
<li><a href="r/wr">Y! International</a></li>
</ul>
</div>
</div>
</div>
<div id="rightcx">
<div id="middle">
<div class="colpadding">
<div id="today" class="md">
<div class="hd tabs">
<h3 class="a11y">Featured Navigation</h3>
<ul id="todaytabs">
<li class="on first">
<em><a hidefocus="true" id="featured1" href="r/tj">Featured</a></em>
<span class="pipe"></span>
</li>
<li class="tab2">
<em><a hidefocus="true" id="entertainment1" href="r/e8">Entertainment</a></em>
<span class="pipe"></span>
</li>
<li class="tab3">
<em><a hidefocus="true" id="sports1" href="r/sm">Sports</a></em>
<span class="pipe"></span>
</li>
<li class="last">
<em><a hidefocus="true" id="money1" href="r/wq">Life</a></em>
<span class="pipe"></span>
</li>
</ul>
</div>
<div id="todaybd" class="bd">
<span id="featured1ct" class="current">
<cite class="timestamp">&nbsp;</cite>
<a href=s/579954><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/news/2007/05/12/mombig.jpg" width="154" height="115" alt="Daring dates for moms (Corbis)"></a>
<span>
<h3><a href=s/579955>Experimental dates for moms</a></h3>
<p>Why should single moms make dating like a lab experiment? <a class=more href=s/579955>&#187; Find out</a></p>
<ul>
<li><a class=bullet href=s/579956>He\'s separated &#151; is he OK to date?</a></li>
<li><a class=bullet href=s/579957>How to avoid rebound dating</a></li>
<li><a class=bullet href=s/579979>Younger women, older men?</a></li>
</ul>
</span>
</span>
<span id="featured2ct">
</span>
<span id="featured3ct">
</span>
<span id="featured4ct">
</span>
<span id="entertainment1ct">
</span>
<span id="entertainment2ct">
</span>
<span id="entertainment3ct">
</span>
<span id="entertainment4ct">
</span>
<span id="sports1ct">
</span>
<span id="sports2ct">
</span>
<span id="sports3ct">
</span>
<span id="sports4ct">
</span>
<span id="money1ct">
</span>
<span id="money2ct">
</span>
<span id="money3ct">
</span>
<span id="money4ct">
</span>
</div>
<div id="todayft" class="ft">
<span id="footer1" class="current">
<ul id="todaystories1">
<li id="featured1|344" class="on"><a href=s/579980><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/news/2007/05/12/momsmall.jpg" alt="" width="29" height="21">Why should moms go on experimental dates?</a></li>
<li id="featured2|284"><a href=s/579806><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/news/2007/05/11/portlandskyline-sm.jpg" alt="" width="29" height="21">Where home prices are hot now</a></li>
</ul>
<ul>
<li id="featured3|345"><a href=s/579984><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/news/2007/05/12/0512paris2_crop.jpg" alt="" width="29" height="21">Is Paris Hilton too pretty for prison?</a></li>
<li id="featured4|335"><a href=s/579945><img src="http://us.i1.yimg.com/us.yimg.com/i/ww/news/2007/05/12/sambrett_thumb.jpg" width="29" height="21" alt="">Presidential hopeful booed for dissing Favre</a></li>
</ul>
<div id="more-featured" class="btn-more"><b>&#187;
<a href=r/tm>More Featured</a></b></div>
</span>
<span id="footer2">
</span>
<span id="footer3">
</span>
<span id="footer4">
</span>
</div>
</div>
<div id="adwest" class="ad">
</div>
<script type="text/javascript">now=new Date;t5=now.getTime();</script>
<div id="news" class="md">
<div class="hd tabs">
<h3 class="a11y">News Navigation</h3>
<ul id="newstabs">
<li class="on first">
<em><a hidefocus="true" id="inthenews2" href="r/nb">In the News</a></em>
<span class="pipe"></span>
</li>
<li class="tab2">
<em><a hidefocus="true" id="worldnews" href="r/1a">World</a></em>
<span class="pipe"></span>
</li>
<li class="tab3">
<em><a hidefocus="true" id="localnews" href="r/n4">Local</a></em>
<span class="pipe"></span>
</li>
<li class="last">
<em><a hidefocus="true" id="videonews" href="r/1b">Video</a></em>
<span class="pipe"></span>
</li>
</ul>
</div>
<div id="newsbd" class="bd">
<span id="inthenews2ct" class="current">
<h2 class="a11y">In the News</h2>
<div id="newstop">
<cite class="timestamp">&nbsp;</cite>
&#149;&nbsp;<a href=s/579850>Three missing after deadly attack on U.S. patrol in Iraq</a><br>&#149;&nbsp;<a href=s/579790>Cheney seeks Saudi Arabia\'s support on Iraq war strategy</a><br>&#149;&nbsp;<a href=s/579967>Israel probes complaints from Lebanon peace force</a><br>&#149;&nbsp;<a href=s/579892>Edwards offers students anti-war advice</a><dl class="inline"><dt><a href=s/534727>Campaign \'08</a></dt></dl><br>&#149;&nbsp;<a href=s/579933>Holocaust survivor refuses to meet with son</a><br>&#149;&nbsp;<a href=s/579947>Justice Dept. goes after online gambling in Utah</a><dl class="inline"><dt><a class=video href=s/579953 onclick="window.open(\'s/579953\',\'playerWindow\',\'width=793,height=608,scrollbars=no\');return false;">Case</a></dt></dl><br>&#149;&nbsp;<a href=s/579948>Bode Miller\'s cousin kills officer, then is killed by passer-by</a><br>
&#149;&nbsp;<a href=s/379501>MLB</a>  &#183;
<a href=s/404909>NBA Playoffs</a> &#183;
<a href=s/404910>NHL Playoffs</a> &#183;
<a href=s/379500>Tennis</a> &#183;
<a href=s/380904>Soccer</a><br>
<ul id="more-news" class="btn-more"><li class="first"><b>&#187;</b> More:</li><li><a href=r/xn>News</a></li><li><a href=r/me>Popular</a></li><li class="last"><a href=r/vb>Business</a></li></ul>
</div>
<div id="newsft">
<div id="newsbottom">
<div id="finance-data">
<div id="markets"><h3><a href="r/f3">Markets:</a></h3><ul><li><strong>Dow: <span class="up">+0.8%</span></strong></li><li><strong>Nasdaq: <span class="up">+1.1%</span></strong></li></ul></div><script language="javascript" type="text/javascript">document.getElementById("news").className="md afterhours";</script></div>
<div id="news-sponsor">
<style type="text/css">#news-sponsor img{position:relative;display:block;margin:0;}#news.afterhours #news-sponsor img{display:inline;position:relative;top:10px;}<style type="text/css">#news-sponsor img{position:relative;display:block;margin:0;}#news.afterhours #news-sponsor img{display:inline;position:relative;top:10px;}</style><a href="http://us.ard.yahoo.com/SIG=12lfs7a17/M=579773.10267568.11202284.9498165/D=yahoo_top/S=2716149:STCK/_ylt=A9GDJJbFQUZGdmoBfWf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4344100/R=0/SIG=115dhte9i/*http://www.scottrade.com/?cid=16229"><img src="http://us.a2.yimg.com/us.yimg.com/a/1-/flash/promotions/scottrade/070108/scottrade_165x15_logo.gif" border=0 width=165 height=15 title="Open a no-fee IRA at Scottrade"></a><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'PpavKNGDJG4-\']=\'&U=13bdjae4a%2fN%3dPpavKNGDJG4-%2fC%3d579773.10267568.11202284.9498165%2fD%3dSTCK%2fB%3d4344100\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142fclp40%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d2920559397%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13bdjae4a%2fN%3dPpavKNGDJG4-%2fC%3d579773.10267568.11202284.9498165%2fD%3dSTCK%2fB%3d4344100"></noscript></div>
</div>
</div>
</span>
<span id="worldnewsct">
</span>
<span id="localnewsct">
</span>
<span id="videonewsct" class="single-panel">
</span>
</div>
</div>
<script type="text/javascript">now=new Date;t6=now.getTime();</script>
<div id="marketplace" class="md">
<div class="hd">
<h2><a href="r/0v" name="marketplace">Marketplace</a></h2>
</div>
<div id="marketplacebd" class="bd">
<table border=0 cellpadding=0 cellspacing=0 width="100%"><tr><td valign=top><a href="http://us.ard.yahoo.com/SIG=12jppuqne/M=567956.9724517.11317181.9365916/D=yahoo_top/S=2716149:MKP/_ylt=A9GDJJbFQUZGdmoBfmf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4585695/R=0/SIG=12j56rtte/*http://www.freecreditreport.com/pm/default.aspx?sc=658900&bcd=FPSAT0512cmboexpscr"><img src="http://us.a2.yimg.com/us.yimg.com/a/1-/flash/promotions/consumerinfo/070512/70x50iltlA.gif" width=70 height=50 border=0></a></td><td width=8>&nbsp;</td><td valign=top><font face=arial size=-1><a href="http://us.ard.yahoo.com/SIG=12jppuqne/M=567956.9724517.11317181.9365916/D=yahoo_top/S=2716149:MKP/_ylt=A9GDJJbFQUZGdmoBfmf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4585695/R=1/SIG=12j56rtte/*http://www.freecreditreport.com/pm/default.aspx?sc=658900&bcd=FPSAT0512cmboexpscr">What\'s your credit score 560? 720?</a><br>The average U.S. credit score is 675. <a href="http://us.ard.yahoo.com/SIG=12jppuqne/M=567956.9724517.11317181.9365916/D=yahoo_top/S=2716149:MKP/_ylt=A9GDJJbFQUZGdmoBfmf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4585695/R=2/SIG=12j56rtte/*http://www.freecreditreport.com/pm/default.aspx?sc=658900&bcd=FPSAT0512cmboexpscr">See yours for $0. By Experian</a>.</font></td></tr></table><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'P5avKNGDJG4-\']=\'&U=139gfna0c%2fN%3dP5avKNGDJG4-%2fC%3d567956.9724517.11317181.9365916%2fD%3dMKP%2fB%3d4585695\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=141qanirm%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d651205322%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=139gfna0c%2fN%3dP5avKNGDJG4-%2fC%3d567956.9724517.11317181.9365916%2fD%3dMKP%2fB%3d4585695"></noscript><hr size=1 noshade><a href="http://us.ard.yahoo.com/SIG=12l117iao/M=573849.10109950.11302921.8855218/D=yahoo_top/S=2716149:MKP1/_ylt=A9GDJJbFQUZGdmoBf2f1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4578145/R=0/SIG=150533jd7/*http://www.classesusa.com/clickcount.cfm?id=867374&goto=http%3A%2F%2Fwww.classesusa.com%2Ffeaturedschools%2Fonlinedegreesmp%2Fform-dyn1.html%3Fsplovr%3D867372">Don&#146;t have enough time to go back to school?</a> - Earn your AS, BS, or MS degree online in 1 year - <a href="http://us.ard.yahoo.com/SIG=12l117iao/M=573849.10109950.11302921.8855218/D=yahoo_top/S=2716149:MKP1/_ylt=A9GDJJbFQUZGdmoBf2f1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4578145/R=1/SIG=150533jd7/*http://www.classesusa.com/clickcount.cfm?id=867374&goto=http%3A%2F%2Fwww.classesusa.com%2Ffeaturedschools%2Fonlinedegreesmp%2Fform-dyn1.html%3Fsplovr%3D867372">Start now</a>.<script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'QJavKNGDJG4-\']=\'&U=13bct3ls1%2fN%3dQJavKNGDJG4-%2fC%3d573849.10109950.11302921.8855218%2fD%3dMKP1%2fB%3d4578145\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=1426bok11%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d4111886255%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13bct3ls1%2fN%3dQJavKNGDJG4-%2fC%3d573849.10109950.11302921.8855218%2fD%3dMKP1%2fB%3d4578145"></noscript><hr size=1 noshade><a href="http://us.ard.yahoo.com/SIG=12l45tv2v/M=571699.10029847.11302691.8855218/D=yahoo_top/S=2716149:MKP1/_ylt=A9GDJJbFQUZGdmoBgGf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4578060/R=0/SIG=12fjgc2v0/*http://www.lowermybills.com/lre/index.jsp?sourceid=lmb-10443-19484&moid=14888">Mortgage rates fall again. $430,000 for $1299/mo. Think you pay too much? Calculate next payment</a>.<script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'QZavKNGDJG4-\']=\'&U=13bged65i%2fN%3dQZavKNGDJG4-%2fC%3d571699.10029847.11302691.8855218%2fD%3dMKP1%2fB%3d4578060\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142p91utc%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d1823140651%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13bged65i%2fN%3dQZavKNGDJG4-%2fC%3d571699.10029847.11302691.8855218%2fD%3dMKP1%2fB%3d4578060"></noscript><hr size=1 noshade>  <div id="infinityad">     <a href="http://us.ard.yahoo.com/SIG=12lal42vr/M=574569.10473962.11203451.8855218/D=yahoo_top/S=2716149:MKP1/_ylt=A9GDJJbFQUZGdmoBgWf1cSkA;_ylg=X3oDMTBrbWNyNnF0BGZwdF91cHMDMQRmcHRfYWQDMC45/Y=YAHOO/EXP=1179016677/A=4437960/R=0/SIG=111j751i2/*http://get.games.yahoo.com/home">Try Yahoo! Games Downloads today</a> - One hour free game play.    </div><script>YAHOO.Fp.infinity = function(){var zSr;var aUrl=[];aUrl.push("http://xpcs.ads.yahoo.com/");aUrl.push("a?p=front_page&csty=n1OV&csprof=fpm_js&pos=ST&csurl=http://www.yahoo.com&ad-p=yahoo_marketplace_ctxt&js-array=1");aUrl.push("&");aUrl.push(Math.floor(Math.random() * 100000));YAHOO.Fp.dod(aUrl.join(""));setTimeout("YAHOO.Fp.dod(\'http://us.js2.yimg.com/us.js.yimg.com/a/ya/yahoo2/frontpagemarket_022807.js\')",300);}</script><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'QpavKNGDJG4-\']=\'&U=13bemg8pr%2fN%3dQpavKNGDJG4-%2fC%3d574569.10473962.11203451.8855218%2fD%3dMKP1%2fB%3d4437960\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=140sefmki%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d87663397%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13bemg8pr%2fN%3dQpavKNGDJG4-%2fC%3d574569.10473962.11203451.8855218%2fD%3dMKP1%2fB%3d4437960"></noscript></div>
</div>
<script type="text/javascript">now=new Date;t7=now.getTime();</script>
</div>
</div>
<div id="right">
<div class="colpadding">
<div id="pa" class="md">
<div id="pabd">
<div id="patop">

<ul id="reg" class="so">
<li>Check your mail status: <a href="r/l6">Sign In</a></li>
<li id="signup">Free mail: <a href="r/m7">Sign Up</a></li>
</ul>
</div>
<div id="patabs">
<ul id="tabs1" class="patabs first">
<li id="mail" class="first">
<div>
<h4>
<a id="pamail" accesskey="m" href="r/m2"><span class="icon">Mail</span></a></h4>
</div>
</li>
<li id="messenger">
<div>
<h4>
<a id="pamsgr" href="r/p1"><span class="icon">Messenger</span></a>
</h4>
</div>
</li>
<li id="music" class="last">
<div>
<h4>
<a id="pamusic" href="r/uf"><span class="icon">Radio</span></a>
</h4>
</div>
</li>
</ul>
<div id="tabs1previewdiv" class="papreviewdiv"></div>
<ul id="tabs2" class="patabs last">
<li id="weather" class="first">
<div>
<h4>
<a id="paweather" href="r/wa"><span class="icon">Weather</span></a></h4>
</div>
</li>
<li id="traffic">
<div>
<h4>
<a id="patraffic" href="r/0z"><span class="icon">Local</span></a>
</h4>
</div>
</li>
<li id="horoscope" class="last">
<div>
<h4>
<a id="pahoroscope" href="r/h1"><span class="icon">Horoscopes</span></a>
</h4>
</div>
</li>
</ul>
<div id="tabs2previewdiv" class="papreviewdiv"></div>
</div>
</div>
</div>
<script type="text/javascript">
now=new Date;
t8=now.getTime();
</script>
<div id="ad" class="ad">
<style type="text/css">	#ad { min-height:198px; _height:198px; text-align:center; border:1px solid #91a8b4; position:relative; background:#fff;}	#ad #ad_hea {background:#fff;width:100%;text-align:left;}	#ad h2 {background:url(http://us.i1.yimg.com/us.yimg.com/i/mntl/ga/07q2/hea_0300.gif) 5px 5px no-repeat; height:30px; text-indent:-5000px; width:260px; }	#ad #ad_hea h2 a {font:77% verdana;}	#ad #ad_hea h2 a.hea {float:left; height:15px;width:115px;margin:3px 0 0 3px;}	#ad #ad_hea h2 a.sub_hea {float:right;font:77% verdana; width:115px; height:15px;margin:3px 10px 0 0}	#ad #ad_con {width:100%;min-height:150px; _height:145px;background:#e1fe94;}	#ad #ad_con .col {float:left;}	#ad #ad_con #first{width:50%;_width:50.5%;margin:2px 0;border-right:1px solid #fff;}	#ad #ad_con #second {width:45%;_width:45%;}	#ad #ad_con ul {font:77% verdana;zoom:1;padding:2px 0 5px 5px;text-align:left;}    #ad #ad_con ul li {padding-left:6px; background:url(http://us.i1.yimg.com/us.yimg.com/i/nt/gr/li/2x2/003399.gif) 2px .6em no-repeat;}	#ad #ad_ft {background:#a4d475; height:20px;width:100%;}	#ad #ad_con .col:after {content:"."; display:block; font-size:0px; line-height:0px; height:0; clear:both; visibility:hidden;}</style><div id="ad_hea"><h2><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=0/SIG=114uhnlu9/*http://games.yahoo.com/games/front" class="hea">Yahoo! Games -</a> <a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=1/SIG=112mta7g7/*http://games.yahoo.com/downloads" class="sub_hea">Download and Play</a></h2></div><div id="ad_con"><img src="http://us.i1.yimg.com/us.yimg.com/i/mntl/ga/07q2/img_0300.jpg" width="348" height="86" alt="" id="mimg" usemap="#m_gam"><map name="m_gam"><area alt="Dream Day Wedding" coords="1,2,85,85" href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=2/SIG=11tp26ogb/*http://get.games.yahoo.com/proddesc?gamekey=dreamdaywedding"><area alt="Ravenhearst" coords="87,0,174,85" href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=3/SIG=11phe9mqb/*http://get.games.yahoo.com/proddesc?gamekey=ravenhearst"><area alt="Kudos" coords="176,1,262,84" href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=4/SIG=11j1iliag/*http://get.games.yahoo.com/proddesc?gamekey=kudos"><area alt="Bookworm" coords="265,1,350,86" href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=5/SIG=1201p1eu2/*http://get.games.yahoo.com/proddesc?gamekey=bookwormadventures"></map><div id="first" class="col">	<ul>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=6/SIG=11tp26ogb/*http://get.games.yahoo.com/proddesc?gamekey=dreamdaywedding">Dream Day Wedding</a></li>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=7/SIG=11phe9mqb/*http://get.games.yahoo.com/proddesc?gamekey=ravenhearst">MCF: Ravenhearst</a></li>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=8/SIG=11j1iliag/*http://get.games.yahoo.com/proddesc?gamekey=kudos">Kudos</a></li>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=9/SIG=1201p1eu2/*http://get.games.yahoo.com/proddesc?gamekey=bookwormadventures">Bookworm Adventures</a></li>	</ul>	</div>	<div id="second" class="col">	<ul>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=10/SIG=11ochl79e/*http://get.games.yahoo.com/proddesc?gamekey=ghscrabble">Scrabble</a></li>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=11/SIG=11omonvij/*http://get.games.yahoo.com/proddesc?gamekey=dinerdash3">Diner Dash 3</a></li>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=12/SIG=1201bephg/*http://get.games.yahoo.com/proddesc?gamekey=carriethecaregiver">Carrie the Caregiver</a></li>		<li><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=13/SIG=11ppqqjft/*http://get.games.yahoo.com/proddesc?gamekey=jewelquest2">Jewel Quest 2</a></li>	</ul>	</div></div><div id="ad_ft"><a href="http://us.ard.yahoo.com/SIG=12lie2fcg/M=545301.10615248.11227113.7674020/D=yahoo_top/S=2716149:FPAD/_ylt=A9GDJJbFQUZGdmoBgmf1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4545738/R=14/SIG=112mta7g7/*http://games.yahoo.com/downloads" class="btn-more">&#187; More Games</a></div><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'Q5avKNGDJG4-\']=\'&U=13b1b01li%2fN%3dQ5avKNGDJG4-%2fC%3d545301.10615248.11227113.7674020%2fD%3dFPAD%2fB%3d4545738\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=1421gci7k%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d3021105922%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13b1b01li%2fN%3dQ5avKNGDJG4-%2fC%3d545301.10615248.11227113.7674020%2fD%3dFPAD%2fB%3d4545738"></noscript></div>
<script type="text/javascript">
now=new Date;
t9=now.getTime();
</script>
<div id="mantlecx">
<div id="mantle">
<style>#mantle2 {min-height:103px;_height:103px;}#mantle2 .bd {position:relative; padding-left:115px;}#mantle2 .bd img {position:absolute; top: 6px; left: 10px; margin:0; padding:1px;border:1px solid #9cafbd;border-color:#9cafbd #9cafbd #647684 #647684;}#mantle2 p {font:100% arial; height:3em; color:#666;}	#mantle2 h3 {color:#057e14;font:bold 100% arial; margin-bottom:2px;}#mantle2 ul {font:77% verdana; height:4em;_height:4.5em; margin:0 0 .5em}#mantle2 h2 em {color:#057e14}</style>	<div id="mantle2" class="md"><div class="hd"><h2><a href="http://us.ard.yahoo.com/SIG=12l5tfoot/M=592793.10705396.11321364.1508716/D=yahoo_top/S=2716149:MNTL/_ylt=A9GDJJbFQUZGdmoBg2f1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4588586/R=0/*http://answers.yahoo.com/;_ylc=X3oDMTI0MGFpMm5wBF9TAzIxMTU1MDAzNTIEX3MDMzk2NTQ1MTAzBHNlYwNCQUJwaWxsYXJfRlBta3RnBHNsawNQcm9kdWN0X2hvbWVwYWdl">Be a Better <em>Weekend Warrior</em></a></h2></div><div class="bd"><a href="http://us.ard.yahoo.com/SIG=12l5tfoot/M=592793.10705396.11321364.1508716/D=yahoo_top/S=2716149:MNTL/_ylt=A9GDJJbFQUZGdmoBg2f1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4588586/R=1/*http://us.lrd.yahoo.com/_ylc=X3oDMTI2aGZvYTk2BF9TAzIxMTU1MDAzNTIEX3MDMjExNTUwMDMzMwRzZWMDQkFCcGlsbGFyX0ZQbWt0ZwRzbGsDQkFCTWljcm9zaXRlX21haW4-/SIG=1146ba1ri/**http%3A//better.yahoo.com/answers"><img src="http://l.yimg.com/us.yimg.com/i/mntl/srch/07q2/img_070507.jpg" width="92" height="68" alt="Yahoo! Answers"></a><h3>Answers to Weekend Questions</h3><ul><li><a href="http://us.ard.yahoo.com/SIG=12l5tfoot/M=592793.10705396.11321364.1508716/D=yahoo_top/S=2716149:MNTL/_ylt=A9GDJJbFQUZGdmoBg2f1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4588586/R=2/*http://answers.yahoo.com/question/index;_ylc=X3oDMTI5N25zZDhlBF9TAzIxMTU1MDAzNTIEX3MDMzk2NTQ1MTAzBHNlYwNCQUJwaWxsYXJfRlBta3RnBHNsawNQcm9kdWN0X3F1ZXN0aW9uX3BhZ2U-?qid=20070325235840AAui3d6">How can I stop burning food on a grill?</a></li><li><a href="http://us.ard.yahoo.com/SIG=12l5tfoot/M=592793.10705396.11321364.1508716/D=yahoo_top/S=2716149:MNTL/_ylt=A9GDJJbFQUZGdmoBg2f1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4588586/R=3/*http://answers.yahoo.com/question/index;_ylc=X3oDMTI5N25zZDhlBF9TAzIxMTU1MDAzNTIEX3MDMzk2NTQ1MTAzBHNlYwNCQUJwaWxsYXJfRlBta3RnBHNsawNQcm9kdWN0X3F1ZXN0aW9uX3BhZ2U-?qid=20060709065406AAg2MSx">What are great party foods for kids?</a></li><li><a href="http://us.ard.yahoo.com/SIG=12l5tfoot/M=592793.10705396.11321364.1508716/D=yahoo_top/S=2716149:MNTL/_ylt=A9GDJJbFQUZGdmoBg2f1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4588586/R=4/*http://answers.yahoo.com/question/index;_ylc=X3oDMTI5N25zZDhlBF9TAzIxMTU1MDAzNTIEX3MDMzk2NTQ1MTAzBHNlYwNCQUJwaWxsYXJfRlBta3RnBHNsawNQcm9kdWN0X3F1ZXN0aW9uX3BhZ2U-?qid=20061117140704AAfGGAy">What&#39;s an easy breakfast tailgate idea?</a></li></ul></div><a href="http://us.ard.yahoo.com/SIG=12l5tfoot/M=592793.10705396.11321364.1508716/D=yahoo_top/S=2716149:MNTL/_ylt=A9GDJJbFQUZGdmoBg2f1cSkA;_ylg=X3oDMTEwZjJhMm9yBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42/Y=YAHOO/EXP=1179016677/A=4588586/R=5/*http://us.lrd.yahoo.com/_ylc=X3oDMTI2aGZvYTk2BF9TAzIxMTU1MDAzNTIEX3MDMjExNTUwMDMzMwRzZWMDQkFCcGlsbGFyX0ZQbWt0ZwRzbGsDQkFCTWljcm9zaXRlX21haW4-/SIG=1146ba1ri/**http%3A//better.yahoo.com/answers" class="btn-more">&#187; Ready to get answers?</a></div><script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'RJavKNGDJG4-\']=\'&U=13bvc1j3p%2fN%3dRJavKNGDJG4-%2fC%3d592793.10705396.11321364.1508716%2fD%3dMNTL%2fB%3d4588586\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142m93ksm%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d1707598789%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=13bvc1j3p%2fN%3dRJavKNGDJG4-%2fC%3d592793.10705396.11321364.1508716%2fD%3dMNTL%2fB%3d4588586"></noscript></div>
</div>
<style type="text/css">#pulse h3{font:bold 114% arial;text-align:left;color:#555;margin-bottom:6px;}#pulse .bd{padding:9px 10px 1.2em 10px;}	#pulse img{float:left;margin:0px;padding:1px; border:1px solid #9cafbd;border-color:#9cafbd #9cafbd #647684 #647684;}#pulse ol{float: left;width:13em;margin-left:5px;}#pulse li{padding-left:18px;margin-bottom:8px;font:normal 77%/100% verdana;padding-left: 8px; background:url(http://us.i1.yimg.com/us.yimg.com/i/nt/gr/li/2x2/003399.gif) 2px 50% no-repeat}#pulse li a {font-weight:bold;}</style><div id="pulse" class="md"><div class="hd"><h2>Pulse - What Yahoos Are Into</h2></div><div id="pulsebd" class="bd"><h3>Wildlife Watch: Popular Animal Videos</h3><a href=s/576035/**http://video.yahoo.com/video/play?vid=378547&cache=1><img src="http://us.i1.yimg.com/us.yimg.com/i/us/sch/cn/vid/img/otters6k.jpg" alt="Otter-ly Adorable" width="139" height="119"></a><ol><li class="tt1"><a href=s/576035/**http://video.yahoo.com/video/play?vid=378547&cache=1>Otter-ly Adorable</a></li><li class="tt2"><a href=s/576036/**http://video.yahoo.com/video/play?vid=119361>Monkey Scare</a></li><li class="tt3"><a href=s/576037/**http://video.yahoo.com/video/play?vid=316104>Lion Kisses Rescuer</a></li><li class="tt4"><a href=s/576038/**http://video.yahoo.com/video/play?vid=325423>Amazing Turtle Encounter</a></li><li class="tt5"><a href=s/576039/**http://video.yahoo.com/video/play?vid=216903>Baby Rabbits</a></li><li class="tt6"><a href=s/576040/**http://video.yahoo.com/video/play?vid=116509>Incredible Fishing Video</a></li></ol></div><a class=btn-more href=s/576041/**http://video.yahoo.com/>&#187; More Videos</a></div><div id="popsearch" class="md">
  <div class="hd"><h2>Today&#039;s Search Highlights</h2></div>
  <div id="popsearchbd" class="bd">
    <ol><li class="tt1"><a href="r/dy/*-http://search.yahoo.com/search?p=Eurovision+Song+Contest&cs=bz&fr=fp-buzzmod">Eurovision Song Contest</a></li>

<li class="tt2"><a href="r/dy/*-http://search.yahoo.com/search?p=jamestown&cs=bz&fr=fp-buzzmod">Jamestown</a></li>

<li class="tt3"><a href="r/dy/*-http://search.yahoo.com/search?p=georgia+rule&cs=bz&fr=fp-buzzmod">Georgia Rule</a></li>

<li class="tt4"><a href="r/dy/*-http://search.yahoo.com/search?p=mother%E2%80%99s+day+recipes&cs=bz&fr=fp-buzzmod">Mother?s Day Recipes</a></li>

<li class="tt5"><a href="r/dy/*-http://search.yahoo.com/search?p=lily+allen&cs=bz&fr=fp-buzzmod">Lily Allen</a></li>

</ol><ol><li class="tt6"><a href="r/dy/*-http://search.yahoo.com/search?p=tiger+shark+images&cs=bz&fr=fp-buzzmod">Tiger Shark Images</a></li>

<li class="tt7"><a href="r/dy/*-http://search.yahoo.com/search?p=isabella+blow&cs=bz&fr=fp-buzzmod">Isabella Blow</a></li>

<li class="tt8"><a href="r/dy/*-http://search.yahoo.com/search?p=fantastic+four+2&cs=bz&fr=fp-buzzmod">Fantastic Four 2</a></li>

<li class="tt9"><a href="r/dy/*-http://search.yahoo.com/search?p=steve+nash&cs=bz&fr=fp-buzzmod">Steve Nash</a></li>

<li class="tt10"><a href="r/dy/*-http://search.yahoo.com/search?p=csi&cs=bz&fr=fp-buzzmod">CSI</a></li>

</ol>
  </div>
</div>
<script type="text/javascript">
now=new Date;
t10=now.getTime();
</script>
</div>
</div>
</div>
</div>
<div id="footer" class="md">
<ul id="flist2">
<li class="first"><a href="r/ao">Advertise with Us</a></li>
<li><a href="r/o4">Search Marketing</a></li>
<li><a href="r/hw">Help</a></li>
<li><a href="r/pv">Privacy Policy</a></li>
<li><a href="r/ts">Terms of Service</a></li>
<li><a href="r/ad">Suggest a Site</a></li>
<li><a href="r/ep">Yahoo! Telemundo</a></li>
<li class="last"><a href="r/gb">Yahoo! TV Ads</a></li>
</ul>
<ul id="copyright">
<li class="first">Copyright &copy; 2007 Yahoo! Inc. All rights reserved.</li>
<li class="first"><a href="r/cy">Copyright/IP Policy</a></li>
<li><a href="r/cp">Company Info</a></li>
<li><a href="r/hr">Jobs</a></li>
</ul>
</div>
</div>
<!-- SpaceID=2716149 loc=FR01 noad -->
<script language=javascript>
if(window.yzq_d==null)window.yzq_d=new Object();
window.yzq_d[\'RZavKNGDJG4-\']=\'&U=139a48dcp%2fN%3dRZavKNGDJG4-%2fC%3d224039.2072002.3536622.2012076%2fD%3dFOOT%2fB%3d1088125\';
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142lk1j3g%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d2.1%2fW%3dH%2fY%3dYAHOO%2fF%3d4099148118%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1&U=139a48dcp%2fN%3dRZavKNGDJG4-%2fC%3d224039.2072002.3536622.2012076%2fD%3dFOOT%2fB%3d1088125"></noscript><noscript><img src="r/dw" style="position:absolute;left:-2000px;top:0;" height="1" width="1"></noscript>
</div></body>
<script type="text/javascript">
YAHOO.Fp.dod = function(){
var aArgs = arguments, nArgsLength = aArgs.length;
this.oTypes = {
js : "script" ,
css : "link"
}
sNode=(nArgsLength>3) ? this.oTypes[aArgs[3]] : this.oTypes["js"];
this.oAttributes = {
sNode       : sNode ,
aType       : ["type", (sNode=="script" ? "text/javascript" : "text/css") ] ,
aSource     : [ (sNode=="script" ? "src" : "href" ) , aArgs[0] ] ,
aName       : ( sNode=="script" ? [ "name" , "javascript" ] : [ "rel" , "stylesheet" ] ) ,
sId         : ( this.id++ || 0 ) ,
bBreakCache : ( (nArgsLength>1 && aArgs[1]!=\'\') ? aArgs[1] : 0 ) ,
bRemove     : ( (nArgsLength>2 && aArgs[2]!=\'\') ? aArgs[2] : 0 )
}
this.get = function(){
var d = document;
var dNode = d.createElement(this.oAttributes.sNode);
dNode.setAttribute( this.oAttributes.aType[0] , this.oAttributes.aType[1] );
dNode.setAttribute( this.oAttributes.aName[0] , this.oAttributes.aName[1] );
dNode.setAttribute( "id" , "src" + this.oAttributes.sId );
if(this.oAttributes.bBreakCache){
this.oAttributes.aSource[1] += "?rnd=" + Math.random();
}
dNode.setAttribute( this.oAttributes.aSource[0] , this.oAttributes.aSource[1] );
var dHead = d.getElementsByTagName(\'head\')[0];
dHead.appendChild(dNode);
if(this.oAttributes.bRemove){
setTimeout(function(){dNode.parentNode.removeChild(dNode);}, 500);
}
return dNode;
}
return this.get();
}
YAHOO.Fp.sQueryString = function ( ) {
var aQueryString = [];
aQueryString.push(\'nu=1\');
if (typeof(kfEnable)!=\'undefined\') {
aQueryString.push(\'kf=\'+kfEnable);
}
return ( ( aQueryString.length > 0 ) ? aQueryString.join(\'&\') : \'\' );
}();
YAHOO.Fp.load = function(){
now=new Date;
t12=now.getTime();
_ult=(typeof(yguc)!="undefined")?1:0;
YAHOO.Fp.dod(\'http://us.js2.yimg.com/us.js.yimg.com/i/ww/sp/onload_1.3.4.css\',\'\',\'\', \'css\');
YAHOO.Fp.dod(\'http://us.js2.yimg.com/us.js.yimg.com/i/ww/sp/onload_1.4.8.js\');
YAHOO.Fp.dod(\'http://us.js2.yimg.com/us.js.yimg.com/i/ww/sp/ie7ws_0.4.js\');

}
window.onload=YAHOO.Fp.load;
YAHOO.Fp.jsOnloadLoaded = function(){
YAHOO.Fp.trough = new YAHOO.Fp.oTrough();
YAHOO.util.Event.addListener(\'allyservices\', \'click\',function(e){YAHOO.util.Event.stopEvent(e); YAHOO.Fp.trough.toggleTrough(0,{sAction : "all"});} );
}
YAHOO.Fp.jsLoaded = function(){
if(document.getElementById("exceptional")){
YAHOO.Fp.updateTimeStamp(\'exceptional\',\'d\');
}
YAHOO.Fp._ylh=typeof(YLH)!=\'undefined\'?YLH+\'/\':\'\';
if(YAHOO.Fp.infinity){
YAHOO.Fp.infinity();
}
YAHOO.Fd.attachUlt(document.getElementById(\'patabs\'), \'mouseover\');
if (document.getElementById(\'pa\'))
{
instantiatePaModule();
}
var eSizeToggleLink = document.getElementById("sizetogglelink");
if(eSizeToggleLink){
eSizeToggleLink.onclick=function(){YAHOO.Fp.togglePageSize("ts");return false;};
}
if(document.getElementById(\'todaytabs\')){
var todayTabs = new YAHOO.Fp.tabs("todaytabs");
todayTabs.bChangeTab=0;
todayTabs.changeAction(YAHOO.Fp.loadPanel,{"type":"tab","module":"today","load":"story,footer"});
todayTabs.setupTabs();
YAHOO.Fp.setupStoriesTabs("footer1",todayTabs,"featured1ct");
}
if(document.getElementById(\'vsearchtabs\')){
var verts=new YAHOO.Fp.tabs("vsearchtabs");
verts.changeAction(YAHOO.Fp.changeVert,{"obj":verts});
verts.setupTabs();
YAHOO.util.Event.addListener(document,"keydown",fKeyDown,verts);
}
if(YAHOO.Fp._ie){
YAHOO.Fp.onResize = function(){
var dLink = document.getElementById("copyright");
var nSize = dLink.offsetHeight;
document.getElementById(\'search\').style.height=(nSize>17 ? (nSize>21 ? \'120px\' : \'105px\') : \'89px\');
if(document.getElementById(\'scountry\')){document.getElementById(\'scountry\').style.bottom=(nSize>17 ? (nSize>21 ? \'32px\' : \'28px\') : \'25px\');}
}
YAHOO.Fp.onResize();
YAHOO.util.Event.addListener(\'page\',\'resize\',YAHOO.Fp.onResize);
}
YAHOO.Fp.oSearch.searchTargets = {"IN":"r/i5","UK":"r/i6","CA":"r/i7","PH":"r/i8","MY":"r/ib","SG":"r/ic","CN":"r/if","AU":"r/ih","NZ":"r/ii","DE":"r/ij","ID":"r/ik"};
YAHOO.util.Event.addListener(document.sf1, \'submit\', YAHOO.Fp.oSearch.updateSearch, verts);
if(document.getElementById(\'newstabs\')){
var newsTabs = new YAHOO.Fp.tabs("newstabs");
newsTabs.bChangeTab=0;
newsTabs.changeAction(YAHOO.Fp.loadPanel,{"type":"tab","module":"news","load":"story"});
newsTabs.setupTabs();
if(typeof(YAHOO.Fp.updateTimeStamp)!=\'undefined\'){
YAHOO.Fp.updateTimeStamp(\'newstop\');YAHOO.Fp.updateTimeStamp(\'todaybd\',\'d\');
}
}
YAHOO.Fp.local = new YAHOO.Fp.localNews();
if(document.getElementById(\'editpage\')){
YAHOO.Fp.pageSettings = new YAHOO.Fp.oPageSettings();
YAHOO.Fp.oPageSettings.prototype.sCurrentTheme = "t1";YAHOO.util.Event.addListener(\'editpage\', \'click\',function(e){YAHOO.util.Event.stopEvent(e);YAHOO.Fp.pageSettings.toggle();return false;} );
YAHOO.util.Event.addListener(document.getElementById(\'themes\').getElementsByTagName(\'a\'), \'click\', function(e){YAHOO.util.Event.stopEvent(e);YAHOO.Fp.pageSettings.applyTheme(e,YAHOO.Fp.pageSettings);return false;} );
}
YAHOO.Fp.selectTab = function(sTab,oObj){
sTab = YAHOO.cookie.getsub("FPM",sTab);
if(sTab!=""){
setTimeout( function(){
oObj.tabAction(0,oObj,document.getElementById(sTab));
}, 10);
}
}
if(YAHOO.cookie.get("FPM").indexOf(\'=\')>0){
YAHOO.Fp.selectTab("news",newsTabs);
YAHOO.Fp.selectTab("today",todayTabs);
}
YAHOO.Fp.onJsLoaded.fire();
};
var YMAPPID = "trafficbrowser";
YAHOO.Fp.sPartner="";
YAHOO.Fp.nUlmVer=3;
var nu=1;
YAHOO.Fp.oSearch={};
YAHOO.Fp.oSearch.bg=\'http://us.i1.yimg.com/us.yimg.com/i/ww/thm/1/search_1.1.png\';
YAHOO.Fp.oSearch.sMoreLinksHtml=\'<div><ul><li class="first"><a href="r/av/*http://answers.yahoo.com/search/search_result" class="vs_answers">Answers</a></li><li><a href="r/aw/*-http://audio.search.yahoo.com/search/audio" class="vs_audio">Audio</a></li><li><a href="r/b0/*-http://search.yahoo.com/search/dir" class="vs_directory">Directory</a></li><li><a href="r/b4/*-http://hotjobs.yahoo.com/jobseeker/jobsearch/search_results.html" class="vs_jobs">Jobs</a></li><li><a href="r/b1/*-http://news.search.yahoo.com/search/news" class="vs_news">News</a></li><li class="last"><a href="r/cq">All Search Services</a></li></ul><span></span><ul class="vslist"><li class="first"><a href="r/bt">Advertising Programs</a></li></ul></div>\';
YAHOO.Fp.oSearch.sLocalSearchHtml = \'<label for="p" class="plabel"><input id="p" type="text" class="inputtext" name="p"><span>Businesses &amp; Services</span></label><label for="scsz" class="cszlabel1">in</label><label for="scsz" class="cszlabel2"><input name="csz" class="inputtext" id="scsz" type="text"><span>Address, City, State, or Zip</span></label>\';
function PaModule(){};
YAHOO.Fp.oPaErrorManager = {
mail : {
html : "go to <a href=\'r/lm\'>Yahoo! Mail</a> to get your mail.</li><li class=\'last\'><a href=\'r/ll\'>&#187; Go To Yahoo! Mail",
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
bProcessed : 0,
dScriptNode : null
},
messenger : {
html : "go to <a href=\'r/p4\'>Yahoo! Messenger</a> to see your online contacts.</li><li class=\'last\'><a href=\'ymsgr:SendIM\'>&#187; Go To Yahoo! Messenger",
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
bProcessed : 0,
dScriptNode : null
},
weather : {
html : "go to <a href=\'r/wf\'>Yahoo! Weather</a> to get the local weather.</li><li class=\'last\'><a href=\'r/wf\'>&#187; Go To Yahoo! Weather",
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
dScriptNode : null
},
traffic : {
html : "go to <a href=\'r/kf\'>Yahoo! Local</a> to get the local traffic.</li><li class=\'last\'><a href=\'r/kf\'>&#187; Go To Yahoo! Local",
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
dScriptNode : null
},
events : {
html : "go to <a href=\'r/kf\'>Yahoo! Local</a> to get the local events.</li><li class=\'last\'><a href=\'r/kf\'>&#187; Go To Yahoo! Local",
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
dScriptNode : null
},
music : {
html : "<h3><a href=\'r/uc\'>LAUNCHcast Radio:</a> <em><a href=\'r/ud\'>Featured stations</a></em></h3><div class=\'station\'><div class=\'station-hd\'></div><div class=\'station-bd\' class=\'fixfloat\'><a class=\'photo-link\' href=\'r/ut/*-http://music.yahoo.com/launchcast/stations/station.asp?i=341\'><img class=\'station-photo\' src=\'http://us.ent1.yimg.com/images.launch.yahoo.com/000/025/969/25969265.jpg\'></a><h4><a class=\'station-name\' href=\'r/ut/*-http://music.yahoo.com/launchcast/stations/station.asp?i=341\'>Today\'s Big Hits</a></h4><p class=\'artists\'><a href=\'r/ut/*-http://music.yahoo.com/launchcast/stations/station.asp?i=341\'>Mary J. Blige, Kelly Clarkson, Sean Paul, Beyonce</a></p><a class=\'listen\' href=\'r/ul/*-http://music.yahoo.com/lc/?rt=1&rp1=341&rp2=0\' onclick=\\"YAHOO.Fp.launchMusicWindow(\'http://radio.music.yahoo.com/radio/player/default.asp?clientID=1&clientStationID=0&p=1&m=341&d=0\',491,365,\'http://music.yahoo.com/lc/?rt=1&rp1=341&rp2=0\');return false;\\">Listen</a></div><div class=\'station-ft\'></div></div><a class=\'btn-more\' href=\'r/ua\'>&#187; View All Stations</a><div class=\'nav\'><a class=\'back\' onclick=\\"return  YAHOO.Fp.oPaModule.getModuleData(\'music\',{nav:\'prev\',curr_stn:1})\\" href=\'r/um\'>Previous</a><a class=\'frwd\' onclick=\\"return YAHOO.Fp.oPaModule.getModuleData(\'music\',{nav:\'next\',curr_stn:1})\\" href=\'r/um\'>Next</a></div>",
error : false,
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
dScriptNode : null
},
horoscope : {
html : "go to <a href=\'r/h3\'>Yahoo! Astrology</a> to get your horoscope.</li><li class=\'last\'><a href=\'r/h3\'>&#187; Go To Yahoo! Astrology",
error : false,
status : false,
buffer : false,
requestDelayTimeout : null,
requestFailTimeout : null,
dScriptNode : null
},
template : {
templateHdr : "<div class=\'pa-alert error\'><ul><li class=\'first\'>Please ",
templateFtr : "</a></li></ul></div>"
}
}
YAHOO.Fp.oPaModuleHostname="p.www.yahoo.com";
if(YAHOO.Fp._hostname === \'preview.www.yahoo.com\' || YAHOO.Fp._hostname === \'qa.www.yahoo.com\' || YAHOO.Fp._hostname === \'staging.www.yahoo.com\'){
YAHOO.Fp.oPaModuleHostname = YAHOO.Fp._hostname;
}
</script>
<script type="text/javascript" src="http://us.js2.yimg.com/us.js.yimg.com/i/ww/sp/js_2.14.js"></script>
<script type="text/javascript">
now=new Date;
t11=now.getTime();
</script>
<script language="javascript" type="text/javascript">
YAHOO.Fp.nFontSize=false;
if(document.getElementById("copyright")){
YAHOO.Fp.nFontSize=document.getElementById("copyright").offsetHeight;
}
if (typeof(app_c_pp)!=\'undefined\'){
app_c_pp(\'hp\',YAHOO.Fp.hp?1:0);
app_c_pp(\'res\',YAHOO.Fp.bNarrow);
app_c_pp(\'cres\',YAHOO.Fp.sFsCookie);
app_c_pp(\'aw\',YAHOO.Fp.nScreenWidth);
app_c_pp(\'fs\',YAHOO.Fp.nFontSize);
}
var s=screen,b=document.body;
YAHOO.Fp.sFpm = YAHOO.cookie.get("FPM");
cc=\'&hp=\'+(YAHOO.Fp.hp?1:0)+\'&cp=\'+(YAHOO.Fp.cp?1:0)+\'&res=\'+(YAHOO.Fp.bNarrow)+\'&cres=\'+(YAHOO.Fp.sFsCookie)+\'&aw=\'+(YAHOO.Fp.nScreenWidth)+\'&sh=\'+s.height+\'&sw=\'+s.width+\'&fs=\'+YAHOO.Fp.nFontSize+(YAHOO.Fp.sFpm!=\'\'?\'&\'+YAHOO.Fp.sFpm:\'\');
if(YAHOO.Fp._ie){
b.style.behavior=\'url(#default#clientCaps)\';
cc=cc+\'&ct=\'+b.connectionType+\'&ch=\'+b.clientHeight+\'&cw=\'+b.clientWidth;
}
if(YAHOO.Fp._ie){
b.style.behavior=\'url(#default#clientCaps)\';
cc=cc+\'/ct=\'+b.connectionType+\'/ch=\'+b.clientHeight+\'/cw=\'+b.clientWidth;
}
</script>
</html>
<script language=javascript>ULT_KEY=\'X3oDMTVoOXRldnRwBGZwdF91cHMDMQRmcHRfYWQDMC45BGZwdF90MzkDMC42BHlwdWxzZQNjb25zZXJyBHBhAy0xBHBjaWQDVmlkZW9zX1BvcHVsYXJfV2lsZGxpZmVfdHdvX290dGVyc18zRS01ODYzNDkEcHBpZAMxMTc4OTUzODc2BGZwdF90NTIDMi4xBHRtcGwDaW5kZXgtbARfUwMyNzE2MTQ5BHBpZAMxMTc5MDA3NTMzBHRlc3QDMA--\';</script><!-- pbt 1179007533 --><script language=javascript>
if(window.yzq_p==null)document.write("<scr"+"ipt language=javascript src=http://l.yimg.com/us.js.yimg.com/lib/bc/bc_2.0.3.js></scr"+"ipt>");
</script><script language=javascript>
if(window.yzq_p)yzq_p(\'P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=13s6e5414%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d1.1%2fW%3dJ%2fY%3dYAHOO%2fF%3d232917113%2fS%3d1%2fJ%3d962483D1\');
if(window.yzq_s)yzq_s();
</script><noscript><img width=1 height=1 alt="" src="http://us.bc.yahoo.com/b?P=3bBx.9GDJJbKbbVTJfqEErwJRbXt.0ZGQcUACe4L&T=142ceaebm%2fX%3d1179009477%2fE%3d2716149%2fR%3dyahoo_top%2fK%3d5%2fV%3d3.1%2fW%3dJ%2fY%3dYAHOO%2fF%3d1591672595%2fQ%3d-1%2fS%3d1%2fJ%3d962483D1"></noscript>
<!-- f23.www.sp1.yahoo.com uncompressed/chunked Sat May 12 15:37:57 PDT 2007 -->

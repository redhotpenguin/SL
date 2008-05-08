#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 77;

BEGIN { use_ok('SL::Subrequest') or die }

# slurp the test webpage
my $content = do { local $/; <DATA> };

use Time::HiRes qw(tv_interval gettimeofday);

my $base_url   = 'http://www.youtube.com';
my $subreq     = SL::Subrequest->new();

# clear out the cache
$subreq->{cache}->clear;

my $start      = [gettimeofday];
my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);
my $interval = tv_interval( $start, [gettimeofday] );

is( scalar( @{$subreq_ref} ), 24, 'subrequests extracted' );
diag("extraction took $interval seconds");
my $limit = 0.1;
cmp_ok( $interval, '<', $limit,
    "subrequests extracted in $interval seconds" );

diag("check correct subrequests were extracted");
# unique subrequests
my %subreq_hash = map { $_->[0] => 1 } @{$subreq_ref};
foreach my $test_url ( @{ test_urls() } ) {
    ok(exists $subreq_hash{$test_url}, "extracted $test_url");
}

diag('test replacing the links');
my $port = '6969';
$start = [gettimeofday];
my $replaced = $subreq->replace_subrequests(
        { port => $port, content_ref => \$content, subreq_ref => $subreq_ref } );

cmp_ok($replaced, '==', 154, "154 urls replaced");

$interval = tv_interval( $start, [gettimeofday] );
$limit = 0.025;    # 25 milliseconds
diag("replacement took $interval seconds");
cmp_ok( $interval, '<', $limit, "replace_subrequests took $interval seconds" );

my $subrequests_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);

# sanity check the replaced subrequest urls
my $i = 0;
foreach my $subrequest_ref ( @{$subrequests_ref} ) {
    like( $subrequest_ref->[0], qr/$port/ );
    cmp_ok( $subreq_ref->[ $i++ ]->[2], 'eq', $subrequest_ref->[2] );
}


sub test_urls {
    return [
    qw(
http://www.redhotpenguin.com/css/ga.css
http://static.youtube.com/yt/css/watch_all-vfl32434.css
http://youtube.com/opensearch?locale=en_US
http://static.youtube.com/yt/favicon-vfl1123.ico
http://youtube.com/rssls
http://static.youtube.com/yt/js/watch_all_with_bidi-vfl32163.js
http://www.redhotpenguin.com/images/sl/sl.gif
http://pagead2.googlesyndication.com/pagead/show_ads.js
http://static.youtube.com/yt/img/pixel-vfl73.gif
http://i.ytimg.com/i/NZqjhqF8wuxO-lAXQbF4SQ/1.jpg
http://youtube.com/img/pixel.gif
http://i.ytimg.com/vi/TfMkzRwfGiU/default.jpg
http://i.ytimg.com/vi/-2X1C-kjXW8/default.jpg
http://i.ytimg.com/vi/pERnJns5zOU/default.jpg
http://i.ytimg.com/vi/05YeDOkDGso/default.jpg
http://i.ytimg.com/vi/IvhVI-D3ivc/default.jpg
http://i.ytimg.com/vi/J7f5MRkJho0/default.jpg
http://i.ytimg.com/vi/ADkBZ4_9Lzc/default.jpg
http://i.ytimg.com/vi/sEf83Z6YpQA/default.jpg
http://i.ytimg.com/vi/Xw5nE__RZEM/default.jpg
http://youtube.com/
http://pagead2.googlesyndication.com/
http://static.youtube.com/
http://www.youtube.com/
)
 ];
}


__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">


	<html lang="en">

<!-- machid: 272 -->
<head><link rel="stylesheet" href="http://www.redhotpenguin.com/css/ga.css" type="text/css" />
	
	<title>YouTube - Memory Game</title>

		<link rel="stylesheet" href="http://static.youtube.com/yt/css/watch_all-vfl32434.css" type="text/css">
	<!--[if IE]>
		<style>
			.addtoQL90 {
				margin-top: -27px;
			}
		</style>
	<![endif]-->
	<link rel="search" type="application/opensearchdescription+xml" href="http://youtube.com/opensearch?locale=en_US" title="YouTube Video Search">
	<style type="text/css">
		#ticker {
			background-color: #eee;
			width: 100%;
		}
		#ticker .container {
			margin-left: 33%;
			overflow: auto;
			height: 32px;
		}
		#ticker img {
			display: block;
			float: left;
			background: transparent url(/img/master.gif) no-repeat scroll -488px -23px;
			margin-right: 5px;
		}
		#ticker h1 {
			float: left;
			display: block;
			font-size: 12px;
			font-weight: bold;
			line-height: auto;
			margin: 8px 0;
		}
	</style>
	<link rel="icon" href="http://static.youtube.com/yt/favicon-vfl1123.ico" type="image/x-icon">
	<link rel="shortcut icon" href="http://static.youtube.com/yt/favicon-vfl1123.ico" type="image/x-icon">
	

	<meta name="title" content="Memory Game">
	<meta name="description" content="The Wild Horses found this one in our &quot;made for sesame street&quot; vault. But remember folks, you dont have to wait for a holiday to think about your heroes. The...">
	<meta name="keywords" content="MLK, tribute, nathalie, roland, lila, yomtoob, memory, game, cards, heroes, hero, animation, wild, horse, society">

	<link rel="alternate" type="application/rss+xml" title="YouTube - [RSS]" href="http://youtube.com/rssls">

				<script type="text/javascript" src="http://static.youtube.com/yt/js/watch_all_with_bidi-vfl32163.js"></script>

	<script type="text/javascript">
		var quicklist_count=0;

		function _hbLink (a,b) { return false; }

		
	</script>
    <script type="text/javascript">    <script type="text/javascript">

	

	<script type="text/javascript">
		initWatchQueue(true);
		var MSG_Hide = 'Hide';
		var MSG_Show = 'Show';
		var MSG_Login = 'Please login to perform this operation.';
		var MSG_Loading = 'Loading...';
		var MSG_ShowingAll = 'Showing All Videos';
		var MSG_LoginFavorites = 'You must be logged in to add this video to your favorites';
		var MSG_LoginPostResponse = 'You must be logged in to post a response.';
		var MSG_LoginAddPlaylist = 'You must be logged in to add this video to a playlist.';
		var MSG_LoginReportConcern = 'You must be logged in to report a concern.';
		var MSG_FlagDefault = 'Select a Reason';

		var isLoggedIn  =  false ;
		var swfUrl = '/player2.swf?v=1';
					
					
					
					
					
					
		var swfArgs = {hl:'en',BASE_YT_URL:'http://youtube.com/',video_id:'d8Arzv-8-Fg',l:'201',t:'OEgsToPDskL7I570RqURbOFC-eYdX97-',sk:'6TuChPqtLShuMT4Rx4NBcAC'};

		var additionalStatsHonorsUrl = '/watch_ajax?v=d8Arzv-8-Fg&action_get_honors=1&l=EN';
		var additionalStatsAudioUrl = '/watch_ajax?v=d8Arzv-8-Fg&action_get_audio_info=1&l=EN';
		var watchlistContainerUrl = '/watch_queue_ajax?action_get_all_queue_videos_component&v=d8Arzv-8-Fg';
		var fullscreenUrl = '/watch_fullscreen?video_id=d8Arzv-8-Fg&l=201&t=OEgsToPDskL7I570RqURbOFC-eYdX97-&sk=6TuChPqtLShuMT4Rx4NBcAC&fs=1&title=Memory Game';
		var watchGamUrl = null;
		var watchDCUrl = null;
		var watchQuery = null;
		var watchSourceDetail = null;
		var watchSourceId = null;
		var watchTrackWithHitbox = false;
		var watchIsPlayingAll = false;
		var watchPlayerTrackingId = null;
		var watchUsername = 'WildHorseSociety';
		var pageVideoId = 'd8Arzv-8-Fg';
		var relatedVideoGridUrl = '/related_ajax?video_id=d8Arzv-8-Fg&view_type=G&watch3=1&search=%20MLK%20tribute%20nathalie%20roland%20lila%20yomtoob%20memory%20game%20cards%20heroes%20hero%20animation%20wild%20horse%20society';
		var relatedVideoListUrl = '/related_ajax?video_id=d8Arzv-8-Fg&view_type=L&watch3=1&search=%20MLK%20tribute%20nathalie%20roland%20lila%20yomtoob%20memory%20game%20cards%20heroes%20hero%20animation%20wild%20horse%20society';
		var playnextFrom = '';
		var playnextCount = '0';
		var qlAutoscrollDestination = 0;
		var watchSetWmode = false;

		var axc = '';
		var subscribeaxc = '';
		
			watchSourceDetail = "p%3A/";
			watchSourceId = "y";
			watchPlayerTrackingId = "AAREXdkjuV36Pr3GAAAAoIAIQAA";



			function showCommentReplyForm(form_id, reply_parent_id, is_main_comment_form) {
		if(!CheckLogin()) {
			alert("Please login to post a comment.");
			return false;
		}

		printCommentReplyForm(form_id, reply_parent_id, is_main_comment_form);
	}
	function printCommentReplyForm(form_id, reply_parent_id, is_main_comment_form) {

		var div_id = "div_" + form_id;
		var reply_id = "reply_" + form_id;
		var reply_comment_form = "comment_form" + form_id;
		if (is_main_comment_form)
			discard_visible="style='display: none'";
		else
			discard_visible="";

		var innerHTMLContent = '\
		<form name="' + reply_comment_form + '" id="' + reply_comment_form + '" onSubmit="return false" method="post" action="/comment_servlet" >\
			<input type="hidden" name="video_id" value="d8Arzv-8-Fg">\
			<input type="hidden" name="add_comment" value="">\
			\
			<input type="hidden" name="form_id" value="' + reply_comment_form + '">\
			<input type="hidden" name="reply_parent_id" value="' + reply_parent_id + '">\
			<input type="hidden" name="comment_type" value="V">\
			<textarea  name="comment" \
			cols="46" rows="5" \
			onkeyup="goog.i18n.bidi.setDirAttribute(event,this)"></textarea>\
			<br/>\
			<div style="float:left;clear:left">\
				<input align="left"  type="button"  name="add_comment_button" \
								value="Post Comment" \
								onclick="postThreadedComment(\'' + reply_comment_form + '\');">\
				<input align="left" type="button" name="discard_comment_button"\
								value="Discard" ' + discard_visible + '\
								onclick="hideCommentReplyForm(\'' + form_id + '\',false);">\
			</div>\
			</form><br style="clear:both"><br>';
		
		if(!is_main_comment_form) {
			toggleVisibility(reply_id, false);
		}
		setInnerHTML(div_id, innerHTMLContent);
		toggleVisibility(div_id, true);
	}

	function loginMsg(div_id, display_val) {
		login_msg_div_id = "comment_msg_" + div_id;
		if (display_val == 1) {
			setInnerHTML(login_msg_div_id, 'Please login');
		}
		else {
			setInnerHTML(login_msg_div_id, '');
		}
	}

	function postThreadedComment(comment_form_id) 
	{
		if (CheckLogin() == false)
			return false;

		var form = document.forms[comment_form_id];

		
		if (ThreadedCommentHandler(form, comment_form_id)) {
			var add_button = form.add_comment_button;
			add_button.value = "Adding comment...";
			form.comment.disabled = true;
			add_button.disabled = true;

		} 
	}
	function commentApproved(xmlHttpRequest)
{
	alert("Comment approved.")
}

	function ThreadedCommentHandler(comment_form, comment_form_id)
	{
		var comment = comment_form.comment;
		var comment_button = comment_form.comment_button;

		if (comment.value.length == 0 || comment.value == null)
		{
			alert("You must enter a comment!");
			comment.disabled=false;
			comment.focus();
			return false;
		}

		if (comment.value.length > 500)
		{
			alert("Your comment must be shorter than 500 characters!");
			comment.disabled=false;
			
			comment.focus();
			return false;
		}
		postFormByForm(comment_form, true, commentResponse);
		return true;
	}
	function commentResponse(xmlHttpRequest)
	{
		response_str = xmlHttpRequest.responseText;
		response_code = response_str.substr(0, response_str.indexOf(" "));
		form_id = response_str.substr(response_str.indexOf(" ")+1);
		
		var form = document.forms[form_id];
		var dstDiv = form.add_comment_button;
		var discard_button = form.discard_comment_button;
		var commentDiv = form.comment;

		if (response_code == "OK") {
		dstDiv.value = "Comment Posted!";
		dstDiv.disabled = true;
			discard_button.disabled = true;
			discard_button.style.display  = "none";
		} else if (response_code == "PENDING") {
			dstDiv.value = "Comment Pending Approval!";
			dstDiv.disabled = true;
			discard_button.disabled = true;
			discard_button.style.display  = "none";

		} else if (response_code == "LOGIN") {
		    dstDiv.disabled = false;
		} else if (response_code == "EMAIL") {
		    if(confirm("You must confirm your email address before you can submit comments.  Click OK to confirm your email address."))
			{
				window.location="/email_confirm"
			}
		    dstDiv.disabled = false;
		} else {
			if(response_code == "BLOCKED") {
				dstDiv.disabled = true;
			} else if(response_code == "TOOSOON") {
				dstDiv.disabled = false;
				alert("Commenting Limit Exceeded");
			} else if(response_code == "TOOLONG") {
				alert("The comment you have entered is too long. Limit is 500 characters. Please write a shorter comment and try again");
				dstDiv.disabled = false;
				commentDiv.disabled = false;
			} else if(response_code == "TOOSHORT") {
				alert("The comment you have entered is too short. Please write a longer comment and try again");
				dstDiv.disabled = false;
				commentDiv.disabled = false;
				commentDiv.focus();
			} else if(response_code == "FAILED") {
				dstDiv.disabled = true;
			} else if(response_code == "FAILADDED") {
				dstDiv.disabled = true;
			} else if(response_code == "CAPTCHAFAIL") {
				alert("The response to the letters on the image was not correct, please try again.");
				dstDiv.disabled = false;
			} else {
				dstDiv.disabled = false;
			}
			dstDiv.value = "Post Comment";
		}
	}

	function load_all_comments(video_id, is_watch2) {
		var remove_btn = document.getElementById('all_comments_button');
		if(remove_btn) {
			remove_btn.value = "Loading Comments...";
			remove_btn.disabled = true
		}
			
		if(is_watch2)
			var watch2_str = "&watch2"
		else
			var watch2_str = ""
		
		getUrlXMLResponse("/comment_servlet?get_comments&v=" + video_id + watch2_str, handleStateChange);
		
	}
	function hideSpam(cid) {
		if (document.getElementById('reply_comment_form_id_'+cid)) {
			document.getElementById('reply_comment_form_id_'+cid).style.display = 'none';
			
		}
		if (document.getElementById('comment_body_'+cid)) {
			document.getElementById('comment_body_'+cid).style.display = 'none';
		}
		if (document.getElementById('comment_spam_bug_'+cid)) {
			document.getElementById('comment_spam_bug_'+cid).style.display = 'inline';
		}
	}

		
	function redirectToUrl(req)
	{
		window.location.href=self.new_redirect_url;
		return true;
	}
	function unblockUserLink(friend_id, url)
	{
        if (!confirm("Are you sure you want to unblock this user?"))
            return false;
        self.new_redirect_url = url;
        data ="unblock_user=1&&friend_id=" + friend_id;
		postUrlXMLResponse("/link_servlet",data ,execOnSuccess(redirectToUrl));
		return true;
	}
	function blockUserLink(friend_id, url)
	{
        if (!confirm("Are you sure you want to block this user?"))
            return true;
        self.new_redirect_url = url;
        data ="block_user=1&&friend_id=" + friend_id;
		postUrlXMLResponse("/link_servlet", data, redirectToUrl);
		return true;
	}
	function unblockUserLinkByUsername(friend_username)
	{
        if (!confirm("Are you sure you want to unblock this user?"))
            return false;
        data ="unblock_user=0&&friend_username=" + friend_username;
		postUrlXMLResponse("/link_servlet", data);
		return false;
	}
	function blockUserLinkByUsername(friend_username)
	{
        if (!confirm("Are you sure you want to block this user?"))
            return false;
        data ="block_user=1&&friend_username=" + friend_username;
		postUrlXMLResponse("/link_servlet", data);
		return false;
	}






		
		var userPrefs = new UserPrefs();
        
		function applyUserPrefs() {
			if (_gel('customizeEmbedDiv')) {
				var showBorderCheckBox = _gel('show_border_checkbox');
				showBorderCheckBox.checked = userPrefs.getPref('emBorder') == 'true';
				if (userPrefs.getPref('emRelated') == 'false') {
					_gel('embedCustomization0').checked = true;
				} else {
					_gel('embedCustomization1').checked = true;
				}

				var color = userPrefs.getPref('emTheme', 'blank');
				if (color != 'blank') {
					onChangeColor(color);
				}
			}
		}
		onLoadFunctionList.push(applyUserPrefs);
		
		var selectedThemeColor = 'blank'
		function onChangeColor(color) {
            var oldTheme = document.getElementById('theme_color_' + selectedThemeColor + '_img');
			var newTheme = document.getElementById('theme_color_' + color + '_img');
			
			userPrefs.setPref('emTheme', color);
			userPrefs.savePrefs();
			
			removeClass(oldTheme, 'radio_selected');
			addClass(newTheme, 'radio_selected');

			selectedThemeColor = color;	
			onUpdatePreviewImage();
		
			return false;
		} 
		function onChangeBorder(border) {
			userPrefs.setPref('emBorder', (!!border));
			userPrefs.savePrefs();
			
			onUpdatePreviewImage();
		}
		function onChangeRelated(related) {
			userPrefs.setPref('emRelated', related);
			userPrefs.savePrefs();
		}
			
		function onUpdatePreviewImage()
		{
			var previewImage = document.getElementById('customizeEmbedThemePreview');
			var showBorderCheckBox = document.getElementById('show_border_checkbox');
			var border = (!showBorderCheckBox.checked ? '_nb' : '');
			previewImage.src = 'img/preview_embed_' + selectedThemeColor + '_sm' + border + '.gif';
		}

		function signup(){
			window.location = "/signup?next_url=" + escape(window.location);
		}
		


	</script>


</head>


<body onLoad="performOnLoadFunctions();"><div id="sl_top"><p>
<a style="text-decoration: none;" href="http://www.silverliningnetworks.com/">
<img style="position: absolute; top: 6px; left: 5px;border: 0px;padding: 0px;" src="http://www.redhotpenguin.com/images/sl/sl.gif" /></a>
&nbsp;&nbsp;
<span class="sl_textad_text">

<script type="text/javascript"><!--
google_ad_client = "pub-5785951125780041";
google_ad_width = 468;
google_ad_height = 60;
google_ad_format = "468x60_as";
google_ad_type = "text";
//google_ad_channel = "7309150677";
//-->
</script>
<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>

</span>
<span class="sl_black">
  <a href="/sl_secret_blacklist_button" >Close X</a>
</span>
<span class="sl_link">
  <a href="http://www.silverliningnetworks.com/" >Silver Lining</a>
</span>
</p>
</div><div id="sl_ctr">
<div id="baseDiv">
		<div id="masthead">
		<a href="/" class="logo"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="132" height="46" border="0" alt=""/></a>
		<div class="user-info">
					<div id="loginBoxZ" class="loginBoxZStd">
			<div class="contentBox" style="padding: 6px; border: 1px solid #CCC;">
				<div>
					<div class="floatR"><span class="smallText"><b><a href="/signup">Sign Up</a> | <a href="http://www.google.com/support/youtube/bin/topic.py?topic=10546&amp;amp;hl=en_US">Help</a></b></span></div>
					<div class="floatL">
						<span class="headerTitle hpBlockHeadingGray"> Login </span>
					</div>
					<div class="clear"></div>
				</div>

				<form method="post" name="loginForm" id="loginFormZ" action="/signup">
				<input id="loginNextZ" name="next" type="hidden" value="" />
				<input type="hidden" name="current_form" value="loginForm" />
				<input type="hidden" name="action_login" value="1">
				<table width="270">
					<tr>
						<td align="right"><label for="loginUserZ"><span class="smallText"><b>Username:</b></span></label></td>
						<td><input id="loginUserZ" class="smallText" type="text" size="16" name="username" value=""></td>
					</tr>
					<tr>
						<td align="right"><label for="loginPassZ"><span class="smallText"><b>Password:</b></span></label></td>
						<td><input id="loginPassZ" class="smallText" type="password" size="16" name="password"></td>
					</tr>
					<tr>
						<td></td>
						<td>
							<span><input type="submit" class="smallText" value="Login"></span>	
						</td>
					</tr>
				</table>
				</form>
				<div class="hpLoginForgot smallText">
					<p align="center" class="marT0 marB0"><a href="/forgot_username?next=/watch?v=d8Arzv-8-Fg">Forgot Username</a> | <wbr><nobr><a href="/forgot?next=/watch?v=d8Arzv-8-Fg">Forgot Password</a></nobr></p>
				</div>
				<div style="border-bottom: 1px dotted #999; margin-bottom: 5px; margin-top: 5px;" class="bottomBorderDotted"></div>
				<div class="alignC"><span class="smallText"><b><a href="https://www.google.com/accounts/ServiceLogin?service=youtube&amp;hl=en_US&amp;continue=http://www.youtube.com/signup%3Fhl%3Den_US&amp;passive=true">Login with your Google account</a>&nbsp; <a href="#" onClick="window.open('/t/help_gaia','login_help','width=580,height=480,resizable=yes,scrollbars=yes,status=0').focus();" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" border="0" class="alignMid gaiaHelpBtn" alt=""></a></b></span></div>
			</div>
	</div>

					<div id="localePickerBox">
	<div id="flagDiv">
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('en_AU'); return false;" class="localePickerFlagLink"><img id="flag_en_AU" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="en_AU"></a> <a href="#" id="countryDiv_en_AU" onclick="selectLocale('en_AU'); return false;" class="localePickerTitle">Australia</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('pt_BR'); return false;" class="localePickerFlagLink"><img id="flag_pt_BR" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="pt_BR"></a> <a href="#" id="countryDiv_pt_BR" onclick="selectLocale('pt_BR'); return false;" class="localePickerTitle">Brazil</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('en_CA'); return false;" class="localePickerFlagLink"><img id="flag_en_CA" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="en_CA"></a> <a href="#" id="countryDiv_en_CA" onclick="selectLocale('en_CA'); return false;" class="localePickerTitle">Canada</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('fr_FR'); return false;" class="localePickerFlagLink"><img id="flag_fr_FR" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="fr_FR"></a> <a href="#" id="countryDiv_fr_FR" onclick="selectLocale('fr_FR'); return false;" class="localePickerTitle">France</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('de_DE'); return false;" class="localePickerFlagLink"><img id="flag_de_DE" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="de_DE"></a> <a href="#" id="countryDiv_de_DE" onclick="selectLocale('de_DE'); return false;" class="localePickerTitle">Germany</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('en_US'); return false;" class="localePickerFlagLink"><img id="flag_en_US" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="en_US"></a> <a href="#" id="countryDiv_en_US" onclick="selectLocale('en_US'); return false;" class="localePickerTitle">Global</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('zh_HK'); return false;" class="localePickerFlagLink"><img id="flag_zh_HK" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="zh_HK"></a> <a href="#" id="countryDiv_zh_HK" onclick="selectLocale('zh_HK'); return false;" class="localePickerTitle">Hong Kong</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('en_IE'); return false;" class="localePickerFlagLink"><img id="flag_en_IE" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="en_IE"></a> <a href="#" id="countryDiv_en_IE" onclick="selectLocale('en_IE'); return false;" class="localePickerTitle">Ireland</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('it_IT'); return false;" class="localePickerFlagLink"><img id="flag_it_IT" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="it_IT"></a> <a href="#" id="countryDiv_it_IT" onclick="selectLocale('it_IT'); return false;" class="localePickerTitle">Italy</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('ja_JP'); return false;" class="localePickerFlagLink"><img id="flag_ja_JP" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="ja_JP"></a> <a href="#" id="countryDiv_ja_JP" onclick="selectLocale('ja_JP'); return false;" class="localePickerTitle">Japan</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('es_MX'); return false;" class="localePickerFlagLink"><img id="flag_es_MX" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="es_MX"></a> <a href="#" id="countryDiv_es_MX" onclick="selectLocale('es_MX'); return false;" class="localePickerTitle">Mexico</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('nl_NL'); return false;" class="localePickerFlagLink"><img id="flag_nl_NL" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="nl_NL"></a> <a href="#" id="countryDiv_nl_NL" onclick="selectLocale('nl_NL'); return false;" class="localePickerTitle">Netherlands</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('en_NZ'); return false;" class="localePickerFlagLink"><img id="flag_en_NZ" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="en_NZ"></a> <a href="#" id="countryDiv_en_NZ" onclick="selectLocale('en_NZ'); return false;" class="localePickerTitle">New Zealand</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('pl_PL'); return false;" class="localePickerFlagLink"><img id="flag_pl_PL" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="pl_PL"></a> <a href="#" id="countryDiv_pl_PL" onclick="selectLocale('pl_PL'); return false;" class="localePickerTitle">Poland</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('ru_RU'); return false;" class="localePickerFlagLink"><img id="flag_ru_RU" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="ru_RU"></a> <a href="#" id="countryDiv_ru_RU" onclick="selectLocale('ru_RU'); return false;" class="localePickerTitle">Russia</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('ko_KR'); return false;" class="localePickerFlagLink"><img id="flag_ko_KR" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="ko_KR"></a> <a href="#" id="countryDiv_ko_KR" onclick="selectLocale('ko_KR'); return false;" class="localePickerTitle">South Korea</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('es_ES'); return false;" class="localePickerFlagLink"><img id="flag_es_ES" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="es_ES"></a> <a href="#" id="countryDiv_es_ES" onclick="selectLocale('es_ES'); return false;" class="localePickerTitle">Spain</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('zh_TW'); return false;" class="localePickerFlagLink"><img id="flag_zh_TW" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="zh_TW"></a> <a href="#" id="countryDiv_zh_TW" onclick="selectLocale('zh_TW'); return false;" class="localePickerTitle">Taiwan</a>
			</div>
			<div class="flagDiv">
				<a href="#" onclick="selectLocale('en_GB'); return false;" class="localePickerFlagLink"><img id="flag_en_GB" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="17" height="11" class="currentFlag" alt="" locale="en_GB"></a> <a href="#" id="countryDiv_en_GB" onclick="selectLocale('en_GB'); return false;" class="localePickerTitle">United Kingdom</a>
			</div>


		<div class="alignR smallText"><a href="#" onclick="closeLocalePicker(); return false;">Close</a></div>
	</div>
	</div>

				

		<span class="info-section first"><b><a  href="/signup" onclick="_hbLink('SignUp','UtilityLinks');">Sign Up</a></b></span>
		<span class="info-section"><a  href="/my_account">Account</a></span>
		<span class="info-section"><a  href="/recently_watched" onclick="_hbLink('ViewingHistory','UtilityLinks');">History</a></span>
		<span class="info-section"><a  href="http://www.google.com/support/youtube/?hl=en_US">Help</a></span>
		<span class="info-section"><a  href="#" class="loginBoxZ eLink" onclick="_gel('loginNextZ').value = '/watch?v=d8Arzv-8-Fg'; openLoginBox(); return false">Log In</a></span>

		<span class="info-section"><a href="#" class="localePickerLink eLink" onclick="window.parent.loadFlagImgs();window.parent.toggleDisplay('localePickerBox');return false;">Site:</a><a href="#" class="localePickerLink" onclick="window.parent.loadFlagImgs();window.parent.toggleDisplay('localePickerBox');return false;"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="currentFlag  globalFlag" alt="Site:"></a></span>

			<form name="logoutForm" method="post" target="_top" action="/index">
		<input type="hidden" name="action_logout" value="1">
	</form>

		</div>
		<div class="nav">
			<div class="nav-item first" id="nav-item-home">
				<span class="leftcap"></span>
				<a class="content" href="/">Home</a>
				<span class="rightcap"></span>
			</div>
			<div class="nav-item selected" id="nav-item-videos">
				<div class="nav-tab">
					<span class="leftcap"></span>
					<a class="content" href="/browse?s=mp">Videos</a>
					<span class="rightcap"></span>
				</div>
			</div>
			<div class="nav-item" id="nav-item-channels">
				<div class="nav-tab">
					<span class="leftcap"></span>
					<a class="content" href="/members">Channels</a>
					<span class="rightcap"></span>
				</div>
			</div>                                              
			<div class="nav-item" id="nav-item-community">
				<div class="nav-tab">
					<span class="leftcap"></span>
					<a class="content" href="/community">Community</a>
					<span class="rightcap"></span>
				</div>
			</div>
		</div>
		<div class="bar">
			<span class="leftcap"></span>
			<div class="search-bar">
				<a href="/my_videos_upload" class="upload-button">
					<span class="leftcap"></span>
					<span class="uploadtext">Upload</span>
					<span class="rightcap"></span>
				</a>
				<form id="search-form" action="/results" method="get" name="searchForm">
					<input id="search-term" name="search_query" type="text" value="" maxlength="128" tabindex="10000" />
					<input id="search-button" name="search" type="submit" value="Search" />
				</form>
			</div>
			<span class="rightcap"></span>
		</div>
	</div>

	
	
	
	








<div id="vidTitle">
	<span >Memory Game</span>
</div>
<table cellpadding="0" cellspacing="0"><tr valign="top">
<td id="thisVidCell">
<div id="thisVidDiv">
	<div id="checkerDiv" style="position:absolute; top:-100px; left:-100px;"></div>
	<div id="playerDiv">
		<div style="padding: 20px; font-size:14px; font-weight: bold;">
			Hello, you either have JavaScript turned off or an old version of Adobe's Flash Player. <a href="http://www.macromedia.com/go/getflashplayer/" onclick="_hbLink('Get+Flash','Watch3');">Get the latest Flash player</a>.
		</div>
	</div> 
	<script type="text/javascript">
		// <![CDATA[
		writeMoviePlayer("playerDiv");
		var to = new SWFObject("/version-check.swf", "checker", "0", "0", "0", "#FFFFFF");
		to.write("checkerDiv");
		// ]]>
	</script>








	<div id="actionsAreaDiv">
		<div class="actionLinks"> 
			<a id="a1_i1" href="#" class="actionLink" onclick="shareVideo('d8Arzv-8-Fg'); _hbLink('ShareVideo','Watch3ActionArea'); return false;" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="22" height="18" alt="Share" id="i1" class="alignMid marB3" /><span class="actionText">Share</span></a>
			<a id="a2_i2" href="#" class="actionLink" onclick="if (!hasClass(this, 'disabled')) { addToFaves('addToFavesForm'); _hbLink('AddToFavs','Watch3ActionArea'); }; return false;" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="22" height="18" alt="Favorite" id="i2" class="alignMid marB3" /><span class="actionText">Favorite</span></a>
			<a id="a3_i3" href="#" class="actionLink" onclick="addToPlaylist('d8Arzv-8-Fg'); _hbLink('AddToPlaylist','Watch3ActionArea'); return false;" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="22" height="18" alt="Add to Playlists" id="i3" class="alignMid marB3" /><span class="actionText">Add to Playlists</span></a><wbr>
			<nobr><a id="a4_i4" href="#" class="actionLink" title="Flag as inappropriate" onclick="reportConcern('d8Arzv-8-Fg'); _hbLink('ReportConcern','Watch3ActionArea'); return false;" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" width="22" height="18" alt="Flag as innapropriate" id="i4" class="alignMid marB3" /><span class="actionText">Flag</span></a></nobr>		</div> 

		<div id="addToFavesDiv" class="moreAction">
			<form method="post" action="/watch_ajax" name="addToFavesForm">
				
				<input type="hidden" name="action_add_favorite_playlist" value="1" />
				<input type="hidden" name="video_id" value="d8Arzv-8-Fg" />
				<input type="checkbox" checked name="add_to_favorite" />
			</form>
		</div> 
			<div id="addToFavesResult" class="actionResult">This video has been added to your <a href="/my_favorites">favorites</a>.</div>

		<div id="addToPlaylistDiv" class="moreAction">Loading...</div>
		<div id="addToPlaylistResult" class="actionResult">The video has been added to your playlist.</div>
		<div id="addToBlogResult" class="actionResult">This video will appear on your blog shortly.</div>
		<div id="reportConcernResult1" class="actionResult">
			<div class="closeDiv">(<a class="eLink" href="#" title="close this layer"  onclick="closeDiv('reportConcernResult1'); closeDiv('inappropriateVidDiv'); return false;">close</a>)</div>
			<div class="clearR">
			Thank you for sharing your concerns.
			</div>
		</div>
		<div id="reportConcernResult2" class="actionResult">
			<div class="closeDiv">(<a class="eLink" href="#" title="close this layer"  onclick="closeDiv('reportConcernResult2'); closeDiv('inappropriateVidDiv'); return false;">close</a>)</div>
			<div class="clearR">
			Thank you for flagging this video. Content of this nature is not necessarily prohibited on YouTube, however we will review this video and take action as appropriate.
			</div>
		</div>
		<div id="reportConcernResult3" class="actionResult">
			<div class="closeDiv">(<a class="eLink" href="#" title="close this layer"  onclick="closeDiv('reportConcernResult3'); closeDiv('inappropriateVidDiv'); return false;">close</a>)</div>
			<div class="clearR">
			Per our Community Guidelines, hate speech is specifically defined in reference to "<a href="http://www.google.com/support/youtube/bin/answer.py?answer=78716&amp;hl=en_US" target="HelpCenter">protected groups</a>."
			</div>
		</div>
		<div id="reportConcernResult4" class="actionResult">
			<div class="closeDiv">(<a class="eLink" href="#" title="close this layer"  onclick="closeDiv('reportConcernResult4'); closeDiv('inappropriateVidDiv'); return false;">close</a>)</div>
			<div class="clearR">
			Thank you for sharing your concerns. We can only process copyright complaints submitted by authorized parties in accordance with processes defined in law. There may be significant legal penalties for false notices. Please refer to our <a href="http://www.google.com/support/youtube/bin/answer.py?answer=58127&amp;hl=en_US" target="HelpCenter">Help Center</a> for more information and the complete instructions.
			</div>
		</div>
		<div id="reportConcernResult5" class="actionResult">
			<div class="closeDiv">(<a class="eLink" href="#" title="close this layer"  onclick="closeDiv('reportConcernResult5'); closeDiv('inappropriateVidDiv'); return false;">close</a>)</div>
			<div class="clearR">
			Thank you for sharing your concerns. In order to process a privacy complaint we need more information from you. Please refer to our <a href="http://www.google.com/support/youtube/bin/answer.py?answer=78346&amp;hl=en_US" target="HelpCenter">Help Center</a> for more information and the form to submit.
			</div>
		</div>
		<div id="inappropriateVidDiv" class="moreAction">Loading...</div>

		<div id="shareVideoDiv" class="moreAction">Loading...</div>
		<div id="shareVideoEmailDiv" class="moreAction martT0">Loading...</div>
		<div id="shareVideoResult" class="actionResult">Thank you for sharing this video!</div>
		<div id="loginPleaseDiv" class="loginPlease">
			<div class="contentBox" style="padding: 6px; border: 1px solid #CCC;" align="center">
				<table border="0" cellpadding="0" cellspacing="0"><tr valign="top"><td width="100%">
					<div>
						<div class="floatR"><span class="smallText"><b><a href="/signup">Sign Up</a> | <a href="http://www.google.com/support/youtube/bin/topic.py?topic=10546&amp;amp;hl=en_US">Help</a></b></span></div>
						<div class="floatL">
							<span class="headerTitle hpBlockHeadingGray"> Login </span>
						</div>
						<div class="clear"></div>
					</div>

					<form method="post" name="loginForm" action="/signup">
					<input name="next" type="hidden" value="/watch?v=d8Arzv-8-Fg">
					<input type="hidden" name="current_form" value="loginForm" />
					<input type="hidden" name="action_login" value="1">
					<table width="270">
						<tr>
							<td align="right"><label for="loginPleaseUser"><span class="smallText"><b>Username:</b></span></label></td>
							<td align="left"><input id="loginPleaseUser" class="smallText" type="text" size="16" name="username" value=""></td>
						</tr>
						<tr>
							<td align="right"><label for="loginPleasePass"><span class="smallText"><b>Password:</b></span></label></td>
							<td align="left"><input id="loginPleasePass" class="smallText" type="password" size="16" name="password"></td>
						</tr>
						<tr>
							<td></td>
							<td align="left">
								<span><input type="submit" class="smallText" value="Login"></span>	
							</td>
						</tr>
					</table>
					</form>
					<div class="hpLoginForgot smallText">
						<p align="center" class="marT0 marB0"><a href="/forgot_username?next=/watch?v=d8Arzv-8-Fg">Forgot Username</a> | <a href="/forgot?next=/watch?v=d8Arzv-8-Fg">Forgot Password</a></p>
					</div>
					<div style="border-bottom: 1px dotted #999; margin-bottom: 5px; margin-top: 5px;" class="bottomBorderDotted"></div>
					<div class="alignC"><span class="smallText"><b><a href="https://www.google.com/accounts/ServiceLogin?service=youtube&amp;hl=en_US&amp;continue=http://www.youtube.com/signup%3Fhl%3Den_US&amp;passive=true">Login with your Google account</a>&nbsp; <a href="#" onClick="window.open('/t/help_gaia','login_help','width=580,height=480,resizable=yes,scrollbars=yes,status=0').focus();" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" border="0" class="alignMid gaiaHelpBtn" alt=""></a></b></span></div>
				</td></tr></table>
			</div>
		</div> 
	</div> 



	<div id="ratingAndStatsDiv">
		<table cellspacing="0" cellpadding="0" width="100%"><tr><td align="center">
		<table cellspacing="0" cellpadding="0"><tr>

		<td style="text-align:left;">
			<div id="ratingDiv"> 
					

		<script language="javascript">


		_gel('ratingDiv').onmouseover = function() { hideDiv('defaultRatingMessage'); showDiv('hoverMessage'); };
		_gel('ratingDiv').onmouseout = function() { showDiv('defaultRatingMessage'); hideDiv('hoverMessage'); };
 	
		</script>

	<div id="ratingWrapper">
		<div class="nowrap">
			<div class="statLabel floatL">Rate:</div> 
		<img class="rating icn_star_full_19x20png" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_full_19x20png" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_empty_19x20png" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_empty_19x20png" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_empty_19x20png" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt="">
		</div>

		<div class="clearL"></div>
		
		<div id="ratingMessage" class="alignR">
			<div id="defaultRatingMessage">
							<span class="smallText">1178 ratings</span>

			</div>
				<div id="hoverMessage" style="width:100%" class="hid">
					<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg" onclick="if (loginPlease) { loginPlease(); return false;}">Login</a> to rate
				</div>
		</div>
	</div>


			</div>
		</td>

		<td width="50">&nbsp;</td>


		<td valign="top" style="text-align:left;">
			<div class="viewsDiv">
				<img class="rating" style="visibility:hidden; width:1px; height:20px;" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" align="top" alt="">
				<span class="statLabel">Views:</span>
				<span class="viewCount">149,442</span>
			</div>
		</td></tr></table>
		</td></tr></table>


			<div id="videoStatsDiv" style="border-top: 1px solid #CCC; padding-top: 5px;">
			<div id="someStats">
				<span class="lightLabel">Comments:</span> <a href="/comment_servlet?all_comments&amp;v=d8Arzv-8-Fg">750</a>
				&nbsp;&nbsp;&nbsp;
					<span class="lightLabel">Favorited:</span> 89 times
				&nbsp;&nbsp;&nbsp;
					<span class="lightLabel">Honors:</span> <a class="eLink" href="#" onclick="toggleFullStats(); return false;" rel="nofollow">2</a>
				&nbsp;&nbsp;&nbsp;
					<span class="lightLabel">Links:</span> <a class="eLink" href="#" onclick="toggleLinkStats(); return false;" rel="nofollow">5</a>
			</div> 
			
			<div id="fullStats">
				<div id="additionalStatsDiv" class="fullStatsClass"><h3>Loading...</h3></div>
				<div class="spacer"></div>
			</div> 

			<div id="linkStats">
				<div id="referDiv" class="fullStatsClass">
					<h4>Sites Linking to This Video:</h4>
	
						<div id="referersList">
														<div class="statItem"> <span class="label">2669 clicks from</span> <a rel="nofollow" href="http://5.gmodules.com/ig/ifr?pid=dell&amp;url=http://www.google.com/ig/modules/youtube_videos.xml&amp;nocache=0&amp;ifpcto" target="_top">http://5.gmodules.com/ig/ifr?pid=dell&amp;url=http:/...</a></div>
					<div class="statItem"> <span class="label">831 clicks from</span> <a rel="nofollow" href="http://3.gmodules.com/ig/ifr?pid=gatewayr&amp;url=http://www.google.com/ig/modules/youtube_videos.xml&amp;nocache=0&amp;if" target="_top">http://3.gmodules.com/ig/ifr?pid=gatewayr&amp;url=ht...</a></div>
					<div class="statItem"> <span class="label">344 clicks from</span> <a rel="nofollow" href="http://3.gmodules.com/ig/ifr?pid=emachines&amp;url=http://www.google.com/ig/modules/youtube_videos.xml&amp;nocache=0&amp;i" target="_top">http://3.gmodules.com/ig/ifr?pid=emachines&amp;url=h...</a></div>
					<div class="statItem"> <span class="label">270 clicks from</span> <a rel="nofollow" href="http://www.funnyjunk.com/youtube/1684/Memory+Game/" target="_top">http://www.funnyjunk.com/youtube/1684/Memory+Game/</a></div>
					<div class="statItem"> <span class="label">132 clicks from</span> <a rel="nofollow" href="http://www.google.com/ig?hl=en" target="_top">http://www.google.com/ig?hl=en</a></div>

						</div>
	
				</div>
				<div class="spacer"></div>
			</div> 

		</div> 

		<div id="recentRatingsDiv">
			<table cellspacing="0" cellpadding="0" align="center"><tr valign="top"><td class="lightLabel">
				Recent Ratings:
			&nbsp;
			</td>
			<td>
				<div class="recentRatingEntry">	
	<div>
		
	<img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt="">



	</div>

		<a href="/profile?user=SMILEYTRIX" class="dg smallText">SMILEYTRIX</a>
</div>
				<div class="recentRatingEntry">	
	<div>
		
	<img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt="">



	</div>

		<a href="/profile?user=NiNjAt0R" class="dg smallText">NiNjAt0R</a>
</div>
				<div class="recentRatingEntry">	
	<div>
		
	<img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt="">



	</div>

		<a href="/profile?user=ponygirllizzie" class="dg smallText">ponygirl...</a>
</div>
				<div class="recentRatingEntry">	
	<div>
		
	<img class="rating icn_star_grey_full_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt=""><img class="rating icn_star_grey_empty_11x11gif" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" style="vertical-align:top" alt="">



	</div>

		<a href="/profile?user=freespid3r" class="dg smallText">freespid3r</a>
</div>
			<div class="spacer">&nbsp;</div>
			</td></tr></table>
		</div> 
	</div> 

	


	<div id="commentsDiv">
			<table cellpadding="0" cellspacing="0" width="100%"><tr>
			<td><h2 style="margin: 0px;">Comments &amp; Responses</h2>
						<div style="margin:5px;">
		<form action="" name="comments_filter">
			<span class="smallText"><b>Show:</b></span>
			<select class="xsmallText" name="commentthreshold" onChange="showLoading('recent_comments', this.value);getUrlXMLResponseAndFillDiv('/watch_ajax?v=d8Arzv-8-Fg&amp;savethreshold=yes&amp;action_get_comments=1&amp;p=1&amp;page_size=10&amp;commentthreshold='+this.value, 'recent_comments');">
					<option  value="-1000">all comments</option>
				  <option  value="10">excellent (+10 or better)</option>
				  <option  value="5">great (+5 or better)</option>
				  <option  value="0">good (0 or better)</option>
				  <option  selected="selected"  value="-5">average (-5 or better)</option>
				  <option  value="-10">poor (-10 or better)</option>
			</select> 
			<span class="smallText">
				<a href="#" class="eLink" onClick="return false;" onMouseover="showDiv('commentsHelp');return false;" onMouseout="hideDiv('commentsHelp');">Help</a>
				<span id="commentsHelp" class="smallText commentsTooltip">
				Change this to see only comments above a certain value.<br>Change the value of a comment by clicking on a thumb.
				</span>
			</span>
		</form>
	</div>

			</td>
			<td align="right">
					<div style="padding-bottom: 2px;">
					<b><a href="/video_response_upload?v=d8Arzv-8-Fg" onclick="_hbLink('Post+Video+Response','Watch3');" rel="nofollow">Post a video response</a></b>
					</div>
						<div id="reply_main_comment2">
			<b><a href="#" class="eLink" onclick="showCommentReplyForm('main_comment2', '', false); _hbLink('Post+Text+Comment','Watch3'); return false;" id="post_text_comment_link" rel="nofollow">Post a text comment</a></b>
		</div>

			</td>
			</tr></table>

		<div id="div_main_comment2"></div>
		<div id="recent_comments">
								
	
	
	

		

			<div id="div_GyQveIjtlO0">
			<a name="GyQveIjtlO0"></a>
			<div class="commentEntry" id="comment_GyQveIjtlO0">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=nismogtp" rel="nofollow">nismogtp</a>
</b>
						<span class="smallText"> (8 minutes ago) </span>
						<span id="show_link_GyQveIjtlO0" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('GyQveIjtlO0');return false;">Show</a></span>

						<span id="hide_link_GyQveIjtlO0" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('GyQveIjtlO0'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_GyQveIjtlO0" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteGyQveIjtlO0" class="commentVoting floatR">
	 
		<b><span id="comment_score_GyQveIjtlO0" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('GyQveIjtlO0', 1);"  onMouseout="loginMsg('GyQveIjtlO0', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('GyQveIjtlO0', 1);"  onMouseout="loginMsg('GyQveIjtlO0', 0);"></a>
	<span id="comment_msg_GyQveIjtlO0" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_GyQveIjtlO0" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_GyQveIjtlO0">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_GyQveIjtlO0', 'GyQveIjtlO0', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_GyQveIjtlO0" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						when was this made 1920s?
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_GyQveIjtlO0"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_GIzLcrHr2Ww">
			<a name="GIzLcrHr2Ww"></a>
			<div class="commentEntry" id="comment_GIzLcrHr2Ww">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=sansisters" rel="nofollow">sansisters</a>
</b>
						<span class="smallText"> (29 minutes ago) </span>
						<span id="show_link_GIzLcrHr2Ww" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('GIzLcrHr2Ww');return false;">Show</a></span>

						<span id="hide_link_GIzLcrHr2Ww" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('GIzLcrHr2Ww'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_GIzLcrHr2Ww" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteGIzLcrHr2Ww" class="commentVoting floatR">
	 
		<b><span id="comment_score_GIzLcrHr2Ww" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('GIzLcrHr2Ww', 1);"  onMouseout="loginMsg('GIzLcrHr2Ww', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('GIzLcrHr2Ww', 1);"  onMouseout="loginMsg('GIzLcrHr2Ww', 0);"></a>
	<span id="comment_msg_GIzLcrHr2Ww" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_GIzLcrHr2Ww" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_GIzLcrHr2Ww">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_GIzLcrHr2Ww', 'GIzLcrHr2Ww', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_GIzLcrHr2Ww" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						i think i get it now after the fifth time i have watched it
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_GIzLcrHr2Ww"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_OJtkPcJts2Y">
			<a name="OJtkPcJts2Y"></a>
			<div class="commentEntry" id="comment_OJtkPcJts2Y">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=Pingaling766" rel="nofollow">Pingaling766</a>
</b>
						<span class="smallText"> (31 minutes ago) </span>
						<span id="show_link_OJtkPcJts2Y" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('OJtkPcJts2Y');return false;">Show</a></span>

						<span id="hide_link_OJtkPcJts2Y" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('OJtkPcJts2Y'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_OJtkPcJts2Y" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteOJtkPcJts2Y" class="commentVoting floatR">
	 
		<b><span id="comment_score_OJtkPcJts2Y" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('OJtkPcJts2Y', 1);"  onMouseout="loginMsg('OJtkPcJts2Y', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('OJtkPcJts2Y', 1);"  onMouseout="loginMsg('OJtkPcJts2Y', 0);"></a>
	<span id="comment_msg_OJtkPcJts2Y" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_OJtkPcJts2Y" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_OJtkPcJts2Y">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_OJtkPcJts2Y', 'OJtkPcJts2Y', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_OJtkPcJts2Y" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						oi u dumb ching <br/>stop wasting ure life on a useless game <br/>jeez, go buy a life<br/>thanks <br/>XD lol noob.
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_OJtkPcJts2Y"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_GKpAvVYFuNk">
			<a name="GKpAvVYFuNk"></a>
			<div class="commentEntry" id="comment_GKpAvVYFuNk">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=kixsbestfriend" rel="nofollow">kixsbestfriend</a>
</b>
						<span class="smallText"> (31 minutes ago) </span>
						<span id="show_link_GKpAvVYFuNk" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('GKpAvVYFuNk');return false;">Show</a></span>

						<span id="hide_link_GKpAvVYFuNk" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('GKpAvVYFuNk'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_GKpAvVYFuNk" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteGKpAvVYFuNk" class="commentVoting floatR">
	 
		<b><span id="comment_score_GKpAvVYFuNk" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('GKpAvVYFuNk', 1);"  onMouseout="loginMsg('GKpAvVYFuNk', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('GKpAvVYFuNk', 1);"  onMouseout="loginMsg('GKpAvVYFuNk', 0);"></a>
	<span id="comment_msg_GKpAvVYFuNk" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_GKpAvVYFuNk" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_GKpAvVYFuNk">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_GKpAvVYFuNk', 'GKpAvVYFuNk', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_GKpAvVYFuNk" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						this is kinda dumb<br/>why was it featured??<br/>what a waste of time...
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_GKpAvVYFuNk"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_L10eXSl4zII">
			<a name="L10eXSl4zII"></a>
			<div class="commentEntry" id="comment_L10eXSl4zII">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=Alligator2222" rel="nofollow">Alligator2222</a>
</b>
						<span class="smallText"> (44 minutes ago) </span>
						<span id="show_link_L10eXSl4zII" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('L10eXSl4zII');return false;">Show</a></span>

						<span id="hide_link_L10eXSl4zII" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('L10eXSl4zII'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_L10eXSl4zII" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteL10eXSl4zII" class="commentVoting floatR">
	
		<b><span id="comment_score_L10eXSl4zII" style="color:green" class="smallText">+2</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('L10eXSl4zII', 1);"  onMouseout="loginMsg('L10eXSl4zII', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('L10eXSl4zII', 1);"  onMouseout="loginMsg('L10eXSl4zII', 0);"></a>
	<span id="comment_msg_L10eXSl4zII" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_L10eXSl4zII" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_L10eXSl4zII">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_L10eXSl4zII', 'L10eXSl4zII', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_L10eXSl4zII" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						wtf was this... and why was it featured???? Very lame vid a waste of time...
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_L10eXSl4zII"></div>
				</div>
	</div>
	</div> 

				
				<div class="commentHead smallText opacity30" id="spam_comment_btn_1">			
					Comment(s) marked as spam <a href="#" class="eLink smallText" onclick="toggleVisibility('spam_comment_1', true); toggleVisibility('spam_comment_btn_1', false); toggleVisibility('spam_comment_hide_btn_1', true);  return false;" rel="nofollow">Show</a>
				</div>
				<div class="commentHead smallText opacity80" id="spam_comment_hide_btn_1" style="display: none">			
					Comment(s) marked as spam <a href="#" class="eLink smallText" onclick="toggleVisibility('spam_comment_1', false); toggleVisibility('spam_comment_btn_1', true); toggleVisibility('spam_comment_hide_btn_1', false);  return false;" rel="nofollow">Hide</a>
				</div>
				<div class="commentSpam" id="spam_comment_1" style="display: none">
		

			<div id="div_FQHUhKM8f40">
			<a name="FQHUhKM8f40"></a>
			<div class="commentEntry" id="comment_FQHUhKM8f40">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=soadtusek" rel="nofollow">soadtusek</a>
</b>
						<span class="smallText"> (45 minutes ago) </span>
						<span id="show_link_FQHUhKM8f40" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('FQHUhKM8f40');return false;">Show</a></span>

						<span id="hide_link_FQHUhKM8f40" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('FQHUhKM8f40'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_FQHUhKM8f40" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteFQHUhKM8f40" class="commentVoting floatR">
	 
	<b><span id="comment_score_FQHUhKM8f40" style="color:#FF3333" class="smallText">&nbsp;-1</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('FQHUhKM8f40', 1);"  onMouseout="loginMsg('FQHUhKM8f40', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('FQHUhKM8f40', 1);"  onMouseout="loginMsg('FQHUhKM8f40', 0);"></a>
	<span id="comment_msg_FQHUhKM8f40" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_FQHUhKM8f40" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_FQHUhKM8f40">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_FQHUhKM8f40', 'FQHUhKM8f40', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_FQHUhKM8f40" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						make some money while surfing<br/><br/>h t t p: / /b u x . t o / ? r = Nietzsche   (delete﻿ spaces)<br/><br/>it's all legal...just read what the site says.
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_FQHUhKM8f40"></div>
				</div>
	</div>
	</div> 

				</div>
		

			<div id="div_k6OWVyWl0dE">
			<a name="k6OWVyWl0dE"></a>
			<div class="commentEntry" id="comment_k6OWVyWl0dE">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=KyWyrm" rel="nofollow">KyWyrm</a>
</b>
						<span class="smallText"> (1 hour ago) </span>
						<span id="show_link_k6OWVyWl0dE" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('k6OWVyWl0dE');return false;">Show</a></span>

						<span id="hide_link_k6OWVyWl0dE" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('k6OWVyWl0dE'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_k6OWVyWl0dE" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVotek6OWVyWl0dE" class="commentVoting floatR">
	 
		<b><span id="comment_score_k6OWVyWl0dE" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('k6OWVyWl0dE', 1);"  onMouseout="loginMsg('k6OWVyWl0dE', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('k6OWVyWl0dE', 1);"  onMouseout="loginMsg('k6OWVyWl0dE', 0);"></a>
	<span id="comment_msg_k6OWVyWl0dE" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_k6OWVyWl0dE" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_k6OWVyWl0dE">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_k6OWVyWl0dE', 'k6OWVyWl0dE', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_k6OWVyWl0dE" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						I liked the video b(^_^)b very strange<br/><br/>type in "insouciant turtle dance"<br/>and watch my videos
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_k6OWVyWl0dE"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_K_z7P7g1Ma4">
			<a name="K_z7P7g1Ma4"></a>
			<div class="commentEntry" id="comment_K_z7P7g1Ma4">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=Sikhtiger" rel="nofollow">Sikhtiger</a>
</b>
						<span class="smallText"> (1 hour ago) </span>
						<span id="show_link_K_z7P7g1Ma4" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('K_z7P7g1Ma4');return false;">Show</a></span>

						<span id="hide_link_K_z7P7g1Ma4" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('K_z7P7g1Ma4'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_K_z7P7g1Ma4" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVoteK_z7P7g1Ma4" class="commentVoting floatR">
	
		<b><span id="comment_score_K_z7P7g1Ma4" style="color:green" class="smallText">+1</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('K_z7P7g1Ma4', 1);"  onMouseout="loginMsg('K_z7P7g1Ma4', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('K_z7P7g1Ma4', 1);"  onMouseout="loginMsg('K_z7P7g1Ma4', 0);"></a>
	<span id="comment_msg_K_z7P7g1Ma4" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_K_z7P7g1Ma4" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_K_z7P7g1Ma4">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_K_z7P7g1Ma4', 'K_z7P7g1Ma4', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_K_z7P7g1Ma4" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						I think that someone had to be pretty imaginative to understand that. So those of you confused, go back to browsing youtube for retarded videos. :/ <br/>For the rest of us, let's remember those people that sacrificed for us in the past. :)<br/><br/>P.S. Gandhi, Mother Teresa, Ann Frank, Einstein, John Lennon would be on the same level as MLKJ for me~ So God bless em all.
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_K_z7P7g1Ma4"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_3weNVgFX1ko">
			<a name="3weNVgFX1ko"></a>
			<div class="commentEntryReply" id="comment_3weNVgFX1ko">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=joninab" rel="nofollow">joninab</a>
</b>
						<span class="smallText"> (41 minutes ago) </span>
						<span id="show_link_3weNVgFX1ko" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('3weNVgFX1ko');return false;">Show</a></span>

						<span id="hide_link_3weNVgFX1ko" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('3weNVgFX1ko'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_3weNVgFX1ko" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVote3weNVgFX1ko" class="commentVoting floatR">
	 
		<b><span id="comment_score_3weNVgFX1ko" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('3weNVgFX1ko', 1);"  onMouseout="loginMsg('3weNVgFX1ko', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('3weNVgFX1ko', 1);"  onMouseout="loginMsg('3weNVgFX1ko', 0);"></a>
	<span id="comment_msg_3weNVgFX1ko" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_3weNVgFX1ko" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_3weNVgFX1ko">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_3weNVgFX1ko', '3weNVgFX1ko', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_3weNVgFX1ko" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						was the second card ghandi?
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_3weNVgFX1ko"></div>
				</div>
	</div>
	</div> 

		

			<div id="div_3pA0nWd5OjE">
			<a name="3pA0nWd5OjE"></a>
			<div class="commentEntry" id="comment_3pA0nWd5OjE">
					<div class="commentHead">
					<div class="floatL padT3">
						<b>  <a href="/profile?user=vic028" rel="nofollow">vic028</a>
</b>
						<span class="smallText"> (1 hour ago) </span>
						<span id="show_link_3pA0nWd5OjE" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayHideCommentLink('3pA0nWd5OjE');return false;">Show</a></span>

						<span id="hide_link_3pA0nWd5OjE" style="visibility:hidden;"><a href="#" class="marL8 eLink smallText" rel="nofollow" onclick="displayShowCommentLink('3pA0nWd5OjE'); return false;">Hide</a></span>  

						<span id="comment_spam_bug_3pA0nWd5OjE" class="commentSpamBug" style="display: none;">Marked as spam</span>
									
					</div>
							<div id="CommentVote3pA0nWd5OjE" class="commentVoting floatR">
	 
		<b><span id="comment_score_3pA0nWd5OjE" style="color:gray" class="smallText"> 0</span></b>

		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentDown" title="Poor comment" alt="Good comment" onMouseover="loginMsg('3pA0nWd5OjE', 1);"  onMouseout="loginMsg('3pA0nWd5OjE', 0);"></a>
		<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="opacity30 commentIcon commentUp" title="Good comment" alt="Poor comment" onMouseover="loginMsg('3pA0nWd5OjE', 1);"  onMouseout="loginMsg('3pA0nWd5OjE', 0);"></a>
	<span id="comment_msg_3pA0nWd5OjE" class="floatR smallText grayText"></span>&nbsp;
	</div>

					<div class="commentAction smallText padT3 floatR">
						
	<div class="commentAction smallText" id="container_comment_form_id_3pA0nWd5OjE" style="display: none"> </div>
		<div class="commentAction smallText" id="reply_comment_form_id_3pA0nWd5OjE">
				<a href="#" onclick="showCommentReplyForm('comment_form_id_3pA0nWd5OjE', '3pA0nWd5OjE', false); return false;" class="eLink" rel="nofollow">Reply</a> 






		</div>
		<div>
	</div>

					</div>
				<div class="clear"></div>
			</div>
				<div id="comment_body_3pA0nWd5OjE" style="display: block ">
					<div  class="commentBody marL8 normalText" style="width:75%;">
						come on people its obviously dedicated to "the last card"<br/><br/>ahahah i wont spoil the ending, you have to spend all 3:21 mins of it to find out!
					</div>
					<div class="clear"></div>
					<div id="div_comment_form_id_3pA0nWd5OjE"></div>
				</div>
	</div>
	</div> 



		<div class="commentPagination">
<div class="floatR">

<span class="commentPnum"><a href="#" onclick="showLoading('recent_comments');;getUrlXMLResponseAndFillDiv('/watch_ajax?v=d8Arzv-8-Fg&action_get_comments=1&p=2&commentthreshold=-5&page_size=10', 'recent_comments'); return false;">Next</a></span>
</div>

<div class="floatL">
	<span class="commentPnum">Pages:</span>
			<span class="commentPnum">1</span>
			<span class="commentPnum"><a href="#" onclick="showLoading('recent_comments');getUrlXMLResponseAndFillDiv('/watch_ajax?v=d8Arzv-8-Fg&action_get_comments=1&p=2&commentthreshold=-5&page_size=10', 'recent_comments'); return false;">2</a></span>
			<span class="commentPnum"><a href="#" onclick="showLoading('recent_comments');getUrlXMLResponseAndFillDiv('/watch_ajax?v=d8Arzv-8-Fg&action_get_comments=1&p=3&commentthreshold=-5&page_size=10', 'recent_comments'); return false;">3</a></span>
		&#160;...&#160;
		</b>
</div>
<div class="clear"></div>
</div>


		</div> <!-- end recent_comments -->

		<b><a href="/comment_servlet?all_comments&amp;v=d8Arzv-8-Fg&amp;fromurl=/watch%3Fv%3Dd8Arzv-8-Fg" onclick="_hbLink('View+All+Comments','Watch3');" rel="nofollow">View all 750 comments</a></b>




		<div id="commentPostDiv">
			<h2 style="margin: 0px;">Would you like to comment?</h2>
			<div style="margin-top: 8px;">
				<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg">Join YouTube</a> for a free account, or
				<a href="/signup?next=/watch%3Fv%3Dd8Arzv-8-Fg">log in</a> if you are already a member.
			</div>
		</div> <!-- end post a comment section -->
		
		<div id="div_main_comment"></div>
	
</div> 


</div> 
</td>



<td id="otherVidsCell">

<div id="otherVidsDiv">
	<div id="channelVidsDiv" class="wsWrapper">
		<div id="channelVidsTop">
			<table cellpadding="0" cellspacing="0" width="100%"><tr valign="top">
			<td width="1%" class="padR5">
			<div class="channelIconWrapper"><div class="channelIcon"><a href="/user/WildHorseSociety" onclick="_hbLink('ChannelIconLink','Watch3ChannelVideos');"><img src="http://i.ytimg.com/i/NZqjhqF8wuxO-lAXQbF4SQ/1.jpg" alt="Channel Icon" /></a></div></div>
			</td>
			<td>
			<div class="wsHeading">
				<span class="normalLabel">From: </span>
			  <a href="/profile?user=WildHorseSociety" onclick="_hbLink('ChannelNameLink','Watch3ChannelVideos');">WildHorseSociety</a>

			</div>
			<div id="subscribeDiv">
				<a class="subButton" onclick="subscribe(watchUsername, subscribeaxc); return false;" title="subscribe to WildHorseSociety's videos">
					<b><b><b>Subscribe</b></b></b>
				</a>
			</div> 
			<div id="unsubscribeDiv" class="hid">
				<a class="profileUnsubButton" onclick="unsubscribe(watchUsername, subscribeaxc); return false;">
					<b><b><b>Unsubscribe</b></b></b>
				</a>
			</div>
			<div id="channelStats">
				<span class="label">Joined:</span>
				1 year ago
				<br>
				<span class="label">Videos:</span>
				3
			</div>
			</td>
			</tr></table>
			<div class="spacer">&nbsp;</div>
		</div> 
			<div id="videoDetailsDiv" class="expand-container">
		<a href="#" class="expand-header" onClick="toggleClass(_gel('videoDetailsDiv'), 'expanded'); return false;"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="arrow" alt="" />About This Video</a>

		<table width="100%" cellpadding="0" cellspacing="0"><tr valign="top"><td>
		<div  class="videoDescDiv collapse-content">
			The Wild Horses found this one in our "made for...<a href="http://www.headphonerecord.com" target="_blank" title="http://www.headphonerecord.com" rel="nofollow"></a><a href="http://www.ndsweatshops.com" target="_blank" title="http://www.ndsweatshops.com" rel="nofollow"></a><a href="http://indiepixfilms.com/highlife" target="_blank" title="http://indiepixfilms.com/highlife" rel="nofollow"></a> (<a href="#" onclick="addClass(_gel('videoDetailsDiv'), 'expanded'); return false;" class="smallText eLink">more</a>)
		</div>
		<div class="collapse-content">
			<span class="smallLabel">Added:</span>
			<span class="smallText">May 27, 2007</span>
		</div>
		<div  class="videoDescDiv expand-content">
			The Wild Horses found this one in our "made for sesame street" vault. But remember folks, you dont have to wait for a holiday to think about your heroes. <br/><br/>The Wild Horse Society is a collaboration between acclaimed San Francisco artist/dj Nathalie Roland <a href="http://www.headphonerecord.com" target="_blank" title="http://www.headphonerecord.com" rel="nofollow">http://www.headphonerecord.com</a> and award-winning Brooklyn-based filmmaker Lila Yomtoob <a href="http://www.ndsweatshops.com" target="_blank" title="http://www.ndsweatshops.com" rel="nofollow">http://www.ndsweatshops.com</a> Visit IndiePixFilms <a href="http://indiepixfilms.com/highlife" target="_blank" title="http://indiepixfilms.com/highlife" rel="nofollow">http://indiepixfilms.com/highlife</a> <br/>to learn more about Yomtoob's critically praised feature "High Life". 
			(<a href="#" onclick="removeClass(_gel('videoDetailsDiv'), 'expanded'); return false;" class="smallText eLink">less</a>)
		</div>
	
		<div class="expand-content">
			<div>
				<span class="smallLabel">Added:</span>
				<span class="smallText">May 27, 2007</span>
			</div>
			<div>
				<span class="smallLabel">Category:&nbsp;</span>
				<a href="/browse?s=mp&amp;t=t&amp;c=1" class="dg smallText" onclick="_hbLink('VideoCategoryLink','Watch3VideoDetails');">Film & Animation</a>
			</div>
			<div>
				<table cellpadding="0" cellspacing="0"><tr valign="top">
				<td class="smallLabel" nowrap>Tags:&nbsp;&nbsp;</td>
				<td class="tagValues smallText">
					<a href="/results?search_query=MLK&amp;amp;search=tag" class="dg">MLK</a> &nbsp;
					<a href="/results?search_query=tribute&amp;amp;search=tag" class="dg">tribute</a> &nbsp;
					<a href="/results?search_query=nathalie&amp;amp;search=tag" class="dg">nathalie</a> &nbsp;
					<a href="/results?search_query=roland&amp;amp;search=tag" class="dg">roland</a> &nbsp;
					<a href="/results?search_query=lila&amp;amp;search=tag" class="dg">lila</a> &nbsp;
					<a href="/results?search_query=yomtoob&amp;amp;search=tag" class="dg">yomtoob</a> &nbsp;
					<a href="/results?search_query=memory&amp;amp;search=tag" class="dg">memory</a> &nbsp;
					<a href="/results?search_query=game&amp;amp;search=tag" class="dg">game</a> &nbsp;
					<a href="/results?search_query=cards&amp;amp;search=tag" class="dg">cards</a> &nbsp;
					<a href="/results?search_query=heroes&amp;amp;search=tag" class="dg">heroes</a> &nbsp;
					<a href="/results?search_query=hero&amp;amp;search=tag" class="dg">hero</a> &nbsp;
					<a href="/results?search_query=animation&amp;amp;search=tag" class="dg">animation</a> &nbsp;
					<a href="/results?search_query=wild&amp;amp;search=tag" class="dg">wild</a> &nbsp;
					<a href="/results?search_query=horse&amp;amp;search=tag" class="dg">horse</a> &nbsp;
					<a href="/results?search_query=society&amp;amp;search=tag" class="dg">society</a> &nbsp;
				</td></tr></table>
			</div>

			<div id="urlDiv">
			<table cellpadding="0" cellspacing="0"><tr>
				<td class="smallLabel">URL</td>
			</tr>
			<tr>
				<td>
				<form action="" name="urlForm" id="urlForm">
				<input name="video_link" class="urlField" type="text" value="http://youtube.com/watch?v=d8Arzv-8-Fg" onClick="javascript:document.urlForm.video_link.focus();document.urlForm.video_link.select();" readonly style="width: 340px;margin-top: 2px;">
				</form>
				</td>
			</tr></table>
			</div>
		</div> 
		</td></tr></table>

		<script type="text/javascript">
			function generateEmbed()
			{                                                                          
					var query = '';
					if (document.embedCustomizeForm.embedCustomization[0].checked) { 
						query += '&rel=1';
					} else {
						query += '&rel=0';
					}
				    switch (selectedThemeColor)
					{
						case 'blank':
							query += '&color1=0xd6d6d6&color2=0xf0f0f0';
							break;
						case 'storm':
							query += '&color1=0x3a3a3a&color2=0x999999';
							break;
						case 'iceberg':
							query += '&color1=0x2b405b&color2=0x6b8ab6';
							break;
						case 'acid':
							query += '&color1=0x006699&color2=0x54abd6';
							break;
						case 'green':
							query += '&color1=0x234900&color2=0x4e9e00';
							break;
						case 'orange':
							query += '&color1=0xe1600f&color2=0xfebd01';
							break;
						case 'pink':
							query += '&color1=0xcc2550&color2=0xe87a9f';
							break;
						case 'purple':
							query += '&color1=0x402061&color2=0x9461ca';
							break;
						case 'rubyred':
							query += '&color1=0x5d1719&color2=0xcd311b';
							break;
					}
				 
					var showBorder = (document.embedCustomizeForm.show_border_checkbox.checked);
					query+= '&border=' + (showBorder ? '1' : '0');
					var height = (showBorder ? 373 : 355);
					
					var embedCode = '<object width="425" height="' + height + '"><param name="movie" value="http://www.youtube.com/v/d8Arzv-8-Fg' + query + '"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/d8Arzv-8-Fg' + query +'" type="application/x-shockwave-flash" wmode="transparent" width="425" height="' + height + '"></embed></object>';
					document.embedForm.embed_code.value = embedCode;
				}
			</script>

		<div id="embedDiv" >
		<table width="100%" cellspacing="0" cellpadding="0">
			<tr>
				<td nowrap>
					<label for="embed_code" class="label">Embed</label>&nbsp;
				</td>
				<td align="right" nowrap>
					<span class="floatR padB1"><a href="#" class="eLink" onclick="customizeEmbed(); _hbLink('CustomizeEmbed','Watch3Embed'); return false;">customize</a></span>
				</td>
			</tr>
				<tr>
				<td colspan="2" align="right">
					<form action="" name="embedForm" id="embedForm">
						<input id="embed_code" name="embed_code" class="embedField" type="text" value='&lt;object width=&quot;425&quot; height=&quot;355&quot;&gt;&lt;param name=&quot;movie&quot; value=&quot;http://www.youtube.com/v/d8Arzv-8-Fg&amp;rel=1&quot;&gt;&lt;/param&gt;&lt;param name=&quot;wmode&quot; value=&quot;transparent&quot;&gt;&lt;/param&gt;&lt;embed src=&quot;http://www.youtube.com/v/d8Arzv-8-Fg&amp;rel=1&quot; type=&quot;application/x-shockwave-flash&quot; wmode=&quot;transparent&quot; width=&quot;425&quot; height=&quot;355&quot;&gt;&lt;/embed&gt;&lt;/object&gt;' onClick="javascript:document.embedForm.embed_code.focus();document.embedForm.embed_code.select();" readonly style="width: 340px; margin-top: 2px;">
					</form>
				</td>
				</tr>
		</table>
	</div> 

	<form id="customizeEmbedDiv" name="embedCustomizeForm">
		<div id="customizeEmbedTheme">
			<img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" id="customizeEmbedThemePreview" />
			<div id="customizeEmbedDesc">
			After making your selection, copy and paste the embed code above. The code changes based on your selection.
			</div>
			<div id="customizeEmbedForm">
				<input type="radio" name="embedCustomization" id="embedCustomization1" onClick="onChangeRelated(true);generateEmbed();" checked>
				<label for="embedCustomization1">Include related videos</label><br/>
				<input type="radio" name="embedCustomization" id="embedCustomization0" onClick="onChangeRelated(false);generateEmbed();">
				<label for="embedCustomization0">Don't include related videos</label><br/>
			</div>
			<div id="customizeEmbedThemeSwatches">
				<a id="theme_color_blank_img" href="#" class="imageRadioLink radio_selected" onClick="onChangeColor('blank'); generateEmbed(); return false;"><img class="embedSel embed_classic" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Blank"  /></a>
				<a id="theme_color_storm_img" href="#" class="imageRadioLink" onClick="onChangeColor('storm'); generateEmbed(); return false;"><img class="embedSel embed_gray" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Storm" /></a>
				<a id="theme_color_iceberg_img" href="#" class="imageRadioLink" onClick="onChangeColor('iceberg'); generateEmbed(); return false;"><img class="embedSel embed_blue" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Iceberg" /></a>
				<a id="theme_color_acid_img" href="#" class="imageRadioLink" onClick="onChangeColor('acid'); generateEmbed(); return false;"><img class="embedSel embed_cyan" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Acid" /></a>
				<a id="theme_color_green_img" href="#" class="imageRadioLink" onClick="onChangeColor('green'); generateEmbed(); return false;"><img class="embedSel embed_green" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Green" /></a>
				<a id="theme_color_orange_img" href="#" class="imageRadioLink" onClick="onChangeColor('orange'); generateEmbed(); return false;"><img class="embedSel embed_orange" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Orange" /></a>
				<a id="theme_color_pink_img" href="#" class="imageRadioLink" onClick="onChangeColor('pink'); generateEmbed(); return false;"><img class="embedSel embed_pink" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Pink" /></a>
				<a id="theme_color_purple_img" href="#" class="imageRadioLink" onClick="onChangeColor('purple'); generateEmbed(); return false;"><img class="embedSel embed_purple" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Purple" /></a>
				<a id="theme_color_rubyred_img" href="#" class="imageRadioLink" onClick="onChangeColor('rubyred'); generateEmbed(); return false;"><img class="embedSel embed_red" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="Ruby Red" /></a>
				<div style="clear: both; margin: 0px 0px 0px 4px;">
					<input type="checkbox" name="show_border_checkbox" id="show_border_checkbox" onChange="onChangeBorder(this.checked);generateEmbed();" /><label for="show_border_checkbox">Show Border</label>
				</div>
			</div>
		</div> 
		<div class="alignR smallText">(<a href="#" class="eLink" onclick="closeDiv('customizeEmbedDiv'); return false;">close</a>)</div>
	</form> 

		<div id="attributionsDiv">
	

	
		</div> 





	</div> 


	</div> 

	<div id="channelVidsBody" class="wsWrapper">
		<div>	<div class="wsHeading" style="clear:both">
		<a href="#" class="expandLink" 
				onclick="toggleDisplay2(this.childNodes[0], this.childNodes[1]);this.blur();toggleChannelVideos('WildHorseSociety'); return false;"><img 
				src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="" height="16" width="16" class="arrowDown" style="display:none"/><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="" height="16" width="16" class="arrowRight" style=""
				/>More From: WildHorseSociety
</a>
	</div>
	<div id="channel_videos_full" class="wsBody hide" style="min-height:62px; height:auto;">
			<div class="alignC">Loading...</div>
	</div>
</div>
	</div>

 	
 	<div id="quicklistDiv" class="hide">
 			<div class="wsWrapper" style="width:360px">
		<div id="playlistClosed_QL" style="display:none">
			<div class="wsHeading">
				<b><a href="#" class="wsHeading expandLink" onclick="return showPlaylist('QL')" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="" height="16" width="16" class="arrowRight" />QuickList</a></b>
			</div>
		</div>

		<div id="playlistOpen_QL">
			<div class="wsHeading">
				<div style="float:left">
				<b><a href="#" class="wsHeading expandLink" onclick="return hidePlaylist('QL')" rel="nofollow"><img src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="" height="16" width="16" class="arrowDown" />QuickList</a></b>
				</div>
				<div style="float:right">
					<span id="playlistVideoCount_QL" class="smallText grayText">0</span>
					<span class="smallText grayText">videos</span>
					<span style="padding-left:5px; font-weight:bold;" id="playall_QL" class="smallText ">
						<a href="#" onclick="return autoNext('QL');" rel="nofollow" >Play All</a>
					</span>
					<span style="padding-left:5px; font-weight:bold;" id="playingall_QL" class="smallText hide">
						<a href="#" onclick="return autoNextOff('QL');" rel="nofollow" >Stop Autoplaying</a>
					</span>
				</div>
				<div style="clear:both"></div>
			</div> 


			<div id="playlistContainer_QL" class="watchSectionBody playlistContainer autoHeight">
				<div id="playlistRows_QL">
								

	<div id="playlistRow_placeholder_QL" class="hide playlistRow   ">
		<a href="" class="playlistRowLink" onclick="window.location=this.href; return false;">
			<div class="playlistIndex">
					<span id="playlistRowIndex_placeholder_QL" class="phIndex"> 1</span>
			</div>
			<div class="playlistRowLeft"><div class="v50WrapperOuter"><div class="v50WrapperInner">
				<img class="vimg50" src="http://youtube.com/img/pixel.gif" alt=""/>
			</div></div></div>
			<div class="playlistRowMiddle">
				<div class="vtitle" style="text-decoration:underline;">
					
				</div>
				<div class="vfacets phUsername" style="color:black">
					
				</div>
			</div>
		</a>
		<div class="playlistRowRight">
			<a class="playlistShowRelated" href="#relatedVidsBody"
			onclick="quickListShowRelated(this);">Related</a>
			<span class="playlistItemDuration">
				
			</span>			<img class="playlistRowDeleter" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" onclick="removeVideo('QL', this)" alt=""/>
		</div>	
	</div>

	
		

	

				</div>
			</div>
		
				<div id="playlistActions">
					<span class="smallText">
						<a href="/edit_playlist_info?watch_queue=1" title="Save all videos into a permanent playlist" onclick="_hbLink('QuickList+SaveLink','Watch3');" rel="nofollow">Save</a> |
						<a href="#" onClick="clearWatchQueue();_hbLink('QuickList+ClearLink','Watch3');return false;" title="Remove all videos from QuickList" rel="nofollow">Clear</a>
					</span>
				</div>
		</div>
	</div> 

 	</div>
 

	<div class="wsWrapper">
		<div id="relatedVidsToggle" style="display: block;">
			<span class="smallLabel">Display:</span><img id="relatedList" title="List View" alt="List View" src="http://static.youtube.com/yt/img/pixel-vfl73.gif"><a href="#" onclick="return showRelatedAsGrid()"><img id="relatedNotGrid" title="Grid View" alt="Grid View" src="http://static.youtube.com/yt/img/pixel-vfl73.gif"></a><a href="#" onclick="return showRelatedAsList()"><img id="relatedNotList" title="List View" alt="List View" class="hide" src="http://static.youtube.com/yt/img/pixel-vfl73.gif"></a><img id="relatedGrid" class="hide" title="Grid View" alt="Grid View" src="http://static.youtube.com/yt/img/pixel-vfl73.gif">
		</div>
		<div class="wsHeading">
			<a href="#" onclick="toggleDisplay2('relatedVidsToggle', 'relatedVidsBodyContainer', this.childNodes[0], this.childNodes[1]); this.blur(); return false;" class="expandLink"><img 
				src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="" height="16" width="16" class="arrowRight" style="display: none" /><img 
				src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="" height="16" width="16" class="arrowDown" />Related Videos</a>
		</div>
		<div class="wsBody" id="relatedVidsBodyContainer" style="display: block;">
			<div id="relatedVidsBody" style="padding-top: 0px;">
						<div style="padding-top:7px; height:302px; overflow:auto" onscroll="performDelayLoad('related')">
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=TfMkzRwfGiU&feature=related"  rel="nofollow"><img   src="http://i.ytimg.com/vi/TfMkzRwfGiU/default.jpg" class="vimg90" qlicon="TfMkzRwfGiU" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=TfMkzRwfGiU&feature=related">	Beach Impeach </a></div>
			<div>
				<span class="smallText"> 03:10 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=WildHorseSociety" >WildHorseSociety</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">3,424</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=-2X1C-kjXW8&feature=related"  rel="nofollow"><img   src="http://i.ytimg.com/vi/-2X1C-kjXW8/default.jpg" class="vimg90" qlicon="-2X1C-kjXW8" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=-2X1C-kjXW8&feature=related">	Street Vault Runway Trial </a></div>
			<div>
				<span class="smallText"> 00:07 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=medicathlete" >medicathlete</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">2,600</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=pERnJns5zOU&feature=related"  rel="nofollow"><img   src="http://i.ytimg.com/vi/pERnJns5zOU/default.jpg" class="vimg90" qlicon="pERnJns5zOU" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=pERnJns5zOU&feature=related">	A Memory Game For the whole family! </a></div>
			<div>
				<span class="smallText"> 00:42 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=seekandfind1" >seekandfind1</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">2,649</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=05YeDOkDGso&feature=related"  rel="nofollow"><img   src="http://i.ytimg.com/vi/05YeDOkDGso/default.jpg" class="vimg90" qlicon="05YeDOkDGso" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=05YeDOkDGso&feature=related">	Memory Cards </a></div>
			<div>
				<span class="smallText"> 00:03 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=koloa32" >koloa32</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">2,582</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=IvhVI-D3ivc&feature=related"  rel="nofollow"><img   src="http://i.ytimg.com/vi/IvhVI-D3ivc/default.jpg" class="vimg90" qlicon="IvhVI-D3ivc" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=IvhVI-D3ivc&feature=related">	Mac Daddy </a></div>
			<div>
				<span class="smallText"> 02:00 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=HappySlip" >HappySlip</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">593,377</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=lmL0vWKnDdI&feature=related"  rel="nofollow"><img   src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="vimg90"
					onload="delayLoad('related', this, 'http://i.ytimg.com/vi/lmL0vWKnDdI/default.jpg')" qlicon="lmL0vWKnDdI" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=lmL0vWKnDdI&feature=related">	Simon Memory Game Commercial </a></div>
			<div>
				<span class="smallText"> 00:29 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=retroist" >retroist</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">1,952</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=HlSOKalCkPI&feature=related"  rel="nofollow"><img   src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="vimg90"
					onload="delayLoad('related', this, 'http://i.ytimg.com/vi/HlSOKalCkPI/default.jpg')" qlicon="HlSOKalCkPI" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=HlSOKalCkPI&feature=related">	Please Stop Horse slaughter! </a></div>
			<div>
				<span class="smallText"> 04:41 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=Horses4Alisa94" >Horses4Alisa94</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">35,903</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=iABtHkcRdjc&feature=related"  rel="nofollow"><img   src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="vimg90"
					onload="delayLoad('related', this, 'http://i.ytimg.com/vi/iABtHkcRdjc/default.jpg')" qlicon="iABtHkcRdjc" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=iABtHkcRdjc&feature=related">	Funny Videos -- MEMORY GAME!!! (Part 1) </a></div>
			<div>
				<span class="smallText"> 04:50 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=kvn620" >kvn620</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">633</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=yU7SuQpgXTk&feature=related"  rel="nofollow"><img   src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="vimg90"
					onload="delayLoad('related', this, 'http://i.ytimg.com/vi/yU7SuQpgXTk/default.jpg')" qlicon="yU7SuQpgXTk" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=yU7SuQpgXTk&feature=related">	5 Year Old Genius playing a Simon Memory Game </a></div>
			<div>
				<span class="smallText"> 05:08 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=aaroncohen" >aaroncohen</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">151,145</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div style="float:left;">
					<div class="v90WideEntry">
		<div class="v90WrapperOuter"><div class="v90WrapperInner">





				<a href="/watch?v=1FnLM15Hc2Y&feature=related"  rel="nofollow"><img   src="http://static.youtube.com/yt/img/pixel-vfl73.gif" class="vimg90"
					onload="delayLoad('related', this, 'http://i.ytimg.com/vi/1FnLM15Hc2Y/default.jpg')" qlicon="1FnLM15Hc2Y" alt=""></a>
		</div></div>
	</div>

		</div>
		<div style="margin-left:100px; margin-right: 5px;">
			<div  class="vtitle"><a href="/watch?v=1FnLM15Hc2Y&feature=related">	MLK - dream baby dream </a></div>
			<div>
				<span class="smallText"> 06:53 </span>
				<span class="smallLabel">From:</span>	<span>  <a href="/profile?user=francez123" >francez123</a>
</span>
			</div>
			<div><span class="smallLabel">Views:</span> <span class="smallText">1,797</span></div>

		</div>
		<div class="relatedDivider"></div>
		<div class="alignC padT5 padB10 bold">
			<a href="/results?search=related&search_query=%20MLK%20tribute%20nathalie%20roland%20lila%20yomtoob%20memory%20game%20cards%20heroes%20hero%20animation%20wild%20horse%20society&v=d8Arzv-8-Fg">See all 29 videos</a>
		</div>
	</div>

			</div> 
		</div>
	</div> 

	<div class="wsWrapper">
		<div class="wsHeading">Promoted Videos</div>
		<div class="marT5" id="promotedVidsContainer" style="display: block;">
			<table cellpadding="0" cellspacing="0" width="100%"><tr valign="top">
				<td>
						<div class="v75WideEntry">
		<div class="v75WrapperOuter"><div class="v75WrapperInner">



				<a href="/cthru?WFjeRZFU5viIAPBTiu-lcYxVSPcu5IntQ-HI8gMaAPafazRRWXEY0hS6VNjKJ6HwoBRgV55XxSrKvXQeNDlFKYhLMqLg2wnjywI4YQd5JQ48oEpDSQyRefroGbj2rBjGPaxmkCOpCo7n9c1ZAy6Q9sawpHvNfQm2RdS36vlAtL8_-5tCzWNzOTAczYy3jy5-HgOoGsMNAVHeHyZUiKRXAw==" name='&amp;lid=DV+-+ceslosersmacbookairmusicfilesharing+-+jetsetshow&amp;lpos=Watch3-s0' onclick="_hbLink('DV+-+ceslosersmacbookairmusicfilesharing+-+jetsetshow', 'Watch3-s0');" rel="nofollow"><img src="http://i.ytimg.com/vi/J7f5MRkJho0/default.jpg" class="vimg75"  alt=""></a>
		</div></div>

		<!--div class="vtitle smallText" style="font-weight: normal;"-->
		<div >
			<a href="/cthru?WFjeRZFU5viIAPBTiu-lcYxVSPcu5IntQ-HI8gMaAPafazRRWXEY0hS6VNjKJ6HwoBRgV55XxSrKvXQeNDlFKYhLMqLg2wnjywI4YQd5JQ48oEpDSQyRefroGbj2rBjGPaxmkCOpCo7n9c1ZAy6Q9sawpHvNfQm2RdS36vlAtL8_-5tCzWNzOTAczYy3jy5-HgOoGsMNAVHeHyZUiKRXAw==" target="_parent" name='&amp;lid=DV+-+ceslosersmacbookairmusicfilesharing+-+jetsetshow&amp;lpos=Watch3-s0' rel="nofollow">ces losers, macbo...</a>
		</div>

			<span class="runtime" style="font-weight: normal">05:42</span>

			<div class="">
				<span class="grayText"></span>  <a href="/profile?user=jetsetshow" class="dg" rel="nofollow">jetsetshow</a>
<br/>
			</div>
		</div>

				</td>
				<td>
						<div class="v75WideEntry">
		<div class="v75WrapperOuter"><div class="v75WrapperInner">



				<a href="/cthru?L0y0jZYdh74vIQvbaGC8aTRrEVpl7MIQqx6Clh4tzLcODCPJLesJWNy2xJvl-59TP7o6eMyHsi_TOW4k_m9Z9_l-XQ1auxwczJx9cY8SUCrxmmguBVFR5k_BXu8cjolD1sQKxntgAY0O5H2TbQaDzI7QvFbrzZ6NcYzFeu8-HLCk43YA7V-sA2C9KMXh0O9djBIk04ZlFTMHX6sO_DGnJg==" name='&amp;lid=DV+-+SUNDANCE08MYPREMIEREINBRUGES+-+sundancechannel&amp;lpos=Watch3-s1' onclick="_hbLink('DV+-+SUNDANCE08MYPREMIEREINBRUGES+-+sundancechannel', 'Watch3-s1');" rel="nofollow"><img src="http://i.ytimg.com/vi/ADkBZ4_9Lzc/default.jpg" class="vimg75"  alt=""></a>
		</div></div>

		<!--div class="vtitle smallText" style="font-weight: normal;"-->
		<div >
			<a href="/cthru?L0y0jZYdh74vIQvbaGC8aTRrEVpl7MIQqx6Clh4tzLcODCPJLesJWNy2xJvl-59TP7o6eMyHsi_TOW4k_m9Z9_l-XQ1auxwczJx9cY8SUCrxmmguBVFR5k_BXu8cjolD1sQKxntgAY0O5H2TbQaDzI7QvFbrzZ6NcYzFeu8-HLCk43YA7V-sA2C9KMXh0O9djBIk04ZlFTMHX6sO_DGnJg==" target="_parent" name='&amp;lid=DV+-+SUNDANCE08MYPREMIEREINBRUGES+-+sundancechannel&amp;lpos=Watch3-s1' rel="nofollow">SUNDANCE '08 - MY...</a>
		</div>

			<span class="runtime" style="font-weight: normal">04:00</span>

			<div class="">
				<span class="grayText"></span>  <a href="/profile?user=sundancechannel" class="dg" rel="nofollow">sundancecha...</a>
<br/>
			</div>
		</div>

				</td>
				<td>
						<div class="v75WideEntry">
		<div class="v75WrapperOuter"><div class="v75WrapperInner">



				<a href="/cthru?1Xcs_CL5NHmbCjhR3ndz86y-TELehh7ZyIppbANIWgMk5UV2Jbi9vcElNb1kPIfg-0qOaXd635yVnvkwshd_osI5Pf5b5aAPK88K4Wg09DP0igKc1wghtEPeLH3EpkYiBKdClGnAKEonhamm96kKELr0rmBXYgMk6R_6-esPvLqoZRxf8tla3DfgBDF0l1AAM97rzUHdCgs=" name='&amp;lid=DV+-+NorthKCToGetStudentTrackingSystem+-+kmbctv&amp;lpos=Watch3-s2' onclick="_hbLink('DV+-+NorthKCToGetStudentTrackingSystem+-+kmbctv', 'Watch3-s2');" rel="nofollow"><img src="http://i.ytimg.com/vi/sEf83Z6YpQA/default.jpg" class="vimg75"  alt=""></a>
		</div></div>

		<!--div class="vtitle smallText" style="font-weight: normal;"-->
		<div >
			<a href="/cthru?1Xcs_CL5NHmbCjhR3ndz86y-TELehh7ZyIppbANIWgMk5UV2Jbi9vcElNb1kPIfg-0qOaXd635yVnvkwshd_osI5Pf5b5aAPK88K4Wg09DP0igKc1wghtEPeLH3EpkYiBKdClGnAKEonhamm96kKELr0rmBXYgMk6R_6-esPvLqoZRxf8tla3DfgBDF0l1AAM97rzUHdCgs=" target="_parent" name='&amp;lid=DV+-+NorthKCToGetStudentTrackingSystem+-+kmbctv&amp;lpos=Watch3-s2' rel="nofollow">North KC To Get S...</a>
		</div>

			<span class="runtime" style="font-weight: normal">02:11</span>

			<div class="">
				<span class="grayText"></span>  <a href="/profile?user=kmbctv" class="dg" rel="nofollow">kmbctv</a>
<br/>
			</div>
		</div>

				</td>
				<td>
						<div class="v75WideEntry">
		<div class="v75WrapperOuter"><div class="v75WrapperInner">



				<a href="/cthru?ni0qShFybgHpOBPUfyMX4pfvgXr_rQF24kuZUNz6xr8r7qHVGynYkoBtR1qa2YD3RKJtsTJh3LeUB3h1svacowv_otZZAQu-b6mMk6-HzVOfG7HuDhl-hdGlRbI3eHLNBxOa6w0p9x2vZ9kOu-VegSGXuPAf98vWY3F03QiCg6JEXf7iYgo14q2hDXObG0YvaA6dlI60sV9jDP9DvXKZqg==" name='&amp;lid=DV+-+SUNDANCE08INTERVIEWSAVAGEGRACE+-+sundancechannel&amp;lpos=Watch3-s3' onclick="_hbLink('DV+-+SUNDANCE08INTERVIEWSAVAGEGRACE+-+sundancechannel', 'Watch3-s3');" rel="nofollow"><img src="http://i.ytimg.com/vi/Xw5nE__RZEM/default.jpg" class="vimg75"  alt=""></a>
		</div></div>

		<!--div class="vtitle smallText" style="font-weight: normal;"-->
		<div >
			<a href="/cthru?ni0qShFybgHpOBPUfyMX4pfvgXr_rQF24kuZUNz6xr8r7qHVGynYkoBtR1qa2YD3RKJtsTJh3LeUB3h1svacowv_otZZAQu-b6mMk6-HzVOfG7HuDhl-hdGlRbI3eHLNBxOa6w0p9x2vZ9kOu-VegSGXuPAf98vWY3F03QiCg6JEXf7iYgo14q2hDXObG0YvaA6dlI60sV9jDP9DvXKZqg==" target="_parent" name='&amp;lid=DV+-+SUNDANCE08INTERVIEWSAVAGEGRACE+-+sundancechannel&amp;lpos=Watch3-s3' rel="nofollow">SUNDANCE '08 - IN...</a>
		</div>

			<span class="runtime" style="font-weight: normal">04:00</span>

			<div class="">
				<span class="grayText"></span>  <a href="/profile?user=sundancechannel" class="dg" rel="nofollow">sundancecha...</a>
<br/>
			</div>
		</div>

				</td>
			</tr></table>
		</div>
	</div> 



</div> 

</td>
</tr></table>




		<div class="clear"></div>
	<div id="footer">
		<div class="search">
			<div class="promo">
				<a href="/youchoose" onclick="_hbLink('FooterPromo','Footer');"><img id="debates_footer_img" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" alt="footer-promo" /></a>
				<a href="/youchoose" onclick="_hbLink('FooterPromo','Footer');">Face The Candidates</a>
			</div>
			<form name="footer-search-form" method="get" action="/results">
				<a href="http://www.google.com/ig/adde?moduleurl=youtube_videos.xml&source=ytfp&hl=en"><img id="igoogle_footer_img" src="http://static.youtube.com/yt/img/pixel-vfl73.gif" /></a>
				<input type="text" name="search_query" maxlength="128" class="query" value=""><input type="submit" name="search" value="Search" class="submit-button">
			</form>
		</div>
		<div class="links">
			<table cellpadding="0" cellspacing="0">
				<tr>
					<th colspan="2" nowrap>Your Account</th>
					<th class="separator" colspan="2" nowrap>Help &amp; Info</th>
					<th class="separator" colspan="2" nowrap>YouTube</th>
				</tr>
				<tr>
					<td nowrap><a href="/my_videos">Videos</a></td>
					<td nowrap><a href="/my_messages">Inbox</a></td>
					<td class="separator" nowrap><a href="http://www.google.com/support/youtube/?hl=en_US">Help Center</a></td>
					<td nowrap><a href="/t/safety">Safety Tips</a></td>
					<td class="separator" nowrap><a href="/t/about">Company Info</a></td>
					<td nowrap><a href="/press_room">Press</a></td>
				</tr>
				<tr>
					<td nowrap><a href="/my_favorites">Favorites</a></td>
					<td nowrap><a href="/subscription_center">Subscriptions</a></td>
					<td class="separator" nowrap><a href="/t/video_toolbox">Video Toolbox</a></td>
					<td nowrap><a href="/t/dmca_policy">Copyright Notices</a></td>
					<td class="separator" nowrap><a href="/testtube">TestTube</a></td>
					<td nowrap><a href="/t/contact_us">Contact</a></td>
				</tr>
				<tr>
					<td nowrap><a href="/my_playlists">Playlists</a></td>
					<td nowrap><a href="/my_account">more...</a></td>
					<td class="separator" nowrap><a href="/dev">Developer APIs</a></td>
					<td nowrap><a href="/t/community_guidelines">Community Guidelines</a></td>
					<td class="separator" nowrap><a href="/t/terms">Terms of Use</a></td>
					<td nowrap>
						<a href="/blog">Blog</a>
					</td>
				</tr>
				<tr>
					<td colspan="2" nowrap>&nbsp;</td>
					<td colspan="2" class="separator" nowrap>&nbsp;</td>
					<td class="separator" nowrap><a href="/t/privacy">Privacy Policy</a></td>
					<td nowrap>
						<a href="http://www.google.com/jobs/youtube">Jobs</a><br/>
					</td>
				</tr>
			</table>
		</div>
	</div>
	<div id="copyright">
		&copy; 2007 YouTube, LLC
	</div>


</div> <!-- end baseDiv -->
</div></body>

</html>

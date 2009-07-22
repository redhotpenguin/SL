#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

BEGIN { use_ok('SL::Subrequest') or die }

# slurp the test webpage
my $content = do { local $/; <DATA> };

use Time::HiRes qw(tv_interval gettimeofday);

my $base_url   = 'http://www.apple.com/startpage/';
my $subreq     = SL::Subrequest->new();

# clear out the cache
$subreq->{cache}->clear;

my $start      = [gettimeofday];
my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);
my $interval = tv_interval( $start, [gettimeofday] );

# check to make sure startpage bug isn't twice
cmp_ok($subreq_ref->[15]->[1], 'eq', 'http://www.apple.com/startpage/scripts/packaged.js');

is( scalar( @{$subreq_ref} ), 18, 'subrequests extracted' );
diag("extraction took $interval seconds");
my $limit = 0.1;
cmp_ok( $interval, '<', $limit,
    "subrequests extracted in $interval seconds" );

diag("check correct subrequests were extracted");
# unique subrequests
#my %subreq_hash = map { $_->[0] => 1 } @{$subreq_ref};
#foreach my $test_url ( @{ test_urls() } ) {
#    ok(exists $subreq_hash{$test_url});
#}

diag('test replacing the links');
my $port = '8135';
$start = [gettimeofday];
ok(
    $subreq->replace_subrequests(
        { port => $port, content_ref => \$content, subreq_ref => $subreq_ref }
    )
);

$interval = tv_interval( $start, [gettimeofday] );
$limit = 0.100;
diag("replacement took $interval seconds");
cmp_ok( $interval, '<', $limit, "replace_subrequests took $interval seconds" );

sub test_urls {
    return [
    ];
}

__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en-us">
<head>
	
	<base href="http://images.apple.com/v20090709114810/">

	
	<meta http-equiv="content-type" content="text/html; charset=utf-8">
	<meta http-equiv="pics-label" content='(pics-1.1 "http://www.icra.org/ratingsv02.html" l gen true for "http://www.apple.com" r (cz 1 lz 1 nz 1 oz 1 vz 1) "http://www.rsac.org/ratingsv01.html" l gen true for "http://www.apple.com" r (n 0 s 0 v 0 l 0))'>
	<meta name="Author" content="Apple Inc.">
	<meta name="viewport" content="width=1024">
	<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7">
	<title>Apple - Start</title>
	<meta name="omni_page" content="Start - Index">
	<meta name="Category" content="">
	<meta name="Description" content="">
	<script type="text/javascript">
	<!-- 
	 var gomez={ 
			 gs: new Date().getTime(), 
			 acctId:'C2C738', 
			 pgId:'StartPage', 
			 grpId:'' 
	 }; 
	 //--> 
	 </script>
	<link rel="alternate" href="http://images.apple.com/main/rss/hotnews/hotnews.rss" type="application/rss+xml" title="RSS">
	<link rel="stylesheet" href="./global/styles/base_itunesmodule_overlay.css" type="text/css" charset="utf-8">
	<link rel="stylesheet" href="./startpage/styles/startpage.css" type="text/css" charset="utf-8">
</head>
<body>
	<script src="http://images.apple.com/global/nav/scripts/shortcuts.js" type="text/javascript" charset="utf-8"></script>
<script type="text/javascript" charset="utf-8">
	var searchSection = 'global';
	var searchCountry = 'us';
</script>
<div id="globalheader">
	<!--googleoff: all-->
	<ul id="globalnav">
		<li id="gn-apple"><a href="/">Apple</a></li>
		<li id="gn-store"><a href="http://store.apple.com">Store</a></li>
		<li id="gn-mac"><a href="/mac/">Mac</a></li>
		<li id="gn-ipoditunes"><a href="/itunes/">iPod + iTunes</a></li>
		<li id="gn-iphone"><a href="/iphone/">iPhone</a></li>
		<li id="gn-downloads"><a href="/downloads/">Downloads</a></li>
		<li id="gn-support"><a href="/support/">Support</a></li>
	</ul>
	<!--googleon: all-->
	<div id="globalsearch">
		<form action="http://searchcgi.apple.com/cgi-bin/sp/nph-searchpre11.pl" method="post" class="search" id="g-search">
			<div>
				<input type="hidden" value="utf-8" name="oe" id="search-oe">
				<input type="hidden" value="p" name="access" id="search-access">
				<input type="hidden" value="us_only" name="site" id="search-site">
				<input type="hidden" value="lang_en" name="lr" id="search-lr">
				<label for="sp-searchtext"><span class="prettyplaceholder">Search</span><input type="search" name="q" id="sp-searchtext" class="g-prettysearch applesearch" accesskey="s"></label>
			</div>
		</form>
		<div id="sp-results"><div class="inside"></div></div>
	</div>
</div>

	<noscript><div id="nojs">Please enable JavaScript to view this page properly.</div></noscript>
	<div id="container">
		<div id="main">
			<div id="header">
				<div class="promo" id="promo1"></div>
				<div class="promo" id="promo2"></div>
				<div class="promo" id="promo3"></div>
				<div class="promo" id="promo4"></div>
			</div>
			<div id="content">
				<div class="grid3col">
					<div class="column first">
						<div class="sidebox store" id="sb-store">
							<h2><a href="http://store.apple.com/">Apple Online Store</a></h2>
							<ul>
								<li class="mac">
									<a href="http://store.apple.com/us/browse/home/shop_mac?mco=MTE3MDg"><img class="left" src="./startpage/images/store_mac20081103.jpg" width="70" height="62" alt="Shop Mac"></a>
									<h3>Configure your Mac</h3>
									<p>Customize it to your exact specifications. <a class="more" href="http://store.apple.com/us/browse/home/shop_mac?mco=MTE3MDg">Shop Mac</a></p>
								</li><!--/mac-->
								<li class="ipod">
									<a href="http://store.apple.com/us/browse/home/ipod/editorial/engraving_giftwrap?mco=MTE3NDA"><img class="left" src="./startpage/images/store_ipod20080924.png" width="73" height="67" alt="Shop iPod"></a>
									<h3>Free iPod engraving</h3>
									<p>Add a personal message to any new iPod for free. <a class="more" href="http://store.apple.com/us/browse/home/ipod/editorial/engraving_giftwrap?mco=MTE3NDA">Shop iPod</a></p>
								</li><!--/ipod-->
							</ul>
							<p class="more"><strong>Questions? Advice?</strong> 1-800-MY-APPLE</p>
						</div><!--/sidebox-->

						<div class="sidebox trailers" id="sb-trailers">
							<h2><a href="/trailers/">iTunes Movie Trailers</a></h2>
							<div id="trailers"></div>
						</div><!--/sidebox-->

						<div class="feedback">
							<p><a class="OverlayPanel" href="feedback_wrapper.html#feedback" title="Provide some feedback via online form">Send Feedback</a></p>
							<!--div id="feedback"><div class="iframewrap"><iframe src="/startpage/feedback.html" height="884" width="393" allowTransparency background-color="transparent" frameborder="0" scrolling="no"></iframe></div></div-->
						</div><!--/feedback-->
					</div>
					<div class="column" id="stories">
						<div class="titlebar">
							<h2>Hot News Headlines</h2>
							<ul class="sortnav">
								<li id="stories-all"><a class="storycontentlink" href="/startpage/feeds/all.json#all"><span>All</span></a></li>
								<li id="stories-mac"><a class="storycontentlink" href="/startpage/feeds/mac.json#mac"><span>Mac</span></a></li>
								<li id="stories-itunes"><a class="storycontentlink" href="/startpage/feeds/itunes.json#itunes"><span>iPod+iTunes</span></a></li>
								<li id="stories-iphone"><a class="storycontentlink" href="/startpage/feeds/iphone.json#iphone"><span>iPhone</span></a></li>
							</ul>
							<span class="rss"><a href="http://images.apple.com/main/rss/hotnews/hotnews.rss">RSS Feed</a></span>
						</div><!--/titlebar-->
						<div id="storycontent" class="swap-view"></div>
						<a href="/hotnews/" title="View all the top stories" class="view">View all</a>
					</div>
					<div class="column last">
						<div class="sidebox tutorials" id="sb-tutorials">
							<h2><a href="/findouthow/">Mac Video Tutorials</a></h2>
							<div id="sb-t-featured"></div>
							<h3>View Hundreds of Tutorials:</h3>
							<ul>
								<li class="first"><a id="FOHMacBasics" href="/findouthow/mac/"><span></span>
									<strong>Mac Basics</strong> (37)
								</a></li>
								<li><a id="FOHPhotos" href="/findouthow/photos/"><span></span>
									<strong>Photos</strong> (86)
								</a></li>
								<li><a id="FOHMovies" href="/findouthow/movies/"><span></span>
									<strong>Movies</strong> (47)
								</a></li>
								<li><a id="FOHWeb" href="/findouthow/web/"><span></span>
									<strong>Web</strong> (22)
								</a></li>
								<li><a id="FOHMusic" href="/findouthow/music/"><span></span>
									<strong>Music</strong> (46)
								</a></li>
								<li><a id="FOHiWork" href="/findouthow/iwork/"><span></span>
									<strong>iWork</strong> (58)
								</a></li>
								<li><a id="FOHMobileMe" href="/findouthow/mobileme/"><span></span>
									<strong>MobileMe</strong> (15)
								</a></li>
							</ul>
							<a href="/findouthow/" title="View all the Mac Video Tutorials" class="view">View all</a>
						</div>
					</div>
				</div>
			</div><!--/content-->
			<div id="itunesmodule">
	<div id="itunesmodule-navbar">
		<div class="titlebar">
			<h2>iTunes Store this week</h2>

			<ul class="sortnav">
				<li><a id="itunesmodule-featured" class="module-link" href="#featured">Featured</a></li>
				<li><a id="itunesmodule-music" class="module-link" href="/itunespromos/thisweek/music.html#itunesmodule-music">Music</a></li>
				<li><a id="itunesmodule-movies" class="module-link" href="/itunespromos/thisweek/movies.html#itunesmodule-movies">Movies</a></li>
				<li><a id="itunesmodule-tvshows" class="module-link" href="/itunespromos/thisweek/tvshows.html#itunesmodule-tvshows">TV Shows</a></li>
				<li><a id="itunesmodule-audiobooks" class="module-link" href="/itunespromos/thisweek/audiobooks.html#itunesmodule-audiobooks">Audiobooks</a></li>
				<li><a id="itunesmodule-appstore" class="module-link" href="/itunespromos/thisweek/appstore.html#itunesmodule-appstore">Games + Apps</a></li>
				<li><a id="itunesmodule-podcasts" class="module-link" href="/itunespromos/thisweek/podcasts.html#itunesmodule-podcasts">Podcasts</a></li>
			</ul>
			
			<form action="http://ax.phobos.apple.com/WebObjects/MZStoreServices.woa/wa/com.apple.jingle.search.DirectAction/search?term=" method="get" accept-charset="utf-8" id="itunes-search">
				<label>Search iTunes Store
					<input type="text" name="itunes-search-term" value="" class="prettysearch search-field">
				</label>
				<input type="submit" value="Search" class="search-submit">
			</form>
		</div>

	</div><!--/cap top-->

	<div id="itunesmodule-panel">
		<div id="featured" class="section">
			<div id="music-toplist-featured1" class="toplist nopref">
				<h2 class="title">Top Songs</h2>
				<ol class="listing">
					<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?i=318393999&amp;id=318390146&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMUSIC"><strong>I Gotta Feeling</strong><br /><span>Black Eyed Peas</span></a><br /><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?i=318393999&amp;id=318390146&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMUSIC"><img src="http://a1.phobos.apple.com/us/r1000/009/Music/73/df/11/mzi.fsjwezgz.60x60-50.jpg" width="60" height="60" alt="I Gotta Feeling" style="padding-top: 3px; border: 0;" /></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?i=312051360&amp;id=312051338&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMUSIC"><strong>Fire Burning</strong><br /><span>Sean Kingston</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?i=295757256&amp;id=295757174&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMUSIC"><strong>You Belong With Me</strong><br /><span>Taylor Swift</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?i=318393150&amp;id=318390146&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMUSIC"><strong>Boom Boom Pow</strong><br /><span>Black Eyed Peas</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?i=291106870&amp;id=291106817&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMUSIC"><strong>Use Somebody</strong><br /><span>Kings of Leon</span></a></li>

				</ol>
			</div>

			<div id="movies-toplist-featured2" class="toplist nopref">
				<h2 class="title">Top Movies</h2>
				<ol class="listing">
					<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=316334210&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMOVIES"><strong>Knowing (2009)</strong><br /><span>Sci-Fi &amp; Fantasy</span></a><br /><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=316334210&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMOVIES"><img src="http://a1.phobos.apple.com/us/r1000/031/Video/62/8c/25/mzi.youdmmot.60x60-50.jpg" width="40" height="60" alt="Knowing (2009)" style="padding-top: 3px; border: 0;" /></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=315272342&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMOVIES"><strong>Push (2009)</strong><br /><span>Sci-Fi &amp; Fantasy</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=305114504&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMOVIES"><strong>He's Just Not That Into You</strong><br /><span>Comedy</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=304298150&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMOVIES"><strong>Gran Torino</strong><br /><span>Action &amp; Adventure</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewMovie?id=303711220&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPMOVIES"><strong>Paul Blart: Mall Cop</strong><br /><span>Comedy</span></a></li>

				</ol>
			</div>

			<div id="tvshows-toplist-featured3" class="toplist nopref">
				<h2 class="title">Top TV Shows</h2>
				<ol class="listing">
					<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTVSeason?i=322664954&amp;id=294805285&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPTV"><strong>Super(stitious) Girl (Crossover Episode)</strong><br /><span>Hannah Montana</span></a><br /><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTVSeason?i=322664954&amp;id=294805285&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPTV"><img src="http://a1.phobos.apple.com/us/r1000/011/Video/62/1c/9e/mzl.drxjribp.80x60-75.jpg" width="60" height="60" alt="Super(stitious) Girl (Crossover Episode)" style="padding-top: 3px; border: 0;" /></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTVSeason?i=323245840&amp;id=288943595&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPTV"><strong>Double-Crossed</strong><br /><span>The Suite Life On Deck</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTVSeason?i=324360341&amp;id=306125371&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPTV"><strong>The New King</strong><br /><span>Part One</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTVSeason?i=323296644&amp;id=289274767&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPTV"><strong>Cast-Away (To the Other Show)</strong><br /><span>Wizards of Waverly Place</span></a></li>
<li><a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTVSeason?i=324114898&amp;id=316804967&amp;s=143441&amp;uo=2&amp;uo=2&amp;v0=WWW-NAUS-ITUHOME-TOPTV"><strong>The Hunter</strong><br /><span>Burn Notice</span></a></li>

				</ol>
			</div>
			<div class="splashes">
  <a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewCustomPage?name=pageSummerSciFiMovies"><img src="http://a1.phobos.apple.com/us/r30/Features/d6/4e/da/dj.ukflmssx.jpg" width="248" height="140" alt="Layout Root pageSummerSciFiMovies" /></a>
  <a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?id=321981044&amp;s=143441" class="last"><img src="http://a1.phobos.apple.com/us/r30/Features/68/7d/a4/dj.hcdugwmw.jpg" width="248" height="140" alt="The Dead Weather Horehound" /></a>
</div>

<div class="bricks">
  <a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewCustomPage?name=pageHDMovies"><img src="http://a1.phobos.apple.com/us/r30/Features/f7/81/6e/dj.wtkmeydu.jpg" width="135" height="95" alt="Layout Root pageHDMovies" /></a>
  <a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewCustomPage?name=pageiTunesPicksNonfiction"><img src="http://a1.phobos.apple.com/us/r30/Features/b3/21/36/dj.sdlmzpiz.jpg" width="135" height="95" alt="iTunes Picks: 10 Best Nonfiction Shows" /></a>
  <a href="http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewAlbum?id=321188873&amp;s=143441" class="last"><img src="http://a1.phobos.apple.com/us/r30/Features/78/26/f6/dj.khynrhlf.jpg" width="135" height="95" alt="Neko Case iTunes Originals - Neko Case" /></a>
</div>

		</div>
	</div>
</div><!--/itunesmodule-->

		</div><!--/main-->
	</div><!--/container-->
	<div id="globalfooter" class="gf-980">
		<div id="breadcrumbs">
			<a href="/" class="home">Home</a><span>&gt;</span>Start
		</div><!--/breadcrumbs-->
		<p class="gf-buy">Shop the <a href="/store/">Apple Online Store</a> (1-800-MY-APPLE), visit an <a href="/retail/">Apple Retail Store</a>, or find a <a href="/buy/locator/">reseller</a>.</p>

<ul class="gf-links piped">
	<li><a href="/about/" class="first">Apple Info</a></li>
	<li><a href="/sitemap/">Site Map</a></li>
	<li><a href="/hotnews/">Hot News</a></li>
	<li><a href="/rss/">RSS Feeds</a></li>
	<li><a href="/contact/" class="contact_us">Contact Us</a></li>
	<li><a href="/choose-your-country/" class="choose" title="Choose your country or region."><img src="http://images.apple.com/home/elements/worldwide_us.png" alt="United States" width="22" height="22"></a></li>
</ul>
	
<div class="gf-sosumi">
	<p>Copyright © 2009 Apple Inc. All rights reserved.</p>
	<ul class="piped">
		<li><a href="/legal/terms/site.html" class="first">Terms of Use</a></li>
		<li><a href="/legal/privacy/">Privacy Policy</a></li>
	</ul>
</div>


	</div><!--/globalfooter-->
	<script type="text/javascript" charset="utf-8">
			function absoluteURLForValue(href) {
				if(!!href && href.indexOf("http") !== 0) {
					return  window.location.protocol+"//"+window.location.host+ ((href.indexOf("/") !== 0) ? "/" : "")+href;
				}
				return href;
			}
	
			function getRandomElement(a) {
				return a[Math.floor(Math.random()*a.length)];
			}

			// header promos
			var promos = {
				iphone: { title:'iPhone 3GS', href:'/iphone/', img:'./startpage/images/2009/06/promo-iphone-20090608.jpg'},
				softwareupdate: { title:'iPhone 3.0 Get Cut, Copy &amp; Paste, Spotlight Search, and more with this free download.', href:'/iphone/softwareupdate/', img:'./startpage/images/2009/06/promo-iphone3-20090623.jpg' },
				macbookpro: { title:'The new MacBook Pro family.', href:'/macbookpro/', img:'./startpage/images/2009/06/promo-macbookpro-20090608.jpg' },
				mobileme: { title:'MobileMe. Locate your lost iPhone on a map.', href:'/mobileme/whats-new/', img:'./startpage/images/2009/06/promo-mobileme-20090629.jpg' },
				backtoschool: { title:'Buy a Mac for college, and get a free iPod touch. Terms apply.', href:'http://store.apple.com/us/go/promo/backtoschool?cid=WWW-NAUS-BTS20090507-00033', img:'./startpage/images/2009/05/promo-bts-20090527.jpg' },
				snowleopard: { title:'Mac OS X Snow Leopard. World\'s most advanced operating system. Finely tuned.', href:'/macosx/', img:'./startpage/images/2009/06/promo-snowleopard-20090608.jpg' }
			};

			var promoRotations = [
				[
					[ promos.iphone, promos.softwareupdate ],
					[ promos.macbookpro, promos.mobileme ],
					promos.backtoschool,
					promos.snowleopard
				]
			];
			var promoRotation = getRandomElement(promoRotations);
			for (var i=0; i<promoRotation.length; i++) {
				var promo = promoRotation[i];
				if (promo.constructor == Array) promo = getRandomElement(promo);
				promoHref = absoluteURLForValue(promo.href);

				document.getElementById('promo'+(i+1)).innerHTML = '<a href="'+promoHref+'"><img src="'+promo.img+'" width="236" height="155" alt="'+promo.title+'"></a>';
			}

			// featured tutorial
			var tutorials = [
				{ title:'Anatomy of a Mac', href:'/findouthow/mac/#tutorial=anatomy', img:'./startpage/images/2009/03/foh-anatomy-20090327.jpg' },
				{ title:'Wireless Basics', href:'/findouthow/mac/#tutorial=wirelessbasics', img:'./startpage/images/2009/03/foh-wirelessbasics-20090327.jpg' },
				{ title:'Parental Controls', href:'/findouthow/mac/#tutorial=leopardparental', img:'./startpage/images/2009/03/foh-parental-20090327.jpg' },
				{ title:'PC to Mac: The Basics', href:'/findouthow/mac/#tutorial=switcher', img:'./startpage/images/2009/03/foh-switcher-20090327.jpg' },
				{ title:'Streaming Music Wirelessly', href:'/findouthow/mac/#tutorial=wirelessmusic', img:'./startpage/images/2009/03/foh-wirelessmusic-20090327.jpg' },
				{ title:'Time Machine Basics', href:'/findouthow/mac/#tutorial=leopardtimemachine', img:'./startpage/images/2009/01/foh-leopardtimemachine-20090109.jpg'}
			];
			var tutorial = getRandomElement(tutorials), tutorialHref = tutorial.href;
			tutorialHref = absoluteURLForValue(tutorial.href);
			document.getElementById('sb-t-featured').innerHTML = '<a class="featured" href="'+tutorialHref+'"><img src="'+tutorial.img+'" width="124" height="62" alt="Featured Tutorial: '+tutorial.title+'">Featured Tutorial:<br><strong>'+tutorial.title+'</strong></a>';

	</script>
	<!-- Inlined Metrics-->
	<div id="top">
	<!-- SiteCatalyst code version: H.8. Copyright 1997-2006 Omniture, Inc. -->
	<script type="text/javascript">
	/* RSID: */
	var s_account="appleglobal,appleusstartpage"
	</script>

	<!-- End SiteCatalyst code version: H.8. -->
	</div>
	
	<script src="./startpage/scripts/packaged.js" type="text/javascript" charset="utf-8"></script>
	<script type="text/javascript">
	Event.observe(window, 'load', function() {
		if ($('promo3')) {
			if ($('promo3').down('a')) {

				s.pageName=AC.Tracking.pageName()+" (US)";
				s.server=""
				s.channel="www.us.startpage"
				s.pageType=""
				s.prop1=""
				s.prop2=TrackStartpage();
		s.prop3=""
				s.prop4=document.URL;
				s.prop5=""
				s.prop18=""
				s.prop19=""

				/* E-commerce Variables */
				s.campaign=""
				s.state=""
				s.zip=""
				s.events=""
				s.products=""
				s.purchaseID=""
				s.eVar1=""
				s.eVar2=""
				s.eVar3=""
				s.eVar4=""
				s.eVar5=""

				s.linkInternalFilters="javascript:,www.apple.com"

				/************* DO NOT ALTER ANYTHING BELOW THIS LINE ! **************/
				var s_code=s.t();if(s_code)document.write(s_code)
			}
		}
	});
	</script>
	<!-- End SiteCatalyst code version: H.8. -->
	
</body>
</html>

#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 44;

BEGIN { use_ok('SL::Subrequest') or die }

# slurp the test webpage
my $content = do { local $/; <DATA> };

use Time::HiRes qw(tv_interval gettimeofday);

my $base_url   = 'http://leknott.com';
my $subreq     = SL::Subrequest->new();

# clear out the cache
$subreq->{cache}->clear;

my $start      = [gettimeofday];
my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url,
);
my $interval = tv_interval( $start, [gettimeofday] );

is( scalar( @{$subreq_ref} ), scalar(@{test_urls()}), 'subrequests extracted' );
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
$limit = 0.100;
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
       'http://www.leknott.com/blog/styles.css',
       'http://www.leknott.com/blog/index.rdf',
       'http://www.typepad.com/t/rsd/9086',
       'http://www.leknott.com/foaf.rdf',
       'http://stats.adbrite.com/stats/stats.gif?_cpid=conversion&_uid=207319',
       'http://leknott.typepad.com/blog/images/photos.gif',
       'http://leknott.typepad.com/blog/images/cc.gif',
       'http://pagead2.googlesyndication.com/pagead/show_ads.js',
       'http://www.leknott.com/photos/uncategorized/2007/06/22/baraci.gif',
       'http://leknott.typepad.com/images/hood_to_coast_banner.gif',
       'http://leknott.typepad.com/images/PHP_banner.jpg',
       'http://pagead2.googlesyndication.com/',
       'http://www.typepad.com/',
    ];
}

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta name=FreeFind content="noRobotsTag">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="generator" content="http://www.typepad.com/" />

<title>LeKnott</title>

<link rel="stylesheet" href="http://www.leknott.com/blog/styles.css" type="text/css" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.leknott.com/blog/index.rdf" />
<link rel="EditURI" type="application/rsd+xml" title="RSD" href="http://www.typepad.com/t/rsd/9086" />
<link rel="meta" type="application/rdf+xml" title="FOAF" href="http://www.leknott.com/foaf.rdf" />



</head>

<body>
<!-- begin AdBrite conversion tracking code -->

<img border=0 hspace=0 vspace=0 width=1 height=1 src=http://stats.adbrite.com/stats/stats.gif?_cpid=conversion&_uid=207319>
<img border=0 hspace=0 vspace=0 width=1 height=1 src= http://stats.adbrite.com/stats/stats.gif?_cpid=conversion&_uid=207319>
<img border=0 hspace=0 vspace=0 width=1 height=1 src =  http://stats.adbrite.com/stats/stats.gif?_cpid=conversion&_uid=207319 ">

<!-- end AdBrite conversion tracking code -->
<div id="container">

<div id="banner">
<a id="banner-img" href="http://www.leknott.com/blog/"><span class="banner-
alt"></span></a>
</div>

<div id="left">

<!-- FreeFind Begin No Index -->
<div class="sidebar"> 
<p>
<div class="module-typelist module">
	<h2 class="module-header"><h3>LeWho?</h3></h2>
	<div class="module-content">
		<ul class="module-list">
							<li class="module-list-item"><a title="" href=""><a href="http://www.leknott.com/blog/2003/10/about_jeff_lenn.html">Jeff Lennan</a>  |  <a href="http://www.leknott.com/blog/2003/10/contact_molly_k.html">Molly Knott</a></a></li>

			
		</ul>
	</div>
</div>

<h3>Categories</h3>
<ul>
<li><a href ="http://leknott.typepad.com/blog/archives.html">All Posts (Archives)</a> </li>
<li><a href="http://leknott.typepad.com/blog/animals/index.html">Animals</a></li>
 <li><a href="http://leknott.typepad.com/blog/current_affairs/index.html">Current Affairs</a></li>

<li><a href="http://leknott.typepad.com/blog/film/index.html">Film</a></li>
 <li><a href="http://leknott.typepad.com/blog/garden/index.html">Garden</a></li>
<li><a href="http://leknott.typepad.com/blog/music/index.html">Music</a></li>
<li><a href="http://leknott.typepad.com/blog/photos/index.html">Photos</a></li>
<li><a href="http://leknott.typepad.com/blog/technology/index.html">Technology</a></li>
<li><a href="http://www.leknott.com/blog/trips/index.html">Trips</a></li>


</ul>

<h3>Recent Posts</h3>
<ul>
<li><a href="http://www.leknott.com/blog/2007/06/taking-our-gove.html">Taking Our Government Back</a><br /> </li>
<li><a href="http://www.leknott.com/blog/2007/06/a_love_song_to_.html">A Love Song To Public Transportation</a><br /> </li>
<li><a href="http://www.leknott.com/blog/2007/05/summer_lake_hot.html">Summer Lake Hot Springs 2007</a><br /> </li>

</ul><br>


<a href="http://leknott.typepad.com/blog/photos.html"><img src="http://leknott.typepad.com/blog/images/photos.gif"></a>

<br><br><br><br><br><br>
<!--Creative Commons License-->
<a rel="license" href="http://creativecommons.org/licenses/by/2.5/"><img alt="Creative Commons License" border="0" src="http://leknott.typepad.com/blog/images/cc.gif" /></a><br />
<!--/Creative Commons License-->
<!--<img src="/blog/images/adventures.gif">-->


<!--

<rdf:RDF xmlns="http://web.resource.org/cc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<Work rdf:about="">
   <license rdf:resource="http://creativecommons.org/licenses/by/2.0/" />
</Work>

<License rdf:about="http://creativecommons.org/licenses/by/2.0/">
   <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
   <permits rdf:resource="http://web.resource.org/cc/Distribution" />
   <requires rdf:resource="http://web.resource.org/cc/Notice" />
   <requires rdf:resource="http://web.resource.org/cc/Attribution" />
   <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
</License>

</rdf:RDF>
</p>
-->
</div> 
<!-- FreeFind End No Index -->

</div>

<div id="center">
<div class="content">

<script type=”text/javascript”><!—
google_ad_client = “pub-8790931056699463”;
google_ad_output = “textlink”;
google_ad_format = “ref_text”;
google_cpa_choice = “CAAQyaP2_gEaCMrERTxCnNWQKLGsuIEB”;
//—></script>

<script type="text/javascript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>




<!--
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/"
         xmlns:dc="http://purl.org/dc/elements/1.1/">
<rdf:Description
    rdf:about="http://www.leknott.com/blog/2007/06/taking-our-gove.html"
    trackback:ping="http://www.typepad.com/t/trackback/6166/19509682"
    dc:title="Taking Our Government Back"
    dc:identifier="http://www.leknott.com/blog/2007/06/taking-our-gove.html"
    dc:description="ByBarack Obama June 21, 2007 Over one hundred years ago, around the turn of the last century, the Industrial Revolution was beginning to take hold of America, creating unimaginable wealth in sprawling metropolises all across the country. As factories multiplied..."
    dc:creator="Jeff Lennan"
    dc:date="2007-06-22T17:39:16-07:00" />
</rdf:RDF>
-->




<a id="a0035670110"></a>

<h3>Taking Our Government Back</h3>


<p><span style="color: #669900;"><strong><img border="0" src="http://www.leknott.com/photos/uncategorized/2007/06/22/baraci.gif" title="Baraci" alt="Baraci" style="margin: 0px 0px 5px 5px; float: right;" /></strong></span><span style="color: #000000;">
 By</span><span style="color: #669900;"><strong>&nbsp;</strong><a href="http://barackobama.com">Barack Obama </a></span><br /><span style="color: #000000;">June 21, 2007 </span><span style="color: #669900;"><br /> </span></p>

<p><img src="file:///C:/DOCUME~1/Jeff/LOCALS~1/Temp/moz-screenshot-24.jpg" />
Over one hundred years ago, around the turn of the last century, the
Industrial Revolution was beginning to take hold of America, creating
unimaginable wealth in sprawling metropolises all across the country.

</p>

<p>As factories multiplied and profits grew, the winnings of the new
economy became more and more concentrated in the hands of a few robber
barons, railroad tycoons and oil magnates.</p>

<p>It was known as the Gilded Age, and it was made possible by a
government that played along. From the politicians in Washington to the
big city machines, a vast system of payoffs and patronage, scandal and
corruption kept power in the hands of the few while the workers who
streamed into the new factories found it harder and harder to earn a
decent wage or work in a safe environment or get a day off once in
awhile.</p>

<p>Eventually, leaders committed to reform began to speak out all
across America, demanding a new kind of politics that would give
government back to the people.</p>

<p>One was the young governor of the state of New York.</p>

<p>In just his first year, he had already begun to antagonize the
state's political machine by attacking its system of favors and
corporate giveaways. He also signed a workers' compensation bill, and
fired a high-level official for taking money from the very industry he
was supposed to be regulating.</p>

<p>None of this reform sat too well with New York's powerful party
boss, who finally plotted to get rid of the governor by making sure he
was nominated for the Vice Presidency that year. What no one could have
expected is that soon after the election, when President William
McKinley was assassinated, the greatest fears of all the entrenched
interests came true when that former governor became President of the
United States.</p>

<p>His name, of course, was Teddy Roosevelt. And during his presidency,
he went on to bust trusts, break up monopolies, and do his best to give
the American people a shot at the dream once more.</p>

<p class="extended"><a href="http://www.leknott.com/blog/2007/06/taking-our-gove.html#more">Continue reading "Taking Our Government Back"</a></p>

<p class="posted">Jeff Lennan posted Jun 22, 2007 in <a href="http://www.leknott.com/blog/current_affairs/index.html">Current Affairs</a>, <a href="http://www.leknott.com/blog/politics/index.html">Politics</a>, <a href="http://www.leknott.com/blog/vote_with_your/index.html">Vote With Your $$$</a> | <a href="http://www.leknott.com/blog/2007/06/taking-our-gove.html">Permalink</a> | <a href="http://www.leknott.com/blog/2007/06/taking-our-gove.html#comments">Comments (1)</a>


<h2><a id="trackback"></a>TrackBack</h2>

<p>TrackBack URL for this entry:<br />http://www.typepad.com/t/trackback/6166/19509682</p>

<p>Listed below are links to weblogs that reference <a href="http://www.leknott.com/blog/2007/06/taking-our-gove.html">Taking Our Government Back</a>:</p>



</p>



</div>
</div>

<div id="right">
<!-- FreeFind Begin No Index -->
<div class="sidebar">
<a href="http://www.hoodtocoastequine.com"><img border="0" src="http://leknott.typepad.com/images/hood_to_coast_banner.gif"></a>
<a href="http://www.performancehorsephoto.com"><img border="0" src="http://leknott.typepad.com/images/PHP_banner.jpg"></a>







<!--
<a href="http://leknott.typepad.com/blog/audioscrobbler.html"><img border="0" src="http://static.last.fm/media/lastfm_button.png"></a>-->

<br><br><Br>

</ul>
</div>
<!-- FreeFind End No Index -->



</div>

<div style="clear: both;">&#160;</div>

</div>

<script type="text/javascript">
<!--
var extra_happy = Math.floor(1000000000 * Math.random());
document.write('<img src="http://www.typepad.com/t/stats?blog_id=9086&amp;user_id=6166&amp;page=' + escape(location.href) + '&amp;referrer=' + escape(document.referrer) + '&amp;i=' + extra_happy + '" width="1" height="1" alt="" style="position: absolute; top: 0; left: 0;" />');
// -->
</script>


</body>
</html>

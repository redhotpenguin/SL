#!perl

# tests for the SL::Model::Subrequest module

use strict;
use warnings FATAL => 'all';

use Test::More tests => 41;

BEGIN { use_ok('SL::Cache::Subrequest') or die };

# setup the database
my $base_url = "http://example.com";
my @urls     = (
    "$base_url/bar.js",             "http://scripthaus.com/zimzam.js",
    "http://www.redhotpenguin.com/css/local.css",
    "$base_url/subreq.cgi",         "$base_url/not_subreq.cgi",
    "http://imagefarm.com/pig.jpg", "$base_url/images/news.gif",
    "$base_url/img/cow.gif",  'javascript:false;',
     'about:blank',
);
my $in = join ( ',', map { "'" . $_ . "'" } @urls );

# some content with one subreq and one normal link
my $content = do { local $/; <DATA> };

my $subreq = SL::Cache::Subrequest->new();
isa_ok( $subreq, 'SL::Cache::Subrequest' );

# clear out the cache
$subreq->{cache}->clear;

my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url
);

# make sure the subrequests can be identified correctly
diag('identify subrequests correctly');
ok( $subreq->is_subrequest( url  => $urls[0] ) );
ok( $subreq->is_subrequest( url  => $urls[1] ) );
ok( $subreq->is_subrequest( url  => $urls[2] ) );
ok( $subreq->is_subrequest( url  => $urls[3] ) );
ok( !$subreq->is_subrequest( url => $urls[4] ) );
ok( $subreq->is_subrequest( url  => $urls[5] ) );
ok( $subreq->is_subrequest( url  => $urls[6] ) );
ok( $subreq->is_subrequest( url  => $urls[7] ) );
ok( !$subreq->is_subrequest( url => $urls[8] ) );
ok( !$subreq->is_subrequest( url => $urls[9] ) );

# examine the results of the subrequest collection
diag('examine results of subrequest collection');
is( scalar( @{$subreq_ref} ), 7 );
cmp_ok( $subreq_ref->[0]->[0], 'eq', '/bar.js' );
cmp_ok( $subreq_ref->[0]->[1], 'eq', $urls[0] );
cmp_ok( $subreq_ref->[1]->[0], 'eq', $urls[1] );
cmp_ok( $subreq_ref->[1]->[1], 'eq', $urls[1] );
cmp_ok( $subreq_ref->[2]->[0], 'eq', $urls[2] );
cmp_ok( $subreq_ref->[2]->[1], 'eq', $urls[2] );

cmp_ok( $subreq_ref->[3]->[0], 'eq', 'subreq.cgi' );
cmp_ok( $subreq_ref->[3]->[1], 'eq', $urls[3] );
cmp_ok( $subreq_ref->[4]->[0], 'eq', $urls[5] );
cmp_ok( $subreq_ref->[4]->[1], 'eq', $urls[5] );
cmp_ok( $subreq_ref->[5]->[0], 'eq', 'images/news.gif' );
cmp_ok( $subreq_ref->[6]->[0], 'eq', '/img/cow.gif' );
cmp_ok( $subreq_ref->[6]->[1], 'eq', $urls[7] );

diag('replace the links now');
my $port = '8135';
$DB::single = 1;
my $ok = $subreq->replace_subrequests(
        {
            port        => $port,
            content_ref => \$content,
            subreq_ref  => $subreq_ref,
        }
    );
ok($ok, 'subrequests replaced od');
$DB::single = 1;
my $subrequests_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url
);

# sanity check the replaced subrequest urls

my $i = 0;
foreach my $subrequest_ref ( @{$subrequests_ref} ) {
    # make sure the port was replaced
    like($subrequest_ref->[0], qr/$port/);
    # ??
    cmp_ok($subreq_ref->[$i++]->[2], 'eq', $subrequest_ref->[2]);
    # check to make sure quotes were preserved
    my $testurl = $subrequest_ref->[1];
}

# FIXME YOU FRIGGIN DUMBSHIT
# check to make sure quotes are preserved
#    like($content, qr/\"$testurl\"/, 'quotes preserved');

1;
__DATA__
<html>
<head><title>Foo</title>
<script src="/bar.js">
<script src="http://scripthaus.com/zimzam.js">
<link rel="stylesheet" href="http://www.redhotpenguin.com/css/local.css" type="text/css" />
</head>
<body>
<iframe src="subreq.cgi"></iframe>
<p>
<a href="not_subreq.cgi">bar</a>
<img src="http://imagefarm.com/pig.jpg">
<img src=images/news.gif alt="" border=0 width=205 height=85>
  <!-- file:// link to trip up our tests -->
<p><img src="file:///C:/DOCUME~1/Jeff/LOCALS~1/Temp/moz-screenshot-24.jpg" /></p>
<img src="/img/cow.gif">
<iframe src="javascript:false;"></iframe>
<frame src="about:blank"></frame>
</p>
</body>
</html>

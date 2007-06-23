#!perl

# tests for the SL::Model::Subrequest module

use strict;
use warnings FATAL => 'all';

use Test::More tests => 32;

BEGIN { use_ok('SL::Model::Subrequest') or die }

# setup the database
my $base_url = "http://example.com";
my @urls     = (
    "$base_url/bar.js",             "http://scripthaus.com/zimzam.js",
    "$base_url/subreq.cgi",         "$base_url/not_subreq.cgi",
    "http://imagefarm.com/pig.jpg", "$base_url/img/cow.gif",
    'javascript:false;',            'about:blank',
);
my $in = join ( ',', map { "'" . $_ . "'" } @urls );
SL::Model->connect->do("DELETE FROM subrequest WHERE URL IN ($in)");

# some content with one subreq and one normal link
my $content = do { local $/; <DATA> };

my $subreq = SL::Model::Subrequest->new();
isa_ok( $subreq, 'SL::Model::Subrequest' );

my $subreq_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url
);

# make sure the subrequests can be identified correctly
diag('identify subrequests correctly');
ok( $subreq->is_subrequest( url  => $urls[0] ) );
ok( $subreq->is_subrequest( url  => $urls[1] ) );
ok( $subreq->is_subrequest( url  => $urls[2] ) );
ok( !$subreq->is_subrequest( url => $urls[3] ) );
ok( $subreq->is_subrequest( url  => $urls[4] ) );
ok( $subreq->is_subrequest( url  => $urls[5] ) );
ok( !$subreq->is_subrequest( url => $urls[6] ) );
ok( !$subreq->is_subrequest( url => $urls[7] ) );

# examine the results of the subrequest collection
diag('examine results of subrequest collection');
is( scalar( @{$subreq_ref} ), 5 );
cmp_ok( $subreq_ref->[0]->[0], 'eq', '/bar.js' );
cmp_ok( $subreq_ref->[0]->[1], 'eq', $urls[0] );
cmp_ok( $subreq_ref->[1]->[0], 'eq', $urls[1] );
cmp_ok( $subreq_ref->[1]->[1], 'eq', $urls[1] );
cmp_ok( $subreq_ref->[2]->[0], 'eq', 'subreq.cgi' );
cmp_ok( $subreq_ref->[2]->[1], 'eq', $urls[2] );
cmp_ok( $subreq_ref->[3]->[0], 'eq', $urls[4] );
cmp_ok( $subreq_ref->[3]->[1], 'eq', $urls[4] );
cmp_ok( $subreq_ref->[4]->[0], 'eq', '/img/cow.gif' );
cmp_ok( $subreq_ref->[4]->[1], 'eq', $urls[5] );

diag('replace the links now');
my $port = '6969';

ok(
    $subreq->replace_subrequests(
        {
            port        => $port,
            content_ref => \$content,
            subreq_ref  => $subreq_ref,
        }
    )
);

my $subrequests_ref = $subreq->collect_subrequests(
    content_ref => \$content,
    base_url    => $base_url
);

# sanity check the replaced subrequest urls
my $i = 0;
foreach my $subrequest_ref ( @{$subrequests_ref} ) {
    like($subrequest_ref->[0], qr/$port/);
    cmp_ok($subreq_ref->[$i++]->[2], 'eq', $subrequest_ref->[2]);
  }

1;
__DATA__
<html>
<head><title>Foo</title>
<script src="/bar.js">
<script src="http://scripthaus.com/zimzam.js">
</head>
<body>
<iframe src="subreq.cgi"></iframe>
<p>
<a href="not_subreq.cgi">bar</a>
<img src="http://imagefarm.com/pig.jpg">
<img src="/img/cow.gif">
<iframe src="javascript:false;"></iframe>
<frame src="about:blank"></frame>
</p>
</body>
</html>

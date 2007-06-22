#!perl

# tests for the SL::Model::Subrequest module

use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

BEGIN { use_ok('SL::Model::Subrequest') or die };

# some content with one subreq and one normal link
my $content = <<END;
<html>
<head><title>Foo</title></head>
<body>
<iframe src="subreq.cgi"></iframe>
<p>
<a href="not_subreq.cgi">bar</a>
</p>
</body>
</html>
END

my $subreq = SL::Model::Subrequest->new();
isa_ok($subreq, 'SL::Model::Subrequest');

is($subreq->collect_subrequests(content_ref => \$content,
                                base_url => 'http://example.com'),
   1);
ok($subreq->is_subrequest(url => 'http://example.com/subreq.cgi'));
ok(!$subreq->is_subrequest(url => 'http://example.com/not_subreq.cgi'));
ok(!$subreq->is_subrequest(url => 'http://example2.com/subreq.cgi'));
ok(!$subreq->is_subrequest(url => 'http://www.example.com/subreq.cgi'));

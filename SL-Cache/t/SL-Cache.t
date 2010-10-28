#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

my $pkg;
BEGIN {
    $pkg = 'SL::Cache';
    use_ok($pkg);
}

my $user = 'mr_foo';
ok($pkg->blacklist_user($user));
cmp_ok($pkg->is_user_blacklisted($user), '==', 1);

my $subrequest = 'http://foobar.com/something.jpg';
ok($pkg->add_known_html($subrequest, 'image/jpg'));
cmp_ok($pkg->is_known_not_html($subrequest), '==', 1);

$subrequest = 'http://foo.bar.com/foo.html';
ok($pkg->add_known_html($subrequest, 'text/html'));
ok(!$pkg->is_known_not_html($subrequest));

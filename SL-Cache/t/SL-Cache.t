#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;

my $pkg;
BEGIN {
    $pkg = 'SL::Cache';
    use_ok($pkg);
}

my $cache = $pkg->new( type => 'obj' );
isa_ok($cache, 'SL::Cache');
isa_ok($cache->{cache}, 'Cache::FastMmap');

$cache = $pkg->new( type => 'raw' );
isa_ok($cache, 'SL::Cache');
isa_ok($cache->{cache}, 'Cache::FastMmap');

$cache->{cache}->clear;

my $user = 'mr_foo';
ok($cache->blacklist_user($user));
cmp_ok($cache->is_user_blacklisted($user), '==', 1);

my $subrequest = 'http://foobar.com/something.jpg';
ok($cache->add_subrequest($subrequest));
cmp_ok($cache->is_subrequest($subrequest), '==', 1);

ok($cache->add_known_html($subrequest, 'text/html'));
cmp_ok($cache->is_known_html($subrequest), '==', 1);

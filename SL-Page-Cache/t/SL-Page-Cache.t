use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;
my $pkg;
BEGIN { 
    $pkg = 'SL::Page::Cache';
    use_ok($pkg);
};

my $cache = $pkg->new;
isa_ok($cache, $pkg);

my $content = 'fizzbin';

my $url = 'http%3A%2F%2Fbar.com';
my $cache_url;
$cache_url = $cache->insert({ url => $url,
                                     content_ref => \$content });

ok($cache_url, "cache_url is $cache_url");

my $new_cache_url = $cache->cache_url({ url => $url });
cmp_ok($new_cache_url, 'eq', $cache_url, 'cache url ok');


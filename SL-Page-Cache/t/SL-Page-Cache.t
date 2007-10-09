use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
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

my $long_url = 'http://pagead2.googlesyndication.com/pagead/ads?client=ca-pub-5785951125780041&dt=1191908094144&lmt=1191908082&format=728x15_0ads_al_s&output=html&correlator=1191908094143&url=http%3A%2F%2Fwww.redhotpenguin.com%2Ffoo.html&ga_vid=1626265464.1191908094&ga_sid=1191908094&ga_hid=1522258364&flash=9&u_h=1050&u_w=1680&u_ah=1024&u_aw=1680&u_cd=32&u_tz=-420&u_his=1&u_java=true&u_nplug=5&u_nmime=78';

$cache_url = $cache->insert({ url => $long_url,
                                     content_ref => \$content });

ok($cache_url, "long cache_url is $cache_url");

$new_cache_url = $cache->cache_url({ url => $long_url });
cmp_ok($new_cache_url, 'eq', $cache_url, 'long cache url ok');

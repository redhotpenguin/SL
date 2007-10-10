#!perl

use strict;
use warnings;

use Test::More tests => 2;

my $pkg;

BEGIN {
  $pkg = 'SL::Model::Ad::Google';
  use_ok($pkg);
}

my $ip = '127.0.0.1';
my $referer = 'http://funkcity.com';

my $url = 'http://pagead2.googlesyndication.com/pagead/ads?client=ca-pub-5785951125780041&dt=1186644785249&lmt=1186644784&format=728x15_0ads_al_s&output=html&correlator=1186644785249&url=http%3A%2F%2Fwww.redhotpenguin.com%2Farchives%2F000020.html&ref=http%3A%2F%2Fwww.redhotpenguin.com%2Farchives%2F000020.html&ga_vid=1774040002.1186644785&ga_sid=1186644785&ga_hid=819217451&flash=9&u_h=1050&u_w=1680&u_ah=1024&u_aw=1680&u_cd=32&u_tz=-420&u_his=10&u_java=true&u_nplug=5&u_nmime=78';

use SL::Page::Cache;
my $mog_port = "2525";
my $cached_url = "http%3A%2F%2F127.0.0.1%3A$mog_port%2Ffizzbin.html";
my $cached_ref_url = "http%3A%2F%2F127.0.0.1%3A$mog_port%2Ffizzbin_referer.html";

use URI::Escape;
my $i = 0;
my $sub = sub { ($i++ == 0) ? URI::Escape::uri_unescape($cached_url) : URI::Escape::uri_unescape($cached_ref_url) };

*SL::Page::Cache::cache_url = $sub;

my $new_uri = $pkg->match_and_log({ url => $url, ip => $ip, referer => $referer });
my $new_test_uri = "/pagead/ads?client=ca-pub-5785951125780041&dt=1186644785249&lmt=1186644784&format=728x15_0ads_al_s&output=html&correlator=1186644785249&url=$cached_url&ref=$cached_ref_url&ga_vid=1774040002.1186644785&ga_sid=1186644785&ga_hid=819217451&flash=9&u_h=1050&u_w=1680&u_ah=1024&u_aw=1680&u_cd=32&u_tz=-420&u_his=10&u_java=true&u_nplug=5&u_nmime=78";

cmp_ok($new_uri, 'eq', $new_test_uri, "match_and_log() new uri correct");


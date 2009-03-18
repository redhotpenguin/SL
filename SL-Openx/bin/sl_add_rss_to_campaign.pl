#/usr/bin/perl

use strict;
use warnings;

use XML::Feed;
use XML::RPC;

my $host = "https://app.silverliningnetworks.com/openx/www/api/v1/xmlrpc/";

my $login_url = 'LogonXmlRpcService.php';
my $url = $host;
my $cli = XML::RPC->new( $url . $login_url);

my $username = 'redhotpenguin';
my $password = 'yomaing';

my $campaign_id = 53;

my $res = $cli->call( 'logon', $username, $password );


my $sid = $res;

# get the banners

my $uri = 'BannerXmlRpcService.php';
$cli = XML::RPC->new( $url . $uri );
$res = $cli->call( 'getBannerListByCampaignId', $sid, $campaign_id);

my %banners;

if (ref($res) eq 'ARRAY') {
  # we have results
  foreach my $banner (@{$res}) {
    $banners{$banner->{bannerText}} = $banner->{url};
  }

}

my $rss = 'http://arkansasmatters.com/common/site_rss.php?feedname=news&cat=3';
my $feed = XML::Feed->parse(URI->new($rss))
  or die XML::Feed->errstr;

foreach my $item ($feed->entries) {

  unless (exists $banners{$item->title}) {
    warn "adding banner " . $item->title . "\n";

    $res = $cli->call('addBanner', $sid, 
                      { campaignId => $campaign_id, 
                        storageType => 'txt', 
                        bannerName => $item->title, 
                        bannerText => $item->title, 
                        statusText => $item->title, 
                        url => $item->link });

  } else {
    warn "banner " . $item->title . " already exists\n";
  }

}


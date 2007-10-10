package SL::Model::Ad::Google;

use strict;
use warnings;

use SL::Config ();
use SL::Model::Ad ();
use URI::Escape ();

our $DEBUG = 1;
our $CONFIG = SL::Config->new;

our $CLIENT_ID = $CONFIG->sl_google_client_id || die 'no sl_google_client_id';
our $CLIENT_ID_LENGTH = length($CLIENT_ID);

our $BASE_URL = $CONFIG->sl_google_base_url || die 'no sl_google_base_url';
our $BASE_URL_REGEX = qr/$BASE_URL/;
our $BASE_LENGTH = $CONFIG->sl_google_base_url_length || die 'no baselen';

our $CLIENT_ID_OFFSET = $CONFIG->sl_google_client_id_offset || die 'no sl_google_client_id_offset';

our $GOOGLE_AD_ID = $CONFIG->sl_google_ad_id || die 'no sl_google_ad_id';

use SL::Page::Cache;
my $PAGE_CACHE = SL::Page::Cache->new;

# this method matches catches outgoing requests to googles ad server
# and logs them

sub match_and_log {
    my ($class, $args_ref) = @_;

    # validate args
    my $url = $args_ref->{url};
    unless ($url) { warn("no url passed for log_and_match"); return; }
    my $ip = $args_ref->{ip};
    unless ($ip) { warn("no ip passed for log_and_match"); return; }
    my $referer = $args_ref->{referer};
    unless ($ip) { warn("no referer passed for log_and_match"); return; }

    # see if this is a google ad url
    my $potential_match = substr($url, 0, $BASE_LENGTH);
    return unless $potential_match =~ m/$BASE_URL_REGEX/;

    # ok it's a google ad, see if the client id matches
    # return 1 here since this is some form of google ad and mod_proxy should blabla
    return 1 unless (substr($url, $CLIENT_ID_OFFSET, $CLIENT_ID_LENGTH) eq $CLIENT_ID);

    # huzzah! we have a match, hit it yo
    SL::Model::Ad->log_view( $ip, $GOOGLE_AD_ID);
    warn("google ad view logged for ip $ip") if $DEBUG;

    # fixup the urls in the ad
    my $escaped_scheme = 'http%3A%2F%2F';

    # first grab the site url param from the google ad query string
    my ($escaped_site_url, $slash) = $url =~ m/url\=($escaped_scheme.*?)(\%2F)?\&(?:ga_vid|ref|cc)/;

    # unescape the url
    my $unescaped_site_url = URI::Escape::uri_unescape($escaped_site_url);
    if ($slash) {
      warn("appending slash $slash") if $DEBUG;
      $unescaped_site_url .= '/';
    }

    warn("FOund unescaped_site_url $unescaped_site_url") if $DEBUG;
    # see if we have a copy of this page in the page cache
    my $unescaped_cached_page_url = $PAGE_CACHE->cache_url({ url => $unescaped_site_url });
    unless ($unescaped_cached_page_url) {
        require Carp && Carp::cluck("ad request for $unescaped_site_url, but no cached page present\n");
        return;
    }
    warn("FOUND unescaped_cache_page_url  $unescaped_cached_page_url") if $DEBUG;
   my $escaped_cached_page_url = URI::Escape::uri_escape($unescaped_cached_page_url);
    warn(" escaped page cache_url  $escaped_cached_page_url") if $DEBUG;
    # good, we have this page cached, fixup the request
    $url =~ s/$escaped_site_url/$escaped_cached_page_url/;

    warn("substituted url is $url") if $DEBUG;
    # remove the http://host.com so that we can return the modified uri /boo/bar?foo=1
    substr($url, 0, $BASE_LENGTH, '');

    # see if there is a refering url 
   my ($escaped_site_referer_url, $r_slash) = $url =~ m/ref\=($escaped_scheme.*?)(\%2F)?\&(?:ga_vid|ref|cc)/;
    return $url unless $escaped_site_referer_url;
    my $unescaped_site_referer_url = URI::Escape::uri_unescape($escaped_site_referer_url);
    if ($r_slash) {
      warn("appending slash to referer") if $DEBUG;
      $unescaped_site_referer_url .= '/';
    }

    warn("FOUND unescaped site_referer_url $escaped_site_referer_url") if $DEBUG;
    # we have a refering url, grab the mirror page url from the cache
    $unescaped_cached_page_url = $PAGE_CACHE->cache_url({ url => $unescaped_site_referer_url });
    unless ($unescaped_cached_page_url) {
       print STDERR "google ad request referer $url, but no $unescaped_cached_page_url\n";
       return;
    }
    warn("FOUND cached referer page url $unescaped_cached_page_url") if $DEBUG;
    # good, we have this page cached, fixup the request
    $escaped_cached_page_url = URI::Escape::uri_escape($unescaped_cached_page_url);
    $url =~ s/$escaped_site_referer_url/$escaped_cached_page_url/;

    return $url;
}

1;

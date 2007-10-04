package SL::Model::Ad::Google;

use strict;
use warnings;

use SL::Config;
use SL::Model::Ad;

our $DEBUG = 1;
our $CONFIG = SL::Config->new;

our $CLIENT_ID = $CONFIG->sl_google_client_id || die 'no sl_google_client_id';
our $CLIENT_ID_LENGTH = length($CLIENT_ID);

our $BASE_URL = $CONFIG->sl_google_base_url || die 'no sl_google_base_url';
our $BASE_LENGTH = length($BASE_URL);

our $CLIENT_ID_OFFSET = $CONFIG->sl_google_client_id_offset || die 'no sl_google_client_id_offset';

our $GOOGLE_AD_ID = $CONFIG->sl_google_ad_id || die 'no sl_google_ad_id';

use SL::Page::Cache;
my $PAGE_CACHE = SL::Page::Cache->new;

# this method matches catches outgoing requests to googles ad server
# and logs them

sub match_and_log {
    my ($class, $args_ref) = @_;
    $DB::single = 1;
    # validate args
    my $url = $args_ref->{url};
    unless ($url) { warn("no url passed for log_and_match"); return; }
    my $ip = $args_ref->{ip};
    unless ($ip) { warn("no ip passed for log_and_match"); return; }
    my $referer = $args_ref->{referer};
    unless ($ip) { warn("no referer passed for log_and_match"); return; }

    # see if this is a google ad url
    return unless (substr($url, 0, $BASE_LENGTH) eq $BASE_URL);

    # ok it's a google ad, see if the client id matches
    # return 1 here since this is some form of google ad and mod_proxy should blabla
    return 1 unless (substr($url, $CLIENT_ID_OFFSET, $CLIENT_ID_LENGTH) eq $CLIENT_ID);

    # huzzah! we have a match, hit it yo
    SL::Model::Ad->log_view( $ip, $GOOGLE_AD_ID);
    warn("google ad view logged for ip $ip") if $DEBUG;

    # fixup the urls in the ad
    my $escaped_scheme = 'http%3A%2F%2F';

    # first grab the site url param from the google ad query string
    my ($site_url) = $url =~ m/url\=($escaped_scheme.*?)(:?\%2F)?\&(?:ga_vid|ref)/;

    # see if we have a copy of this page in the page cache
    my $cached_page_url = $PAGE_CACHE->cache_url($site_url);
    unless ($cached_page_url) {
        print STDERR "uh oh, google ad request for $url, but no cached $cached_page_url\n";
        return;
    }

    # good, we have this page cached, fixup the request
    $url =~ s/$site_url/$cached_page_url/;

    # remove the http://host.com so that we can return the modified uri /boo/bar?foo=1
    substr($url, 0, $BASE_LENGTH, '');

    # see if there is a refering url
    my ($site_referer_url) = $url =~ m/ref\=($escaped_scheme.*?)(:?\%2F)?\&(?:ga_vid|ref)/;
    return $url unless $site_referer_url;

    # we have a refering url, grab the mirror page url from the cache
    $cached_page_url = $PAGE_CACHE->cache_url($site_referer_url);
    unless ($cached_page_url) {
       print STDERR "google ad request referer $url, but no cached referer $cached_page_url\n";
       return;
    }

    # good, we have this page cached, fixup the request
    $url =~ s/$site_referer_url/$cached_page_url/;

    return $url;
}

1;

package SL::Model::Ad::Google;

use strict;
use warnings;

use SL::Config ();
use SL::Model::Ad ();
use URI::Escape ();

our $CONFIG;
BEGIN {
  $CONFIG = SL::Config->new();
}

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $CLIENT_ID = $CONFIG->sl_google_client_id || die 'no sl_google_client_id';
our $CLIENT_ID_LENGTH = length($CLIENT_ID);

our $BASE_URL = $CONFIG->sl_google_base_url || die 'no sl_google_base_url';
our $BASE_URL_REGEX = qr/$BASE_URL/;
our $BASE_LENGTH = $CONFIG->sl_google_base_url_length || die 'no baselen';

our $CLIENT_ID_OFFSET = $CONFIG->sl_google_client_id_offset || die 'no sl_google_client_id_offset';

our $GOOGLE_AD_ID = $CONFIG->sl_google_ad_id || die 'no sl_google_ad_id';

# this method matches catches outgoing requests to googles ad server
# and logs them

sub match_and_log {
    my ($class, $args_ref) = @_;

    my $ip    = $args_ref->{ip}    || warn("no ip passed")   && return;
    my $url   = $args_ref->{url}   || warn("no url passed")  && return;
    my $mac   = $args_ref->{mac}   || warn("no mac passed")  && return;
    my $user  = $args_ref->{user}  || warn("no user passed") && return;
    my $referer = $args_ref->{referer} || '';

    # see if this is a google ad url
    my $potential_match = substr($url, 0, $BASE_LENGTH);
    return unless $potential_match =~ m/$BASE_URL_REGEX/;

    # ok it's a google ad, see if the client id matches
    # return 1 here since this is some form of google ad and mod_proxy should blabla
	unless (substr($url, $CLIENT_ID_OFFSET, $CLIENT_ID_LENGTH) eq $CLIENT_ID) {
		warn("non sl google ad encountered, url $url") if $CONFIG->sl_mod_debug;
		return 1;
	}

    # huzzah! we have a match, hit it yo
    SL::Model::Ad->log_view( { ip => $ip,   ad_id => $GOOGLE_AD_ID, 
                               mac => $mac, user => $user,
                               url => $url, referer => $referer });

	# return if we are not in stealth mode
	unless ($CONFIG->sl_google_stealth ) {
		warn("not in google stealth mode, returning") if $CONFIG->sl_mod_debug;
		return 1;
	}
	return 1;
}

1;

__END__
    # fixup the urls in the ad
    my $escaped_scheme = 'http%3A%2F%2F';

    # first grab the site url param from the google ad query string
    my ($escaped_site_url, $slash) = $url =~ m/url\=($escaped_scheme.*?)(\%2F)?\&/;

    # unescape the url
    my $unescaped_site_url = URI::Escape::uri_unescape($escaped_site_url);
    if ($slash) {
      $unescaped_site_url .= '/';
    }

    # see if we have a copy of this page in the page cache
    my $unescaped_cached_page_url = $PAGE_CACHE->cache_url({ url => $unescaped_site_url });
    unless ($unescaped_cached_page_url) {
        warn "ad request for $unescaped_site_url, but no cached page present\n";
        return;
    }
   my $escaped_cached_page_url = URI::Escape::uri_escape($unescaped_cached_page_url);
    # good, we have this page cached, fixup the request
    if ($slash) {
        $url =~ s/$escaped_site_url$slash/$escaped_cached_page_url/;
      } else {
        $url =~ s/$escaped_site_url/$escaped_cached_page_url/;
   }

    # remove the http://host.com so that we can return the modified uri /boo/bar?foo=1
    substr($url, 0, $BASE_LENGTH, '');

    # see if there is a refering url 
   my ($escaped_site_referer_url, $r_slash) = $url =~ m/ref\=($escaped_scheme.*?)(\%2F)?\&/;
    return $url unless $escaped_site_referer_url;
    my $unescaped_site_referer_url = URI::Escape::uri_unescape($escaped_site_referer_url);
    if ($r_slash) {
      $unescaped_site_referer_url .= '/';
    }

    # we have a refering url, grab the mirror page url from the cache
    $unescaped_cached_page_url = $PAGE_CACHE->cache_url({ url => $unescaped_site_referer_url });
    unless ($unescaped_cached_page_url) {
       print STDERR "google ad request referer $url, but no $unescaped_cached_page_url\n";
       return $url;
    }

    # good, we have this page cached, fixup the request
    $escaped_cached_page_url = URI::Escape::uri_escape($unescaped_cached_page_url);

    if ($r_slash) {
           $url =~ s/$escaped_site_referer_url$r_slash/$escaped_cached_page_url/;
      } else {
           $url =~ s/$escaped_site_referer_url/$escaped_cached_page_url/;
   }

    return $url;
}

1;

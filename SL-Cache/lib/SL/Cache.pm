package SL::Cache;

use strict;
use warnings;

use SL::Config;
use Cache::FastMmap;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    my $CONFIG = SL::Config->new();

    $self->{data_cache} = Cache::FastMmap->new(
        raw_values => 1,
        cache_size => $CONFIG->sl_data_cache_size || '64m',
        share_file => $CONFIG->sl_data_cache_loc || '/tmp/sl_data_cache',
    );

    $self->{ad_cache} = Cache::FastMmap->new(
        cache_size => $CONFIG->sl_data_cache_size || '64m',
        share_file => $CONFIG->sl_data_cache_loc  || '/tmp/sl_ad_cache',
    );

    return $self;
}

sub data_cache {
    return shift->{data_cache};
}

sub ad_cache {
    return shift->{ad_cache};
}

sub url_blacklisted {
    my ( $self, $url ) = @_;
    die unless $url;

    my $blacklist_regex = $self->data_cache->get('blacklist_regex');

    unless ($blacklist_regex) {
        warn("Blacklist regex missing from cache!");
        return;
    }

    return 1 if ( $url =~ m{$blacklist_regex}i );
    return;
}

sub blacklist_user {
    my ( $self, $user_id ) = @_;
    die unless $user_id;

    $self->data_cache->set( join ( '|', 'user', $user_id ) => 1 );
    return 1;
}

sub is_user_blacklisted {
    my ( $self, $user_id ) = @_;
    die unless $user_id;

    my $is_blacklisted =
      $self->data_cache->get( join ( '|', 'user', $user_id ) );
    return 1 if $is_blacklisted;
    return;
}

sub add_subrequest {
    my ( $self, $url ) = @_;
    die unless $url;

    $self->data_cache->set( join ( '|', 'subreq', $url ) => 1 );
    return 1;
}

sub is_subrequest {
    my ( $self, $url ) = @_;
    die unless $url;

    my $tag = $self->data_cache->get( join ( '|', 'subreq', $url ) );
    return 1 if $tag;
    return;
}

sub add_known_html {
    my ( $self, $url, $content_type ) = @_;
    die unless ($url && $content_type);

    return unless ( $content_type =~ m/text\/html/ );

    $self->data_cache->set( join ( '|', 'known_html', $url ) => $content_type );
    return 1;
}

sub is_known_html {
    my ( $self, $url ) = @_;
    die unless $url;

    my $content_type =
      $self->data_cache->get( join ( '|', 'known_html', $url ) );
    return unless $content_type;
    return 1;
}

sub random_ad {
  my ($self, $ip) = @_;

  my $ads_arrayref = $self->ad_cache->get($ip);
  return unless $ads_arrayref;

  # grab a random ad
  my $ad = $ads_arrayref->[int(rand(scalar(@{$ads_arrayref})))];
  return $ad;
}

1;

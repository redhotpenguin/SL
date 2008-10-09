package SL::Cache;

use strict;
use warnings;

use SL::Config;
use Cache::FastMmap;
use Cache::Memcached ();


our $VERSION = 0.23;

our( $RAW_CACHE, $OBJ_CACHE, $MEMD );

BEGIN {
    our $CONFIG = SL::Config->new;
    $RAW_CACHE = Cache::FastMmap->new(
        raw_values => 1,
        cache_size => $CONFIG->sl_raw_cache_size || '64m',
        share_file => $CONFIG->sl_raw_cache_file || '/tmp/sl_raw_cache',
    );
    $OBJ_CACHE = Cache::FastMmap->new(
        cache_size => $CONFIG->sl_obj_cache_size || '64m',
        share_file => $CONFIG->sl_obj_cache_file || '/tmp/sl_obj_cache ',
    );

    $MEMD = Cache::Memcached->new({ servers => [ '127.0.0.1:11211' ] });
}

sub memd {
  return $MEMD;
}

sub new {
    my ( $class, %args ) = @_;
    die unless ( exists $args{type} );
    my $self = {};
    bless $self, $class;

    my $CONFIG = SL::Config->new();
    if ( $args{type} eq 'raw' ) {
        $self->{cache} = $RAW_CACHE;
    }
    elsif ( $args{type} eq 'obj' ) {
        $self->{cache} = $OBJ_CACHE;
    }
    else {
        die ' no such type ' . $args{type} . "\n";
    }

    return $self;
}

sub url_blacklisted {
    my ( $self, $url ) = @_;
    die unless $url;

    my $blacklist_regex = $self->{cache}->get(' blacklist_regex ');

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

    $self->{cache}->set( join ( '|', 'user', $user_id ) => 1 );
    return 1;
}

sub is_user_blacklisted {
    my ( $self, $user_id ) = @_;
    die unless $user_id;

    my $is_blacklisted = $self->{cache}->get( join ( '|', 'user', $user_id ) );
    return 1 if $is_blacklisted;
    return;
}

sub add_known_html {
    my ( $self, $url, $content_type ) = @_;
    unless ( $url && $content_type ) {
        warn("url $url or content type $content_type missing");
        return;
    }

    $self->{cache}->set( join ( '|', 'known_html', $url ) => $content_type );
    return 1;
}

sub is_known_not_html {
    my ( $self, $url ) = @_;
    die unless $url;

    my $content_type = $self->{cache}->get( join ( '|', 'known_html', $url ) );
    return 1 if ( $content_type && ( $content_type !~ m/text\/html/ ) );
    return;
}

sub deserialize_ads {
    my ( $self, $content ) = @_;

    my %ads;
    foreach my $line ( split ( "\n", $content ) ) {
        chomp($line);
        my ( $ad_id, $text, $css_url, $ip ) = split ( "\t", $line );
        push @{ $ads{$ip} }, [ $ad_id, $text, $css_url ];
    }

    return \%ads;
}

sub update_ads {
    my ( $self, $ads_hashref ) = @_;

    foreach my $ip ( keys %{$ads_hashref} ) {
        $self->{cache}->set( $ip => $ads_hashref->{$ip} );
    }

    return 1;
}

sub random_ad {
    my ( $self, $ip ) = @_;

    my $ads_arrayref = $self->{cache}->get($ip);
    return unless $ads_arrayref;

    # grab a random ad
    my $ad = $ads_arrayref->[ int( rand( scalar( @{$ads_arrayref} ) ) ) ];
    return $ad;
}

1;

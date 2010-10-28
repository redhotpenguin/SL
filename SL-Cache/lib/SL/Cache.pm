package SL::Cache;

use strict;
use warnings;

use Config::SL;
use Cache::Memcached ();


our $VERSION = 0.24;

our $Config = Config::SL->new;
our $Memd = Cache::Memcached->new({ servers => [ $Config->sl_memcached ] });

sub memd {
  return $Memd;
}


sub url_blacklisted {
    my ( $class, $url ) = @_;
    die unless $url;

    my $blacklist_regex = $class->memd->get(' blacklist_regex ');

    unless ($blacklist_regex) {
        warn("Blacklist regex missing from cache!");
        return;
    }

    return 1 if ( $url =~ m{$blacklist_regex}i );
    return;
}

sub blacklist_user {
    my ( $class, $user_id ) = @_;
    die unless $user_id;

    $class->memd->set( join ( '|', 'user', $user_id ) => 1 );
    return 1;
}

sub is_user_blacklisted {
    my ( $class, $user_id ) = @_;
    die unless $user_id;

    my $is_blacklisted = $class->memd->get( join ( '|', 'user', $user_id ) );
    return 1 if $is_blacklisted;
    return;
}

sub add_known_html {
    my ( $class, $url, $content_type ) = @_;
    unless ( $url && $content_type ) {
        warn("url $url or content type $content_type missing");
        return;
    }

    $class->memd->set( join ( '|', 'known_html', $url ) => $content_type );
    return 1;
}

sub is_known_not_html {
    my ( $class, $url ) = @_;
    die unless $url;

    my $content_type = $class->memd->get( join ( '|', 'known_html', $url ) );
    return 1 if ( $content_type && ( $content_type !~ m/text\/html/ ) );
    return;
}

sub deserialize_ads {
    my ( $class, $content ) = @_;

    my %ads;
    foreach my $line ( split ( "\n", $content ) ) {
        chomp($line);
        my ( $ad_id, $text, $css_url, $ip ) = split ( "\t", $line );
        push @{ $ads{$ip} }, [ $ad_id, $text, $css_url ];
    }

    return \%ads;
}

sub update_ads {
    my ( $class, $ads_hashref ) = @_;

    foreach my $ip ( keys %{$ads_hashref} ) {
        $class->memd->set( $ip => $ads_hashref->{$ip} );
    }

    return 1;
}

sub random_ad {
    my ( $class, $ip ) = @_;

    my $ads_arrayref = $class->memd->get($ip);
    return unless $ads_arrayref;

    # grab a random ad
    my $ad = $ads_arrayref->[ int( rand( scalar( @{$ads_arrayref} ) ) ) ];
    return $ad;
}

1;

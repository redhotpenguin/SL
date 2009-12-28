package SL::AdParser;

use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

SL::AdParser - a module to parse ads from html

=cut

sub parse_all {
    my $class = shift;
    my $subreqs = shift or die;

    die 'whoops arrayref needed' unless ref $subreqs eq 'ARRAY';

    my @adslots;
    foreach my $text ( @{$subreqs} ) {
        my $ad = $class->parse($text);
        push @adslots, $ad if $ad;
    }

    return \@adslots;
}

our $google_ad =
  qr/google_ad_width\s+\=\s+(\d+).*?google_ad_height\s+\=\s+(\d+)/s;

sub parse {
    my $class = shift;
    my $ad = shift or die 'need an ad to parse';

    die 'whoops must be a  ref' unless ref $ad eq 'SCALAR';

    # start by looking for google adsense
    if ( $$ad =~ m/google_ad_client/ ) {

        # we found a google adsense ad, get the height and width
        my ( $width, $height ) = $$ad =~ m/$google_ad/s;

        if ( $width && $height ) {

            my $adref = { width => $width, height => $height, ad => $ad };
            return $adref;

        }

    }

    return;
}

1;

package SL::Model::Ad;

use strict;
use warnings;

use Apache2::Log;

=head1 NAME

SL::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=head1 METHODS

=over 4

=item C<container( $css_url, $response, $ad )>

Method for ad insertion which wraps the whole page in a stylesheet

=cut

sub container {
    my ( $css_url, $decoded_content, $ad ) = @_;
	
	my $link    = qq{<link rel="stylesheet" href="$css_url" type="text/css" />};
    
    # Insert the stylesheet link
    my $regex = qr{^(.*?)(</\s*head)(.*)$}i;
    $decoded_content =~ s{$regex}{$1$link$2$3}mgs;

    # Insert the rest of the pieces
    my $top       = qq{<div id="sl_top">};
    my $container = qq{</div><div id="sl_ctr">};
    my $tail      = qq{</div>};
    $decoded_content =~ s{^(.*?)<body([^>]*?)>(.*?)</body>(.*)$}
                         {$1<body$2>$top$ad$container$3$tail</body>$4}ismx;

    return $decoded_content;
}

=item C<body_regex> 

Method for ad insertion which puts an html paragraph right after the body tag.

  $page_with_ad = body_regex( $decoded_content, $ad );

=over 4

=item C<$decoded_content> ( string )

The decoded HTTP::Response content.

=item C<$ad> ( string )

The ad content

=back

=cut

sub body_regex {
    my ( $decoded_content, $ad ) = @_;
    $decoded_content =~ s{^(.*?)<body([^>]*?)>}{$1<body$2>$ad}isxm;
    return $decoded_content;
}

=item C<_stacked_page($decoded_content, $ad)>

Method for ad insertion which puts the ad in it's own html page and serves that
inline with the original request response.

=cut

sub stacked {
    my ( $decoded_content, $ad ) = @_;
    my $html = qq{<html><body>$ad</body></html>};
    $decoded_content = join( "\n", $html, $decoded_content );
    return $decoded_content;
}

1;

package SL::Ad;

use strict;
use warnings;

use Apache2::Log;

=head1 NAME

SL::Ad

=head1 DESCRIPTION

This serves ads, ya see?

=head1 VARIABLES

=over 4

=item C<%string>

A global hash which is our initial ad persistence.  We reload apache using
Apache::Reload when we need to update the ads.  Replace later with a real
persistent store.

=back

=cut

my %string = ( 
        1 => q{<table width="100%"><tr width="100%"><td><a href="http://www.redhotpenguin.com"><img border="0" src="http://www.redhotpenguin.com/images/sl/banner_movies.gif"></a></td></tr></table>},
        2 => q{<table width="100%"><tr width="100%"><td><a href="http://www.redhotpenguin.com"><img border="0" src="http://www.redhotpenguin.com/images/sl/banner_starbucks.gif"></a></td></tr></table>},
        3 => q{<table width="100%"><tr width="100%"><td><a href="http://www.metro-region.org"><img border="0" src="http://www.redhotpenguin.com/images/sl/banner_weather.gif"></a></td></tr></table>},
    );

=head1 METHODS

=over 4

=item C<random_ad_string>

This serves a random ad in string format.  Suitable for inserting into an HTML
document.

=cut

sub random_as_string {
    my ($class, $r ) = @_;
    my $ad = $string{ int(rand(scalar(keys %string))) + 1 };
    $ad = "<!-- Ad by SilverLining -->" . $ad;
    $r->log->debug("Random ad string is $ad");
    return $ad;
}

1;

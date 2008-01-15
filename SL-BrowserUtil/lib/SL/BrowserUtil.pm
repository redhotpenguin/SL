package SL::BrowserUtil;

use strict;
use warnings;

use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

our $VERSION = 0.02;

# extract this to a utility library or something
sub is_a_browser {
    my ( $class, $ua ) = @_;

    unless ($ua) {
        require Carp && Carp::cluck("no ua passed");
        return;
    }

    # all browsers start with Mozilla, at least in apache
    my $browser_name;
    if (substr( $ua, 0, 7 ) eq 'Mozilla' ) {
		if ( (length($ua) > 49 ) &&
            ((substr( $ua, 49, 7 ) eq 'Opera 6') or
		    (substr( $ua, 47, 7 ) eq 'Opera 7' ))) {
			$browser_name = 'opera'; # opera 6 & 7
			return $browser_name;
        } else {
			$browser_name = 'mozilla';
			return $browser_name;
		}
	} elsif ( substr( $ua, 0, 5 ) eq 'Opera')  {
      $browser_name = 'opera';
		return $browser_name;
    } else {
      warn("$$ This is not a browser: $ua") if VERBOSE_DEBUG;
      return;
	}
}

1;

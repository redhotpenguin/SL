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
    if ( $browser_name = ( substr( $ua, 0, 7 ) eq 'Mozilla' )
      or ( $browser_name = substr( $ua, 0, 5 ) eq 'Opera' )  ){
          warn("$$ This is a browser: $browser_name")
            if VERBOSE_DEBUG;
            return $browser_name;
      }

      warn("$$ This is not a browser: $ua") if VERBOSE_DEBUG;
    return;
}

1;

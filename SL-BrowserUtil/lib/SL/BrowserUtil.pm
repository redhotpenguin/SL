package SL::BrowserUtil;

use strict;
use warnings;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $VERSION = 0.01;

# extract this to a utility library or something
sub not_a_browser {
    my ( $class, $ua ) = @_;

    unless ($ua) {
        require Carp && Carp::cluck("no ua passed");
        return;
    }

    # all browsers start with Mozilla, at least in apache
    if ( ( substr( $ua, 0, 7 ) eq 'Mozilla' )
      or ( substr( $ua, 0, 5 ) eq 'Opera' )  ){
          warn("$$ This is a browser: $ua")
            if DEBUG;
            return;
      }

      warn("$$ This is not a browser: $ua") if DEBUG;
    return 1;
}

1;

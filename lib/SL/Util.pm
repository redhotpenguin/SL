package SL::Util;

use strict;
use warnings;


sub not_html {
    my $content_type = shift;
    if ( $content_type !~ m/text\/html/ and $content_type !~ m/xml/ ) {
        return 1;
    }
}

1;

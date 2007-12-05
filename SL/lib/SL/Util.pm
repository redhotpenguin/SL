package SL::Util;

use strict;
use warnings;

sub not_html {
    my $content_type = shift;
    if ( $content_type !~ m/text\/html/ ) {
        return 1;
    }
}

# copied this from SL::Apache::PerlAccessHandler - should probably
# make a shared module for this and put the creds in the conf file.
1;

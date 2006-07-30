package SL::Util;

use strict;
use warnings;

use DBI;

sub not_html {
    my $content_type = shift;
    if ( $content_type !~ m/text\/html/ and $content_type !~ m/xml/ ) {
        return 1;
    }
}

# copied this from SL::Apache::PerlAccessHandler - should probably
# make a shared module for this and put the creds in the conf file.
1;

#!perl

#
# clean out expired close actions from the user blacklist
#

use strict;
use warnings;

use SL::Model;

my $dbh = SL::Model->connect;

my $expiry_interval = '60 min';

# have this make it expired once we push the proxy user blacklist part live
$dbh->do(
"DELETE FROM user_blacklist WHERE (now() - ts) > ?",
            undef, $expiry_interval
        );

# reclaim space from delete and update index stats
$dbh->do('VACUUM ANALYZE user_blacklist');


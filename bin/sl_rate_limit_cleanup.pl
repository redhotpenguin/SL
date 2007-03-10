#!perl

#
# clean out old data from rate_limit - this should be run from cron
# fairly frequently to keep the table small and fast.
#

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use SL::Model;

my $dbh = SL::Model->connect;

# delete anything older than 5 minutes - it's hard to imagine ever
# setting rate_limit higher than that!
$dbh->do('DELETE FROM rate_limit WHERE (now() - ts) > ?', undef, '5 min');

# reclaim space from delete and update index stats
$dbh->do('VACUUM ANALYZE rate_limit');


#!perl

#
# clean out expired close actions from the user blacklist
#

use strict;
use warnings;

use SL::Model;

my $dbh = SL::Model->connect;

my %reg_expires = (

    # expire kharma account rate limit once an hour
    '60 min' =>
      [ '0013102d6976', '0016b61c93e7', '0013102d6985', '0016b61c93e7', ],
);

foreach my $expiry_interval ( keys %reg_expires ) {

    # grab the macaddresses of the routers
    my @macaddrs = @{ $reg_expires{$expiry_interval} };
    foreach my $macaddr (@macaddrs) {

        # have this make it expired once we push the proxy user blacklist part live
        $dbh->do(
"DELETE FROM user_blacklist WHERE user_id like '\%$macaddr|\%' and (now() - ts) > ?",
            undef, $expiry_interval
        );
    }
}

# reclaim space from delete and update index stats
$dbh->do('VACUUM ANALYZE user_blacklist');


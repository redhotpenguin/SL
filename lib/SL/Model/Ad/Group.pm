package SL::Model::Ad::Group;

use strict;
use warnings;

use base 'SL::Model';

use constant DEFAULT_GROUP_ID => 1;

our $default_group;

sub from_ip {
    my $class = shift;
    my $ip    = shift;
    my $dbh   = $class->connect;
    my $sql   = <<SQL;
SELECT ad_group.ad_group_id
FROM ad_group
INNER JOIN reg_ad_group USING (ad_group_id)
INNER JOIN reg USING (reg_id)
WHERE reg.ip = ?
SQL
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $ip );
    $sth->execute or return;
    my $array_ref = $sth->fetchrow_arrayref;
    return $array_ref->[0];
}

BEGIN {
    $default_group = __PACKAGE__->default_group;

    sub default_group {
        my $class = shift;
        return $default_group if $default_group;
        my $dbh = $class->connect;
        my $sql = <<SQL;
SELECT ad_group.ad_group_id
FROM ad_group
WHERE ad_group_id = ?
SQL
        my $sth = $dbh->prepare($sql);
        $sth->bind_param( 1, DEFAULT_GROUP_ID );
        $sth->execute or die;
        my $array_ref = $sth->fetchrow_arrayref;
        $default_group = $array_ref->[0] || die;
    }
}

1;
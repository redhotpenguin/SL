#!perl -w

use strict;
use warnings;

use DBI;
my $db_options = {
                  RaiseError         => 1,
                  PrintError         => 1,
                  AutoCommit         => 1,
                  FetchHashKeyName   => 'NAME_lc',
                  ShowErrorStatement => 1,
                  ChopBlanks         => 1,
			  };


my $dsn = "dbi:Pg:dbname='sl';host=localhost";
my $dbh = DBI->connect($dsn, 'phred', '', $db_options);

# drop the test database if exists
my $cmd = `dropdb sl2`;
$cmd = `createdb sl2`;
$cmd = `pg_dump sl3 | psql sl2`;
$cmd = `psql -d sl2 -c 'alter table reg_ad_group drop constraint reg_ad_group_ad_group_id_fkey'`;
foreach my $t qw( view click link ad ad_group ) {
  $cmd = `psql -d sl2 -c "drop table $t"`;
}

my $sql2dir = '/Users/Phred/dev/sl/trunk/sql2/';

# create the new tables
$cmd = `psql -d sl2 -f "$sql2dir/func/ad_md5.sql"`;
foreach my $table qw( ad ad_linkshare ad_sl_group ad_sl click view ) {
  $cmd = `psql -d sl2 -f "$sql2dir/table/$table.sql"`;
}


$dsn = "dbi:Pg:dbname='sl2';host=localhost";
my $dbh2 = DBI->connect($dsn, 'phred', '', $db_options);

############################
# ad_groups

my $sql = <<SQL;
SELECT ad_group_id, name
FROM ad_group
SQL

my $group_hashref = $dbh->selectall_arrayref($sql, { Slice => {} });

$sql = <<SQL;
INSERT INTO ad_sl_group
VALUES (?,?)
SQL

my $sth = $dbh2->prepare($sql);
foreach my $group (@{$group_hashref}) {
    $sth->bind_param(1, $group->{ad_group_id});
	$sth->bind_param(2, $group->{name});
	$sth->execute;
}

#############################
# ads
$sql = <<SQL;
SELECT ad.ad_id, ad.active, ad.ad_group_id, ad.text, link.uri, link.md5
FROM ad
JOIN link USING (ad_id)
SQL

my $ad_hashref = $dbh->selectall_arrayref($sql, { Slice => {} });

# put them in sl2
$sql = <<SQL;
INSERT INTO ad (ad_id, active, md5)
VALUES (?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);

my $sql2 = <<SQL;
INSERT INTO ad_sl (ad_id, text, uri, ad_sl_group_id)
VALUES (?, ?, ?, ?)
SQL
my $sth2 = $dbh2->prepare($sql2);

foreach my $ad (@{$ad_hashref}) {
    $sth->bind_param(1, $ad->{ad_id});
    $sth->bind_param(2, $ad->{active});
    $sth->bind_param(3, $ad->{md5});
    $sth->execute;

	$sth2->bind_param(1, $ad->{ad_id});
    $sth2->bind_param(2, $ad->{text});
    $sth2->bind_param(3, $ad->{uri});
    $sth2->bind_param(4, $ad->{ad_group_id});
    $sth2->execute;
}

################################
# views

$sql = <<SQL;
SELECT ad_id, ts, ip
FROM view
SQL

my $view_arrayref = $dbh->selectall_arrayref($sql);

$sql = <<SQL;
INSERT INTO view (ad_id, cts, ip)
VALUES (?,?,?)
SQL

$sth = $dbh2->prepare($sql);

foreach my $view (@{$view_arrayref}) {
    $sth->bind_param(1, $view->[0]);
    $sth->bind_param(2, $view->[1]);
    $sth->bind_param(3, $view->[2]);
    $sth->execute;
}

#############################
# clicks

$sql = <<SQL;
SELECT click.ts, click.ip, link.ad_id
FROM click
JOIN link USING (link_id)
SQL

my $click_arrayref = $dbh->selectall_arrayref($sql);

$sql = <<SQL;
INSERT INTO click (cts, ip, ad_id)
VALUES (?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);

foreach my $click (@{$click_arrayref}) {
    $sth->bind_param(1, $click->[0]);
    $sth->bind_param(2, $click->[1]);
    $sth->bind_param(3, $click->[2]);
	$sth->execute;
}

1;

__END__

=head1 DESCRIPTION

[DESCRIPTION]

=head1 OPTIONS

=over 4

=item B<opt1>

The first option

=item B<opt2>

The second option

=back

=head1 TODO

=over 4

=item *

Todo #1

=back

=head1 BUGS

None yet

=head1 AUTHOR

[AUTHOR]

=cut

#===============================================================================
#
#         FILE:  sl_update_schema.pl
#
#        USAGE:  ./sl_update_schema.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  01/08/07 08:52:50 PST
#     REVISION:  ---
#===============================================================================

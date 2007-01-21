#!perl -w

use strict;
use warnings;

use DBI;
my $db_options = {
                  RaiseError         => 0,
                  PrintError         => 1,
                  AutoCommit         => 1,
                  FetchHashKeyName   => 'NAME_lc',
                  ShowErrorStatement => 1,
                  ChopBlanks         => 1,
			  };


my $new = 'sl2';
my $old = 'sl3';

my $dsn = "dbi:Pg:dbname='$old';host=localhost";
my $dbh = DBI->connect($dsn, 'phred', '', $db_options);

# drop the test database if exists
my $cmd = `dropdb $new`;
$cmd = `createdb $new`;
$cmd = `pg_dump $old | psql $new`;
$cmd = `psql -d $new -c 'alter table reg_ad_group drop constraint reg_ad_group_ad_group_id_fkey'`;
$cmd = `psql -d $new -c 'alter table ad drop constraint ad_group_id_fkey'`;
foreach my $t qw( view click link ad ad_group reg_ad_group) {
  $cmd = `psql -d $new -c "drop table $t"`;
}

my $sql2dir = '/Users/Phred/dev/sl/trunk/sql2/';

# create the new tables
foreach my $table qw( ad ad_linkshare router ad_sl router_ad_sl click view ) {
  $cmd = `psql -d $new -f "$sql2dir/table/$table.sql"`;
}

$dsn = "dbi:Pg:dbname='$new';host=localhost";
my $dbh2 = DBI->connect($dsn, 'phred', '', $db_options);

############################
# reg to router

my $sql = <<SQL;
SELECT reg_id, ip, serial_number, macaddr, code
FROM reg
SQL

my $reg_hashref = $dbh->selectall_arrayref($sql, { Slice => {} } );
$sql = <<SQL;
INSERT INTO router
( reg_id, ip, serial_number, macaddr, code)
VALUES
( ?,      ?,  ? ,           ?,        ?)
SQL

my $sth = $dbh2->prepare($sql);
foreach my $reg (@{$reg_hashref}) { 
    $sth->bind_param(1, $reg->{reg_id});
    $sth->bind_param(2, $reg->{ip});
    $sth->bind_param(3, $reg->{serial_number});
    $sth->bind_param(4, $reg->{macaddr});
    $sth->bind_param(5, $reg->{code});
    $sth->execute;
}

foreach my $column qw( ip serial_number macaddr code ) {
  $cmd = `psql -d $new -c 'alter table reg drop column $column'`;  
}


#### scratch this next section?  
############################
# ad_groups

#$sql = <<SQL;
#SELECT ad_group_id, name
#FROM ad_group
#SQL

#my $group_hashref = $dbh->selectall_arrayref($sql, { Slice => {} });

#$sql = <<SQL;
#INSERT INTO ad_sl_group
#VALUES (?,?)
#SQL

#my $sth = $dbh2->prepare($sql);
#foreach my $group (@{$group_hashref}) {
#    $sth->bind_param(1, $group->{ad_group_id});
#	$sth->bind_param(2, $group->{name});
#	$sth->execute;
#}


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
INSERT INTO ad_sl (ad_id, text, uri, reg_id)
VALUES (?, ?, ?, ?)
SQL
my $sth2 = $dbh2->prepare($sql2);

foreach my $ad (@{$ad_hashref}) {
    $sth->bind_param(1, $ad->{ad_id});
    $sth->bind_param(2, $ad->{active});
    $sth->bind_param(3, $ad->{md5});
    $sth->execute;

    # now get the reg_id
$sql = <<SQL;
SELECT reg_id from reg_ad_group
WHERE ad_group_id = ?
LIMIT 1
SQL

    my $reg_id = $dbh->selectcol_arrayref($sql, {}, ($ad->{ad_group_id}))->[0] 
        || 14;

	$sth2->bind_param(1, $ad->{ad_id});
    $sth2->bind_param(2, $ad->{text});
    $sth2->bind_param(3, $ad->{uri});
    $sth2->bind_param(4, $reg_id);
    eval { $sth2->execute };
    if ($@) {
      warn("duplicate encountered, reg id " . $ad->{reg_id});
    }
}

################################
# views

$sql = <<SQL;
select count(ad_id) from view
SQL

my $foo = $dbh->selectall_arrayref($sql);
print STDERR "Count is " . $foo->[0]->[0] . "\n";

$sql = <<SQL;
SELECT ad_id, ts, ip
FROM view
SQL

my $blarg = $dbh->prepare_cached($sql);
$blarg->execute;

$sql = <<SQL;
INSERT INTO view (ad_id, cts, ip)
VALUES (?,?,?)
SQL

$sth = $dbh2->prepare($sql);
my $i = 0;
{ 
    local $dbh2->{AutoCommit} = 0;
  while (my $view = $blarg->fetchrow_arrayref) {
  # foreach my $view (@{$view_arrayref}) {
    $sth->bind_param(1, $view->[0]);
    $sth->bind_param(2, $view->[1]);
    $sth->bind_param(3, $view->[2]);
    $sth->execute;
    $i++;
  }
  $dbh2->commit;
}
print STDERR "Hey we found $i views\n";

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


###### now link the ads to the routers
$sql = <<SQL;
SELECT reg_id, ad_group_id
FROM reg_ad_group;
SQL

my $reg_ad_group_arrayref = $dbh->selectall_arrayref($sql, { Slice => {} } );

$sql = <<SQL;
SELECT ad_id
FROM ad
WHERE ad_group_id = ?
SQL

my $new_sql = <<SQL;
INSERT INTO router_ad_sl
(router_id, ad_sl_id)
VALUES
(?, ?)
SQL

# handle for making the router_ad_sl entries
my $new_sth = $dbh2->prepare($new_sql);

$sth = $dbh->prepare($sql);
my $missing = 0;
foreach my $reg_ad_group ( @{$reg_ad_group_arrayref}) {
    # grab the router
    my $foo_sql = <<SQL;
SELECT router_id FROM router
WHERE reg_id = ?
SQL

    my $router_ary_ref = $dbh2->selectcol_arrayref($foo_sql, {}, 
        ( $reg_ad_group->{reg_id}));

    # find all ads in this reg ad group
    my $ary_ref = $dbh->selectall_arrayref($sql, {}, 
                                           ($reg_ad_group->{ad_group_id}));
    foreach my $foo_ad ( @{$ary_ref}) {
        $new_sth->bind_param(1, $router_ary_ref->[0]);
        $new_sth->bind_param(2, $foo_ad->[0]);
        
        my $rv = $new_sth->execute;
        if (!$rv) {
          warn("One missing: " . $foo_ad->[0]);
          $missing++;
        }
    }
}

    warn("This many missing: $missing");

$cmd = `psql -d $new -f "$sql2dir/func/ad_md5.sql"`;
$cmd = `psql -d $new -f "$sql2dir/trigger/md5.sql"`;


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

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

my $new = 'sl';
my $old = 'sl2';

my $dsn = "dbi:Pg:dbname='$old';";
my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );

$dsn = "dbi:Pg:dbname='$new';";
my $dbh2 = DBI->connect( $dsn, 'phred', '', $db_options );

############################
# reg

my $sql = <<SQL;
SELECT reg_id, email, password_md5, active FROM reg
SQL

my $reg_hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql = <<SQL;
INSERT INTO reg
( reg_id, email, password_md5, active)
VALUES
( ?,      ?,      ? ,                ?)
SQL

my $sth = $dbh2->prepare($sql);
foreach my $reg ( @{$reg_hashref} ) {
    $sth->bind_param( 1, $reg->{reg_id} );
    $sth->bind_param( 2, $reg->{email} );
    $sth->bind_param( 3, $reg->{password_md5} );
    $sth->bind_param( 4, $reg->{active} );
    $sth->execute;
}
my $table = 'reg';
my $max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");

###############
# ad
$sql = <<SQL;
select ad_id, active, md5, cts from ad
SQL

my $ad_hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql = <<SQL;
INSERT INTO ad
( ad_id, active, md5, cts)
VALUES
(?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$ad_hashref} ) {
    $sth->bind_param( 1, $reg->{ad_id} );
    $sth->bind_param( 2, $reg->{active} );
    $sth->bind_param( 3, $reg->{md5} );
    $sth->bind_param( 4, $reg->{cts} );
    $sth->execute;
}

$table = 'ad';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


print STDERR "starting ad_sl\n";

#####################
# ad_sl
$sql = <<SQL;
select ad_sl_id, ad_id, reg_id, text, uri, mts from ad_sl
SQL

my $ad_sl_hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql = <<SQL;
INSERT INTO ad_sl
( ad_sl_id, ad_id, reg_id, text, uri, mts)
VALUES
( ?, ?, ?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$ad_sl_hashref} ) {
    $sth->bind_param( 1, $reg->{ad_sl_id} );
    $sth->bind_param( 2, $reg->{ad_id} );
    $sth->bind_param( 3, $reg->{reg_id} );
    $sth->bind_param( 4, $reg->{text} );
    $sth->bind_param( 5, $reg->{uri} );
    $sth->bind_param( 6, $reg->{mts} );
    $sth->execute;
}

$table = 'ad_sl';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


print STDERR "starting ad_linkshare\n";
############################
# ad_linkshare
$sql = <<SQL;
select ad_linkshare_id, ad_id, mname, mid, linkid, linkname, linkurl, trackurl, category, displaytext, mts from ad_linkshare
SQL

my $hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql = <<SQL;
INSERT INTO ad_linkshare
(ad_linkshare_id, ad_id, mname, mid, linkid, linkname, linkurl, trackurl, category, displaytext, mts )
VALUES
( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$hashref} ) {
    $sth->bind_param( 1,  $reg->{ad_linkshare_id} );
    $sth->bind_param( 2,  $reg->{ad_id} );
    $sth->bind_param( 3,  $reg->{mname} );
    $sth->bind_param( 4,  $reg->{mid} );
    $sth->bind_param( 5,  $reg->{linkid} );
    $sth->bind_param( 6,  $reg->{linkname} );
    $sth->bind_param( 7,  $reg->{linkurl} );
    $sth->bind_param( 8,  $reg->{trackurl} );
    $sth->bind_param( 9,  $reg->{category} );
    $sth->bind_param( 10, $reg->{displaytext} );
    $sth->bind_param( 11, $reg->{mts} );
    $sth->execute;
}

$table = 'ad_linkshare';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


##################
# click

print "Starting click\n";
$sql = <<SQL;
select click_id, cts, ad_id, ip from click
SQL

$hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql     = <<SQL;
INSERT into click
(click_id, cts, ad_id, ip)
VALUES
(?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$hashref} ) {
    $sth->bind_param( 1, $reg->{click_id} );
    $sth->bind_param( 2, $reg->{cts} );
    $sth->bind_param( 3, $reg->{ad_id} );
    $sth->bind_param( 4, $reg->{ip} );
    $sth->execute;
}

$table = 'click';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


#########################
# router
print "Starting router\n";
$sql = <<SQL;
select router_id, ip, serial_number, macaddr from router
SQL

$hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql     = <<SQL;
INSERT into router
(router_id, ip, serial_number, macaddr)
VALUES
(?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$hashref} ) {
    $sth->bind_param( 1, $reg->{router_id} );
    $sth->bind_param( 2, $reg->{ip} );
    $sth->bind_param( 3, $reg->{serial_number} );
    $sth->bind_param( 4, $reg->{macaddr} );
    $sth->execute;
}

$table = 'router';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


##################
# subrequest
print "Starting subrequest\n";
$sql = <<SQL;
select url, ts from subrequest
SQL

$hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql     = <<SQL;
INSERT into subrequest
(url, ts)
VALUES
(?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$hashref} ) {
    $sth->bind_param( 1, $reg->{url} );
    $sth->bind_param( 2, $reg->{ts} );
    $sth->execute;
}


print STDERR "starting url\n";
#############
# url
$sql = <<SQL;
select url_id, url, blacklisted, reg_id, ts from url
SQL

$hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql     = <<SQL;
INSERT into url
(url_id, url, blacklisted, reg_id, ts)
VALUES
(?, ?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$hashref} ) {
    $sth->bind_param( 1, $reg->{url_id} );
    $sth->bind_param( 2, $reg->{url} );
    $sth->bind_param( 3, $reg->{blacklisted} );
    $sth->bind_param( 4, $reg->{reg_id} );
    $sth->bind_param( 5, $reg->{ts} );
    $sth->execute;
}


$table = 'url';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");



#####################
print STDERR "starting user_blacklist\n";
# user_blacklist
$sql = <<SQL;
select user_id, ts from user_blacklist
SQL

$hashref = $dbh->selectall_arrayref( $sql, { Slice => {} } );
$sql     = <<SQL;
INSERT into user_blacklist
(user_id, ts)
VALUES
(?, ?)
SQL

$sth = $dbh2->prepare($sql);
foreach my $reg ( @{$hashref} ) {
    $sth->bind_param( 1, $reg->{user_id} );
    $sth->bind_param( 2, $reg->{ts} );
    $sth->execute;
}

#################
# view
$sql = <<SQL;
select view_id, ad_id, cts, ip from view
SQL

print "Starting view\n";

my $sth1 = $dbh->prepare_cached( $sql, { Slice => {} } );
$sth1->execute;

$sql     = <<SQL;
INSERT into view
(view_id, ad_id, cts, ip)
VALUES
(?, ?, ?, ?)
SQL

$sth = $dbh2->prepare($sql);
while  ( my $reg = $sth1->fetchrow_hashref ) {
    $sth->bind_param( 1, $reg->{view_id} );
    $sth->bind_param( 2, $reg->{ad_id} );
    $sth->bind_param( 3, $reg->{cts} );
    $sth->bind_param( 4, $reg->{ip} );
    $sth->execute;
}


$table = 'view';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


##################
## everything else

print "ad_groups\n";

$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (1, 'default')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (2, 'fred home')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (3, 'linktoads')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (4, 'occ')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (5, 'northwest food show')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (6, 'jacob')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (7, 'linkshare')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (8, 'sweet inspiration')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (9, 'jeff home')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (10, 'village hot spot')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (11, 'hvh')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (12, 'text-links.com')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (13, 'todd home')");
$dbh2->do("INSERT INTO ad_group (ad_group_id, name) values (14, 'color broadband')");


$table = 'ad_group';
$max = $dbh2->selectcol_arrayref("select max($table\_id) from $table")->[0];
$dbh2->do("SELECT setval('$table\_$table\_id_seq', $max)");


print "ad__ad_groups\n";

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (13, 1)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (38, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (42, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (43, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (62, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (63, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (64, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (88, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (94, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (95, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (97, 2)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (53, 2)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (236, 3)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (240, 3)");


$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (251, 4)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (250, 4)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (249, 4)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (248, 4)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (245, 4)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (241, 4)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (247, 5)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (246, 5)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (242, 5)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (243, 5)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (244, 5)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (99, 6)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (98, 6)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (14, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (15, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (16, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (17, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (18, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (19, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (20, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (21, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (22, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (23, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (24, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (25, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (26, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (27, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (28, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (29, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (30, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (31, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (32, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (33, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (34, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (35, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (101, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (102, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (103, 7)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (104, 7)");


$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (44, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (54, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (55, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (56, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (57, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (58, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (60, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (61, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (65, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (66, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (67, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (68, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (69, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (70, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (71, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (72, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (73, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (74, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (75, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (76, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (79, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (80, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (81, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (82, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (83, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (84, 8)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (85, 8)");


$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (1, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (36, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (59, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (78, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (90, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (91, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (92, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (93, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (96, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (105, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (107, 9)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (108, 9)");


$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (37, 10)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (45, 10)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (51, 10)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (52, 10)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (89, 11)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (106, 12)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (109, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (110, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (111, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (224, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (225, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (226, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (227, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (228, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (229, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (230, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (231, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (232, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (233, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (234, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (237, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (238, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (239, 13)");
$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (252, 13)");

$dbh2->do("INSERT INTO ad__ad_group (ad_id, ad_group_id) values (235, 14)");

# map the router to router__ad_group

$dbh2->do("INSERT INTO router__ad_group (router_id, ad_group_id) values (22, 4)");
$dbh2->do("INSERT INTO router__ad_group (router_id, ad_group_id) values (7, 2)");


1;

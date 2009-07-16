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

use FindBin qw($Bin);
my $sql_root = "$Bin/../sql/table";

my $db = shift or die "gimme a database name yo\n";
my $host = shift or die "gimme a hostname yo\n\n";

my $dsn = "dbi:Pg:dbname='$db'";
my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );


# get to work

##############################

$dbh->do("alter table ad_zone add column image_href text");
$dbh->do("alter table ad_zone add column link_href text");
$dbh->do("alter table ad_zone add column weight integer default 1");
$dbh->do("update ad_size set grouping='8' where ad_size_id=23");
$dbh->do("update ad_size set grouping=9 where ad_size_id in (20,21)");
$dbh->do("update ad_size set name='SLN Micro Banner (600x31)' where ad_size_id=23");
$dbh->do("alter table ad_size drop column bug_height");
$dbh->do("alter table ad_size drop column bug_width");
$dbh->do("insert into ad_size (ad_size_id,name,css_url, grouping) values (24,'IAB Micro Bar (88x31)','',8)");

$dbh->do("alter table account add column zone_type  text default 'banner_ad' not null");

require SL::Model::App;
# grab any networks that have message bars assigned
my @ad_zones = SL::Model::App->resultset('AdZone')->search({ name => '_twitter_feed' });

my @razes = SL::Model::App->resultset('RouterAdZone')->search({ ad_zone_id => { -in => [ map { $_->ad_zone_id } @ad_zones ] }});

foreach my $raze (@razes) {

   $dbh->do("update account set zone_type='twitter' where account_id=" . $raze->router->account_id);
}

# grab any networks that have twitter feeds assigned
@ad_zones = SL::Model::App->resultset('AdZone')->search({ name => '_message_bar' });

@razes = SL::Model::App->resultset('RouterAdZone')->search({ ad_zone_id => { -in => [ map { $_->ad_zone_id } @ad_zones ] }});

foreach my $raze (@razes) {

   $dbh->do("update account set zone_type='msg' where account_id=" . $raze->router->account_id);
}



# move all the bugs into ad zones
my @bugs = SL::Model::App->resultset('Bug')->all;



foreach my $bug ( @bugs ) {

    next unless (($bug->ad_size_id == 1) or ($bug->ad_size_id == 10) or ($bug->ad_size_id == 12) or ($bug->ad_size_id == 23));

    warn("transforming bug for account " . $bug->account->name);


    # get the ad zone id of the new bug => zone
    my $ad_size_id;
    if ($bug->ad_size_id != 23) {
      $ad_size_id = 22;
    } else {
      $ad_size_id = 24;
    }


    my $name = "Branding Image from bug id " . $bug->bug_id;
    $dbh->do(<<SQL, {}, ($name,$bug->account_id, $ad_size_id,14, $bug->image_href, $bug->link_href, 't'));
INSERT INTO AD_ZONE
(code,name,account_id,ad_size_id,reg_id,image_href,link_href, is_default)
VALUES
( '', ?,   ?,         ?,         ?,     ?,         ?, ? )
SQL

    my $ad_zone_id = $dbh->selectall_arrayref(<<SQL, {Slice => {}}, $name,$bug->image_href, $bug->link_href)->[0]->{ad_zone_id};
SELECT ad_zone_id FROM ad_zone WHERE name  = ? and image_href=? and link_href=?
SQL

    warn("new ad zone for account bug, zone id $ad_zone_id");

    my $routers = $dbh->selectall_arrayref(<<SQL, {Slice => {}}, $bug->account_id);
SELECT router_id from router where account_id = ?
SQL

    foreach my $router_id (@{$routers}) {

        warn("new router ad zone for router $router_id, zone $ad_zone_id");
        $dbh->do(sprintf("insert into router__ad_zone (router_id, ad_zone_id) values ( %s, %s ) ", $router_id->{router_id}, $ad_zone_id));

    }

}

$dbh->do("alter table ad_zone drop column bug_id");

my @accounts = SL::Model::App->resultset('Account')->all;

foreach my $account (@accounts) {

  my @banners = SL::Model::App->resultset('AdZone')->search({
                     'ad_zone.account_id' => $account->account_id,
                     'ad_zone.ad_size_id' => { -in => [ qw( 1 10 12 23 ) ] },
                     'ad_zone.active' => 't',
		 },
		    { -join => [ qw( router__ad_zone ) ]},
);

  my $default = 0;
  foreach my $banner ( @banners ) {
    if ($banner->is_default == 1) {
      $default = 1;
      last;
    }
  }

  unless ($default == 1) {
    $banners[0]->is_default(1);
    $banners[0]->update;
  }


  my @brands = SL::Model::App->resultset('AdZone')->search({
                     'ad_zone.account_id' => $account->account_id,
                     'ad_zone.ad_size_id' => { -in => [ qw( 24 20 22 ) ] },
                     'ad_zone.active' => 't',
		    { -join => [ qw( router__ad_zone ) ]},
 });
  
  $default = 0;
  foreach my $banner ( @brands ) {
    if ($banner->is_default == 1) {
      $default = 1;
      last;
    }
  }

  unless ($default == 1) {
    $brands[0]->is_default(1);
    $brands[0]->update;
  }

}


warn("finished");

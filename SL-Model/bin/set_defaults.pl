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

my $db   = shift or die "gimme a database name yo\n";
my $host = shift or die "gimme a hostname yo\n\n";

my $dsn = "dbi:Pg:dbname='$db';host='$host'";
my $dbh = DBI->connect( $dsn, 'phred', '', $db_options );

# get to work

##############################
use SL::Model::App;
my @accounts = SL::Model::App->resultset('Account')->all;
$DB::single = 1;
my ($banners, $msgs,$tweets, $nodefaults ) = ( 0,0,0,0);
foreach my $account (@accounts) {

    warn("checking account " . $account->name);


    my @default_adzones = SL::Model::App->resultset('AdZone')->search({
	account_id => $account->account_id,
        is_default => 't', });

    unless (@default_adzones > 0) {
    	warn("no default adzones");
	$nodefaults++;
	$DB::single = 1;
	$account->zone_type('banner_ad');
	$account->update;
	my ($randzone) = SL::Model::App->resultset('AdZone')->search({
		active => 't',
		ad_size_id => { -in => [ qw( 1 10 12 ) ] },});

	die 'no zones for account ' . $account->name unless $randzone;

	$randzone->is_default(1);
	$randzone->update;

	my ($randbug) = SL::Model::App->resultset('AdZone')->search({
		active => 't',
		ad_size_id => { -in => [ qw( 20 22 ) ] },});

	die 'no bugs for account ' . $account->name unless $randbug;

	$randbug->is_default(1);
	$randbug->update;

	next;    	
    }

    warn("=> Found " . scalar(@default_adzones) . " default ad zones");


    my ($splash, $banner, $twitext, $twitbrand, $brand) = ( 0,0,0,0,0);
    foreach my $dz (@default_adzones) {
	
	if ($dz->ad_size_id =~ m/(?:1|10|12)/) {
           warn("banner ad default found");
           $banner++;
        } elsif ($dz->ad_size_id == 23) {
	    warn("twitter or text zone found");
	    $twitext++;
	} elsif ($dz->ad_size_id == 24) {
	    warn("twibrand found");
	    $twitbrand++;
	} elsif ($dz->ad_size_id == 15) {
	    warn("splash zone found");
	    $splash++;
	} elsif ($dz->ad_size_id =~ m/(?:20|22)/) {
	    warn("branding image found");
	    $brand++;
	}
    }

    if ($brand > 1) {
	warn("too many brands: $brand");
    }
    if ($banner > 1) {
	warn("too many banners: $banner");
    }
    if ($twitext > 1) {
	warn("too many twitexts: $twitext");
    }
    if ($twitbrand > 1) {
	warn("too many twitbrand: $twitbrand");
    }
    if ($splash > 1 ) {
	warn("too many splash: $splash");
    }


    if ($twitbrand && $twitext && (!$banner && !$brand)) {
	warn("twitext zone active, account ok\n\n");
	die unless $account->zone_type =~ m/(?:twitter|msg)/;
	$msgs++ if $account->zone_type eq 'msg';
        $tweets++ if $account->zone_type eq 'twitter';

    } elsif ($banner && $brand && (!$twitbrand && !$twitext)) {
	warn("banner ad zone active, account ok\n\n");
	die unless $account->zone_type =~ m/(?:banner_ad)/;
	$banners++;

    } elsif ($twitext && !$twitbrand) {
    	warn("update_error, twitext and no twitbrand");

	my ($brand) = SL::Model::App->resultset('AdZone')->search({
		ad_size_id => { -in => [ qw( 24 ) ] },
		account_id => $account->account_id,
		active => 't',});

	die "no twitbrand for account " . $account->name unless ($brand);
	$DB::single = 1;    
    	$brand->is_default(1);
	$brand->update;


    } elsif ($banner && !$brand) {
    	warn("update_error, banner and no brand, twit? $twitext");

	my ($brand) = SL::Model::App->resultset('AdZone')->search({
		ad_size_id => { -in => [ qw( 20 22 ) ] },
		account_id => $account->account_id,
		active => 't'});

	die "no brand for account " . $account->name unless ($brand);
	$DB::single = 1;    
    	$brand->is_default(1);
	$brand->update;
    }
	   



}

warn("total nodefaults: $nodefaults");
warn("total tweets: $tweets");
warn("total msgs: $msgs");
warn("total banners: $banners");
exit;

__END__

	next;    

    my @routers =
      SL::Model::App->resultset('Router')
      ->search( { active => 't', account_id => $account->account_id, } );

    next unless @routers;

    warn("=> Found " . scalar(@routers) . " routers");


    my @razes =
      SL::Model::App->resultset('RouterAdZone')
      ->search(
        { router_id => { -in => [ map { $_->router_id } @routers ] }, } );

    next unless @razes;

    warn("==> Found " . scalar(@razes) . " router ad zones");

    my @banners = SL::Model::App->resultset('AdZone')->search(
        {
    	account_id => $account->account_id,
            ad_size_id => { -in => [qw( 1 10 12 23 )] },
            ad_zone_id => { -in => [ map { $_->ad_zone_id } @razes ] }
        }
    );

    next unless @banners;

    $DB::single = 1;

    my $default;
    foreach my $banner (@banners) {
        if ( $banner->is_default == 1 ) {
            $default = $banner;
            last;
        }
    }

    unless ($default) {
        $banners[0]->is_default(1);
        $banners[0]->update;
        $default = $banners[0];
    }

    if ( $default->name eq '_twitter_feed' ) {
        $account->zone_type('twitter');
    }
    elsif ( $default->name eq '_message_bar' ) {
        $account->zone_type('msg');
    }
    else {
        $account->zone_type('banner_ad');
    }
    $account->update;

    my $zones = ( $default->ad_size_id == 23 ) ? [qw( 24 )] : [qw( 20 22 )];

    my @brands = SL::Model::App->resultset('AdZone')->search(
        {
    	account_id => $account->account_id,
    	ad_size_id => { -in => $zones },
            ad_zone_id => { -in => [ map { $_->ad_zone_id } @razes ] }
        }
    );

    next unless @brands;

    my %brands;

    foreach my $banner (@brands) {

      next if defined $banner->code;

        $brands{ $banner->ad_zone_id } = {
            image_href => $banner->image_href,
            link_href  => $banner->link_href,
            is_default => $banner->is_default,
        };

    }

   next unless keys %brands;
                    use Data::Dumper;
    warn("deduping " . Dumper(\%brands));


    foreach my $brand_id ( keys %brands ) {

        foreach my $possible_dup ( keys %brands ) {

            # skip self
            next if $brand_id == $possible_dup;


            if (
                (
                    $brands{$brand_id}->{image_href} eq
                    $brands{$possible_dup}->{image_href}
                )
                && ( $brands{$brand_id}->{link_href} eq
                    $brands{$possible_dup}->{link_href} )
              )
            {

                my ($dupe) =
                  SL::Model::App->resultset('AdZone')
                  ->search( { ad_zone_id => $possible_dup } );

                    warn("deleting dupe");

                $dupe->active(0);
                $dupe->update;

                delete $brands{$possible_dup};
            }

        }

    }

    my $bdefault = 0;
    foreach my $banner (keys %brands) {

        if ( $brands{$banner}->{is_default} == 1 ) {

          warn("found default brand for account " . $account->name);
            $bdefault = 1;
            last;
        }
    }


    unless ($bdefault == 1) {
      my ($key) = (keys %brands);

      my ($default) = SL::Model::App->resultset('AdZone')->search({
       ad_zone_id => $key } );

      $default->is_default(1);
      $default->update;
          warn("made default brand for account " . $account->name);
    }

}

warn("finished");

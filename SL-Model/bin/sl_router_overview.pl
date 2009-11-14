#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Pg;
use Data::Dumper;
use SL::Model;
use SL::Model::App;

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

# 24 hours worth of router data and write a csv file

my $yesterday = DateTime->now( time_zone => "local" )->subtract( hours => 24 );

my $dbh = SL::Model->connect;

warn("prepping devices") if DEBUG;

# devices
my $sql = <<'SQL';
SELECT checkin.kbup, checkin.kbdown,
account.account_id, checkin.cts, router.router_id,
checkin.ping_ms, checkin.speed_kbytes,
checkin.memfree, checkin.gateway_quality,checkin.users,
checkin.load
FROM checkin, router, account
WHERE checkin.cts > '%s'
and router.account_id = account.account_id and
checkin.router_id = router.router_id and
account.beta = 't'
ORDER BY cts desc
SQL

$sql = sprintf( $sql, DateTime::Format::Pg->format_datetime($yesterday) );

my $results = $dbh->selectall_arrayref( $sql, { Slice => {} } );

warn("aggregating devices") if DEBUG;

# group this data by account
use constant PING_MS         => 0;
use constant SPEED_KBYTED    => 0;
use constant MEMFREE         => 0;
use constant GATEWAY_QUALITY => 0;
use constant KBUP            => 0;
use constant KBDOWN          => 0;
use constant ROUTER_CTS      => 0;

my %refined;
my $now = DateTime->now( time_zone => "local" );
foreach my $row (@$results) {

    my $dt = DateTime::Format::Pg->parse_datetime( $row->{cts} );
    $dt->set_time_zone('local');

    # and group by router
    push @{ $refined{ $row->{account_id} }{routers}{ $row->{router_id} } },
      {
        ping_ms         => $row->{ping_ms},
        speed_kbytes    => $row->{speed_kbytes},
        memfree         => $row->{memfree},
        gateway_quality => $row->{gateway_quality},
        kbup            => $row->{kbup},
        kbdown          => $row->{kbdown},
	users           => $row->{users},
        cts             => $dt,
        load            => $row->{load},
      };

}

warn("prepping users") if DEBUG;

# users
$sql = <<'SQL';
SELECT account.account_id, usertrack.mac, usertrack.cts,
usertrack.kbup, usertrack.kbdown, router.router_id
FROM usertrack, account, router
WHERE
router.account_id = account.account_id
AND usertrack.router_id = router.router_id
AND usertrack.cts > '%s'
AND account.beta = 't'
ORDER BY usertrack.cts DESC
SQL

$sql = sprintf( $sql, DateTime::Format::Pg->format_datetime($yesterday) );

my $users = $dbh->selectall_arrayref( $sql, { Slice => {} } );
warn("aggregating users") if DEBUG;
my %user_refined;
foreach my $row (@$users) {


    my $dt = DateTime::Format::Pg->parse_datetime( $row->{cts} );
    $dt->set_time_zone('local');
    # and group by user
    push @{ $user_refined{ $row->{router_id} }{users}{ $row->{mac} } },
      {
        kbup   => $row->{kbup},
        kbdown => $row->{kbdown},
        router => $row->{router_id},
        cts    => $dt,
      };

}

foreach my $account_id ( keys %refined ) {

    warn("processing account id $account_id") if DEBUG;
    my ($account) =
      SL::Model::App->resultset('Account')
      ->search( { account_id => $account_id } );

    die "missing account for account $account_id" unless $account;

    # aggregate the router data
    my $megabytes_total = 0;
    foreach my $router_id ( keys %{ $refined{$account_id}{routers} } ) {

        warn("processing router id $router_id") if DEBUG;

        my @array;
        for ( 0 .. ( 24 * 12 ) ) {    # 5 minutes
            push @array, [
                $yesterday->clone->add( minutes => 5 * $_ ),    # cts
                0,                                             # kbdown
                0,                                             # kbup
                0,                                             # users
                0,                                             # checkin bit
                0,                                             # ping_ms
                0,                                             # speed_kbytes
                0,                                             # memfree
                0,                                             # gateway quality
                0,                                             # load
            ];
        }

        # loop over the data
        #        $DB::single = 1;
        my $router_traffic = 0;

        my @sorted_checkins =
          sort { $a->{cts}->epoch <=> $b->{cts}->epoch }
          @{ $refined{$account_id}{routers}{$router_id} };

	# start with yesterday and work forward

        for ( my $i = 1 ; $i <= $#sorted_checkins ; $i++ ) {

	    my $slot_idx;
            # figure out what array slot this belongs in
            for ( my $j = 0 ; $j < $#array ; $j++ ) {

                # see if this row fits in the first time slot
                unless (
                    (
                        $sorted_checkins[$i]->{cts}->epoch >=
                        $array[$j]->[0]->epoch
                    )
                    && ( $sorted_checkins[$i]->{cts}->epoch <=
                        $array[ $j + 1 ]->[0]->epoch )
                  )
                {

                    # not in this time slot
                    next;
                }
                else {
		    warn("got slot index $j ") if DEBUG;
		    warn("down " . $sorted_checkins[$i]->{kbdown}) if DEBUG;
		    warn("up " . $sorted_checkins[$i]->{kbup}) if DEBUG;
		    
                    $slot_idx = $j;
                    last;
                }
            }
            unless (defined $slot_idx) {
#		warn("hey no slot idx but it is $slot_idx");
		$sorted_checkins[$i]->{cts} = $sorted_checkins[$i]->{cts}->ymd . " - " . $sorted_checkins[$i]->{cts}->hms;
		$array[0]->[0] = $array[0]->[0]->ymd . " " . $array[0]->[0]->hms;
		warn("checkin range top is " . Dumper($array[0]->[0]));


		$array[$#array]->[0] = $array[$#array]->[0]->ymd . " " . $array[$#array]->[0]->hms;
		warn("checkin range bottom is " . Dumper($array[$#array]->[0]));

                warn("checkin $i found outside time range: " . Dumper($sorted_checkins[$i]->{cts}));
		next;

            }

            warn("found a slot $slot_idx") if VERBOSE_DEBUG;

            # check to make sure an existing entry doesn't exist
            if ( $array[$slot_idx]->[4] > 0 ) {
                warn("existing checkin for array element $i") if DEBUG;
                next;    # next checkin
            }
            my $row      = $sorted_checkins[$i];
            my $last_row = $sorted_checkins[ $i - 1 ];

            # get the difference if traffic numbers not reset
            if (   ( $row->{kbup} >= $last_row->{kbup} )
                and ( $row->{kbdown} >= $last_row->{kbdown} ) )
            {

            $array[$slot_idx]->[1] = $row->{kbdown} - $last_row->{kbdown};
            $array[$slot_idx]->[2] = $row->{kbup} - $last_row->{kbup};

            } else {
		# HACK!  Sometimes nodogsplash isn't accurate, so zero it

		warn "oops - " . $row->{kbdown}/1024 . " , " . $last_row->{kbdown}/1024 if DEBUG;
		warn "oops - " . $row->{kbup}/1024 . " , " . $last_row->{kbup}/1024 if DEBUG;
		warn "OOPS - " . $row->{cts}->hms if DEBUG;
		$array[$slot_idx]->[1] = 0;
		$array[$slot_idx]->[2] = 0;

	    }

            warn(
                sprintf( "kbup %s, kbdown %s", $row->{kbup}/1024, $row->{kbdown}/1024 ) ) if DEBUG;

            # bit to indicate a checkin took place for this device
            $array[$slot_idx]->[4] = 1;
	    $array[$slot_idx]->[3] = $row->{users} || 0;

            # total megs
            $megabytes_total += ( $array[$slot_idx]->[1] + $array[$slot_idx]->[2] );
            $router_traffic  += ( $array[$slot_idx]->[1] + $array[$slot_idx]->[2] );

            # ping time
            $array[$slot_idx]->[5] = $row->{ping_ms};

            # speed megabits per second
            $array[$slot_idx]->[6] =
              sprintf( "%2.1f", ( $row->{speed_kbytes} * 8 ) / 1024 );

            # memfree
            $array[$slot_idx]->[7] = $row->{memfree} / 1024;

            # gateway quality
            $array[$slot_idx]->[8] = $row->{gateway_quality};

	    # load
            $array[$slot_idx]->[9] = $row->{load};
        }

        my ($router) =
          SL::Model::App->resultset('Router')
          ->search( { router_id => $router_id } );

        # uptime willis!!
        my $unchecked_count = grep { !$_->[4] } @array;
        my $uptime = 100 * ( $#array - $unchecked_count ) / $#array;

        if ( $unchecked_count == 0 ) {

            $router->checkin_status("100% Uptime! (last 24 hrs)");

        }
        else {

            $router->checkin_status(
                sprintf(
                    "%2.2f%% uptime, %d failed checkins",
                    $uptime, $unchecked_count
                )
            );
        }


        # aggregate the user data
        my %router_users;

	for ( my $i = 0 ; $i < $#array ; $i++ ) {


	    foreach my $mac ( keys %{ $user_refined{$router_id}{users} } ) {

		$router_users{$router_id}{$mac} = 1;

		# loop over the data
		foreach my $row (
		    sort { $a->{cts}->epoch <=> $b->{cts}->epoch }
		    @{ $user_refined{$router_id}{users}{$mac} } )
		{


		    # see if this row fits in the first time slot
		    unless (
			(
			 $row->{cts}->epoch >=
			 $array[$i]->[0]->epoch
			)
			&& ( $row->{cts}->epoch <=
                        $array[ $i + 1 ]->[0]->epoch )
			)
		    {

			# not in this time slot
			next;
		    }
		    else {
#			$array[$i]->[3]++;
			warn(sprintf("mac %s after %s and before %s",
				     $mac, $row->{cts}->hms,
				     $row->{cts}->hms)) if DEBUG;
			last;
		    }
                }


            }
        }

        $router->users_daily( scalar( keys %{ $router_users{$router_id} } ) );

        $router->traffic_daily( int( $router_traffic / 1024 ) );
        $router->update;

	# reverse for the graph
	@array = reverse(@array);

        ##################################
        # write the uptime
        my $filename = join( '/',
            $account->report_dir_base, "router_" . $router_id . "_uptime.csv" );

        my $fh;
        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            $line->[0] = $line->[0]->strftime("%l:%M %p");
            print $fh join( ',', @{$line}[ 0, 4 ] ) . "\n";
        }
        close($fh) or die $!;

        ##########################
        # write out the ping time graph
        $filename = join( '/',
            $account->report_dir_base, "router_" . $router_id . "_ping.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            print $fh join( ',', @{$line}[ 0, 5 ] ) . "\n";
        }
        close($fh) or die $!;

        ##########################
        # write out the speed graph
        $filename = join( '/',
            $account->report_dir_base, "router_" . $router_id . "_speed.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            print $fh join( ',', @{$line}[ 0, 6 ] ) . "\n";
        }
        close($fh) or die $!;

        ##########################
        # write out the memory graph
        $filename = join( '/',
            $account->report_dir_base,
            "router_" . $router_id . "_memfree.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            print $fh join( ',', @{$line}[ 0, 7 ] ) . "\n";
        }
        close($fh) or die $!;

        ##########################
        # write out the gwqual graph
        $filename = join( '/',
            $account->report_dir_base, "router_" . $router_id . "_gwqual.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            print $fh join( ',', @{$line}[ 0, 8 ] ) . "\n";
        }
        close($fh) or die $!;

	##########################
        # write out the load graph
        $filename = join( '/',
            $account->report_dir_base, "router_" . $router_id . "_load.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            print $fh join( ',', @{$line}[ 0, 9 ] ) . "\n";
        }
        close($fh) or die $!;



        ##########################
        # write out the traffic graph
        $filename = join( '/',
            $account->report_dir_base,
            "router_" . $router_id . "_traffic.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            $line->[1] =
              sprintf( "%.2f", ($line->[1]*1000*8/1024/1024/300  ));
            $line->[2] =
              sprintf( "%.2f", (-1 * $line->[2]*1000*8/1024/1024/300));
            print $fh join( ',', @{$line}[ 0, 1, 2 ] ) . "\n";
        }
        close($fh) or die $!;

        ############################

        ##########################
        # write out the users graph
        $filename = join( '/',
            $account->report_dir_base, "router_" . $router_id . "_users.csv" );

        open( $fh, '>', $filename )
          or die "could not open $filename: " . $!;

        foreach my $line (@array) {
            print $fh join( ',', @{$line}[ 0, 3 ] ) . "\n";
        }
        close($fh) or die $!;

    }

}

__END__

    # now update the router totals
    foreach my $router_id ( keys %router_users ) {
        my ($router) =
          SL::Model::App->resultset('Router')
          ->search( { router_id => $router_id } );

        $router->users_daily( scalar( keys %{ $router_users{$router_id} } ) );
        $router->update;
    }

    # reinitialize the array
    #    $DB::single = 1;
    $_->[0] = $_->[0]->strftime("%l:%M %p") for @array;
    warn( "array is " . Dumper( \@array ) ) if DEBUG;

    # users and traffic last 24 hours
    $account->users_today( scalar( keys %{ $refined{$account_id}{users} } ) );
    $account->megabytes_today( int($megabytes_total) );
    $account->update;

    my $filename =
      join( '/', $account->report_dir_base, "network_overview.csv" );

    my $fh;
    open( $fh, '>', $filename ) or die "could not open $filename: " . $!;
    foreach my $line (@array) {
        print $fh join( ',', @{$line}[ 0 .. 3 ] ) . "\n";
    }
    close $fh or die $!;

    warn("wrote file $filename") if DEBUG;
}

#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Pg;
use Data::Dumper;
use SL::Model;
use SL::Model::App;
use Clone;

use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

# grab the checkin data for the last 24 hours and write a csv file

my $yesterday = DateTime->now( time_zone => "local" )->subtract( hours => 24 );

my @Array;
for ( 0 .. 24 * 12 ) {    # 12 times/hour * 24 times/day
    push @Array, [
        $yesterday->clone->add( minutes => 5 * $_ ),    # cts
        0,                                              # kbdown
        0,                                              # kbup
        0,                                              # users
        0,                                              # checkin bit
    ];
}

my $dbh = SL::Model->connect;

# devices
my $sql = <<'SQL';
SELECT checkin.kbup, checkin.kbdown, checkin.users,
account.account_id, checkin.cts, router.router_id
FROM checkin, router, account
WHERE checkin.cts > '%s'
and router.account_id = account.account_id and
checkin.router_id = router.router_id
AND account.beta='t'
ORDER BY cts desc
SQL

$sql = sprintf( $sql, DateTime::Format::Pg->format_datetime($yesterday) );

my $results = $dbh->selectall_arrayref( $sql, { Slice => {} } );

# group this data by account
my %refined;
my $now = DateTime->now( time_zone => "local" );
warn("processing checkin raw data") if DEBUG;
foreach my $row (@$results) {

    my $dt = DateTime::Format::Pg->parse_datetime( $row->{cts} );
    $dt->set_time_zone('local');

    # and group by router
    push @{ $refined{ $row->{account_id} }{routers}{ $row->{router_id} } },
      {
        kbup   => $row->{kbup},
        kbdown => $row->{kbdown},
        users => $row->{users},
        cts    => $dt,
      };
}

# users
$sql = <<'SQL';
SELECT account.account_id, usertrack.mac, usertrack.cts,
usertrack.kbup, usertrack.kbdown, router.router_id
FROM usertrack, account, router
WHERE
router.account_id = account.account_id
AND account.beta = 't'
AND usertrack.router_id = router.router_id
AND  usertrack.cts > '%s'
ORDER BY usertrack.cts DESC
SQL

$sql = sprintf( $sql, DateTime::Format::Pg->format_datetime($yesterday) );

my $users = $dbh->selectall_arrayref( $sql, { Slice => {} } );

warn("processing user raw data") if DEBUG;
foreach my $row (@$users) {

    my $dt = DateTime::Format::Pg->parse_datetime( $row->{cts} );
    $dt->set_time_zone('local');

    # and group by user
    push @{ $refined{ $row->{account_id} }{users}{ $row->{mac} } },
      {
        kbup   => $row->{kbup},
        kbdown => $row->{kbdown},
        router => $row->{router_id},
        cts    => $dt,
      };
}

foreach my $account_id ( keys %refined ) {
    warn("processing account $account_id") if DEBUG;

    # every 15 minutes for 24 hours is 4*24 = 96 - time, kbdown, kbup
    # setup an array to hold the data

    # the dirty data dance
    my $array_ref = Clone::clone( \@Array );
    my @array     = @{$array_ref};

    # aggregate the router data
    my $megabytes_total = 0;
    foreach my $router_id ( keys %{ $refined{$account_id}{routers} } ) {
        warn("processing router $router_id") if DEBUG;

        #        $DB::single = 1;
        my %last_row;

        my @sorted_checkins =
          sort { $a->{cts}->epoch <=> $b->{cts}->epoch }
          @{ $refined{$account_id}{routers}{$router_id} };

        # start with yesterday and work forward
        for ( my $i = 1 ; $i <= $#sorted_checkins ; $i++ ) {

            my $slot_idx;

            # figure out what array slot this belongs in
            for ( my $j = 0 ; $j < $#array ; $j++ ) {

                # see if this row fits in the first time slot
                if (
                    ( ref $array[$j]->[0] && ref $sorted_checkins[$i]->{cts}
		    && ref $array[$j+1]->[0])
                    && ( $sorted_checkins[$i]->{cts}->epoch >=
                        $array[$j]->[0]->epoch )
                    && ( $sorted_checkins[$i]->{cts}->epoch <=
                        $array[ $j + 1 ]->[0]->epoch )
                  )
                {
                    warn("got slot index $j ") if VERBOSE_DEBUG;
                    warn( "down " . $sorted_checkins[$i]->{kbdown} )
                      if VERBOSE_DEBUG;
                    warn( "up " . $sorted_checkins[$i]->{kbup} )
                      if VERBOSE_DEBUG;

                    $slot_idx = $j;
                    last;
                }
            }
            unless ( defined $slot_idx ) {

                $sorted_checkins[$i]->{cts} =
                    $sorted_checkins[$i]->{cts}->day_abbr . " - "
                  . $sorted_checkins[$i]->{cts}->strftime("%H:%M");
            
	    	if (ref $array[0]->[0]) {
		    $array[0]->[0] =
                  $array[0]->[0]->day_abbr . " " . $array[0]->[0]->strftime("%H:%M");
		}
		warn( "checkin range top is " . Dumper( $array[0]->[0] ) )
                  if DEBUG;

	    	if (ref $array[$#array]->[0]) {
                $array[$#array]->[0] =
                  $array[$#array]->[0]->day_abbr . " " . $array[$#array]->[0]->strftime("%H:%M");
		}
		warn( "checkin range bottom is "
                      . Dumper( $array[$#array]->[0] ) )
                  if DEBUG;

                warn( "checkin $i found outside time range: "
                      . Dumper( $sorted_checkins[$i]->{cts} ) )
                  if DEBUG;
                next;

            }

            warn("found a slot $slot_idx") if VERBOSE_DEBUG;

            my $row      = $sorted_checkins[$i];
            my $last_row = $sorted_checkins[ $i - 1 ];

            # get the difference if traffic numbers not reset
            if (    ( $row->{kbup} >= $last_row->{kbup} )
                and ( $row->{kbdown} >= $last_row->{kbdown} ) )
            {

                $array[$slot_idx]->[1] += $row->{kbdown} - $last_row->{kbdown};
                $array[$slot_idx]->[2] += $row->{kbup} - $last_row->{kbup};

		# total megs
        	$megabytes_total += $row->{kbdown} - $last_row->{kbdown};
        	$megabytes_total += $row->{kbup} - $last_row->{kbup};
            }
            else {

                # HACK!  Sometimes nodogsplash isn't accurate, so zero it
                warn "nodoghack - "
                  . $row->{kbdown} / 1024 . " , "
                  . $last_row->{kbdown} / 1024
                  if VERBOSE_DEBUG;
                warn "nodoghack - "
                  . $row->{kbup} / 1024 . " , "
                  . $last_row->{kbup} / 1024
                  if VERBOSE_DEBUG;
                warn "nodoghack - " . $row->{cts}->hms if VERBOSE_DEBUG;

            }

            $array[$slot_idx]->[3] += $row->{users} || 0;
            # bit to indicate a checkin took place for this device
            $array[$slot_idx]->[4] = 1;
        }

    }

    # aggregate the user data
    my %router_users;
    foreach my $mac ( keys %{ $refined{$account_id}{users} } ) {

        warn("=> processing user mac $mac") if DEBUG;

        # loop over the data
        #        $DB::single = 1;
        foreach my $row ( sort { $b->{cts}->epoch <=> $a->{cts}->epoch }
            @{ $refined{$account_id}{users}{$mac} } )
        {

            $router_users{ $row->{router} }{$mac} = 1;
        }

    }

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
    foreach my $line (@array) {
	if (ref $line->[0]) {
	    $line->[0] = $line->[0]->day_abbr . ' ' . $line->[0]->strftime("%H:%M");
	}
    }
    warn( "array is " . Dumper( \@array ) ) if VERBOSE_DEBUG;

    my ($account) =
      SL::Model::App->resultset('Account')
      ->search( { account_id => $account_id } );

    die "missing account for account $account_id" unless $account;

    # users and traffic last 24 hours
    $account->users_today( scalar( keys %{ $refined{$account_id}{users} } ) );
    $account->megabytes_today( int($megabytes_total/1024) );
    $account->update;

    # reverse for the graph
    @array = reverse(@array);

    my $filename =
      join( '/', $account->report_dir_base, "network_overview.csv" );

    my $fh;
    open( $fh, '>', $filename ) or die "could not open $filename: " . $!;
    foreach my $line (@array) {
        $line->[1] = sprintf( "%2.1f", ( $line->[1] * 1000 * 8 / 1024 / 1024 / 300));
        $line->[2] = sprintf( "%2.1f", ( 1 * $line->[2] * 1000 * 8 / 1024 / 1024 / 300));
        print $fh join( ',', @{$line}[ 0 .. 3 ] ) . "\n";
    }
    close $fh or die $!;

    warn("wrote file $filename") if DEBUG;
}

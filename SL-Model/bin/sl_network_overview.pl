#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Pg;
use Data::Dumper;
use SL::Model;
use SL::Model::App;

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;

# grab the checkin data for the last 24 hours and write a csv file

my $yesterday = DateTime->now( time_zone => "local" )->subtract( hours => 24 );

my $dbh = SL::Model->connect;

# devices
my $sql = <<'SQL';
SELECT checkin.kbup, checkin.kbdown,
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
        cts    => $dt,
        #cts    => DateTime::Format::Pg->parse_datetime( $row->{cts} ),
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
        #cts    => DateTime::Format::Pg->parse_datetime( $row->{cts} ),
      };
}

foreach my $account_id ( keys %refined ) {
	warn("processing account $account_id") if DEBUG;

    # every 15 minutes for 24 hours is 4*24 = 96 - time, kbdown, kbup
    # setup an array to hold the data

	warn("building interval array") if DEBUG;
    my @array;
    for ( 1 .. 24 * 12 ) {    # 5 minutes
        push @array,
          [ $now->clone->subtract( minutes => 5 * $_ - 1 ), # cts
            0, # kbdown
            0, # kbup
            0, # users
            0 ]; # checkin bit
    }

    # aggregate the router data
    my $megabytes_total = 0;
    foreach my $router_id ( keys %{ $refined{$account_id}{routers} } ) {
	warn("processing router $router_id") if DEBUG;

        # loop over the data
        #        $DB::single = 1;
        my $router_traffic = 0;
        my ( %last_row, %placeholder );

TIMES:
	foreach my $row ( sort { $a->{cts}->epoch <=> $b->{cts}->epoch }
            @{ $refined{$account_id}{routers}{$router_id} } )
        {

            # handle first row
            unless ( keys %last_row ) {
                %last_row = (
                    kbup   => $row->{kbup},
                    kbdown => $row->{kbdown}
                );
            }

            %placeholder = (
                kbup   => $row->{kbup},
                kbdown => $row->{kbdown}
            );

            # get the difference
            if ( ($row->{kbup} >= $last_row{kbup}) and
                     ($row->{kbdown} >= $last_row{kbdown} ) ) {
                $row->{kbup}   -= $last_row{kbup};
                $row->{kbdown} -= $last_row{kbdown};
            }

            warn(
                sprintf( "kbup %s, kbdown %s", $row->{kbup}, $row->{kbdown} ) )
              if VERBOSE_DEBUG;

            # at this point we're processing  time based data for $router_id.
            # add the totals to to the array in the correct time slot.
            # loop over the output @array until the row fits the slot.
# 	warn("=> interval analysis for $router_id") if DEBUG;
            for ( my $i = 0 ; $i <= $#array ; $i++ ) {

	#	warn("comparing date " . $row->{cts}->time_zone . " " . $row->{cts}->dmy . " " . $row->{cts}->hms . " with " . $array[$i]->[0]->time_zone . " " . $array[$i]->[0]->dmy . " " . $array[$i]->[0]->hms);
	#	warn("comparing date " . $row->{cts}->epoch . " with " . $array[$i]->[0]->epoch);
                # is this timestamp less than the next element?  That's a match
                if ( $row->{cts}->epoch > $array[$i]->[0]->epoch) {
                    
		    # then log it on the current element
                    $array[$i]->[1] += $row->{kbdown};
                    $array[$i]->[2] += $row->{kbup};

                    # bit to indicate a checkin took place for this device
                    $array[$i]->[4] = 1;

                    # total megs
                    $megabytes_total += ($array[$i]->[1]+$array[$i]->[2])/1024;
                    $router_traffic  += ($array[$i]->[1]+$array[$i]->[2])/1024;
            	%last_row = %placeholder;
                    next TIMES;    # last $row
                }

            }

        }

        my ($router) = SL::Model::App->resultset('Router')->search({router_id => $router_id});

        # uptime willis!!
        my $unchecked_count = grep { !$_->[4] } @array;
        my $uptime = 100 * ($#array-$unchecked_count) / $#array;

        if ($unchecked_count == 0) {

          $router->checkin_status("100% Uptime! (last 24 hrs)");

        } else {

          $router->checkin_status(sprintf("%2.2f%% uptime, %d failed checkins",
                                          $uptime, $unchecked_count));
        }

        $router->traffic_daily(int($router_traffic));
        $router->update;

    }

    # aggregate the user data
    my %router_users;
    foreach my $mac ( keys %{ $refined{$account_id}{users} } ) {
		
	warn("=> processing user mac $mac") if DEBUG;

        # loop over the data
        #        $DB::single = 1;
        my ( %last_row, %placeholder );
        foreach my $row ( sort { $b->{cts}->epoch <=> $a->{cts}->epoch }
            @{ $refined{$account_id}{users}{$mac} } )
        {

            $router_users{$row->{router}}{$mac} = 1;

            # at this point we're processing time based data for $router_id.
            # add the totals to to the array in the correct time slot.
            # loop over the output @array until the row fits the slot.
            for ( my $i = 0 ; $i <= $#array ; $i++ ) {

                # is this timestamp less than the next element?  That's a match
                if ( $row->{cts}->epoch > $array[$i]->[0]->epoch) {

                    # then log it on the current element
                    $array[$i]->[3]++;
                    last;    # last $row
                }

            }

        }

    }

    # now update the router totals
    foreach my $router_id ( keys %router_users ) {
      my ($router) = SL::Model::App->resultset('Router')->search({ router_id => $router_id  });

      $router->users_daily(scalar(keys %{$router_users{$router_id}}));
      $router->update;
    }

    # reinitialize the array
    #    $DB::single = 1;
    $_->[0] = $_->[0]->strftime("%l:%M %p") for @array;
    warn( "array is " . Dumper( \@array ) ) if DEBUG;

    my ($account) =
      SL::Model::App->resultset('Account')
      ->search( { account_id => $account_id } );

    die "missing account for account $account_id" unless $account;

    # users and traffic last 24 hours
    $account->users_today(scalar( keys %{ $refined{$account_id}{users} } ) );
    $account->megabytes_today(int($megabytes_total));
    $account->update;

    my $filename =
      join( '/', $account->report_dir_base, "network_overview.csv" );

    my $fh;
    open( $fh, '>', $filename ) or die "could not open $filename: " . $!;
    foreach my $line (@array) {
    	$line->[1] = sprintf("%2.1f", $line->[1]/(300/(1024**2)));
    	$line->[2] = sprintf("%2.1f", ($line->[2]/300/(1024**2)));
        print $fh join( ',', @{$line}[0..3] ) . "\n";
    }
    close $fh or die $!;

    warn("wrote file $filename") if DEBUG;
}

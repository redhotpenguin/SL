#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Pg;
use Data::Dumper;
use SL::Model;
use SL::Model::App;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

# grab the checkin data for the last 24 hours and write a csv file

my $yesterday = DateTime->now( time_zone => "local" )->subtract( hours => 24 );

my $dbh = SL::Model->connect;

my $sql = <<'SQL';
select checkin.kbup, checkin.kbdown,
account.account_id, checkin.cts, router.router_id
from checkin, router, account where checkin.cts > '%s'
and router.account_id = account.account_id and checkin.router_id = router.router_id order by cts desc
SQL

$sql = sprintf( $sql, DateTime::Format::Pg->format_datetime($yesterday) );

my $results = $dbh->selectall_arrayref( $sql, { Slice => {} } );

# group this data by account
my %refined;
my $now = DateTime->now( time_zone => "local" );
foreach my $row (@$results) {

    # and group by router
    push @{ $refined{ $row->{account_id} }{ $row->{router_id} } },
      {
        kbup   => $row->{kbup},
        kbdown => $row->{kbdown},
        cts    => DateTime::Format::Pg->parse_datetime( $row->{cts} ),
      };
}

foreach my $account_id ( keys %refined ) {


    # every 15 minutes for 24 hours is 4*24 = 96 - time, kbdown, kbup
    # setup an array to hold the data

    my @array;
    for (1..24*12) { # 5 minutes
      push @array, [ $now->clone->subtract( minutes => 5 * $_ ), 0, 0 ];
    }

    foreach my $router_id ( keys %{ $refined{$account_id} } ) {

        # loop over the data
#        $DB::single = 1;
        my (%last_row, %placeholder);
        foreach my $row ( sort { $a->{cts}->epoch <=> $b->{cts}->epoch }
                          @{ $refined{$account_id}{$router_id} } )
        {

            # handle first row
            unless (keys %last_row) {
                %last_row = ( kbup => $row->{kbup},
                              kbdown => $row->{kbdown} );
              }

            %placeholder  = ( kbup => $row->{kbup},
                              kbdown => $row->{kbdown} );

            # get the difference
            $row->{kbup}   -= $last_row{kbup};
            $row->{kbdown} -= $last_row{kbdown};
            warn(sprintf("kbup %s, kbdown %s", $row->{kbup}, $row->{kbdown}))
              if DEBUG;

            # at this point we're processing  time based data for $router_id.
            # add the totals to to the array in the correct time slot.
            # loop over the output @array until the row fits the slot.
            for (my $i = 0; $i <= $#array; $i++) {


                # is this timestamp less than the next element?  That's a match
                if ( DateTime->compare( $row->{cts}, $array[ $i + 1 ]->[0] ) >
                    0 )
                {

                    # then log it on the current element
                    $array[$i]->[1] += sprintf("%2.2f", $row->{kbdown}/1024);
                    $array[$i]->[2] += sprintf("%2.2f", $row->{kbup}/1024);
                    last;  # last $row
                }


            }


            %last_row = %placeholder;
          }

    }

    # reinitialize the array
#    $DB::single = 1;
    $_->[0] = $_->[0]->strftime("%l:%M %p") for @array;
    warn("array is " . Dumper(\@array)) if DEBUG;
    my ($account) = SL::Model::App->resultset('Account')->search({
        account_id => $account_id });

    die "missing account for account $account_id" unless $account;

    my $filename =
          join ( '/', $account->report_dir_base, "network_overview.csv" );

    my $fh;
    open($fh, '>', $filename) or die "could not open $filename: " . $!;
    foreach my $line (@array) {
        print $fh join(',',@{$line}) . "\n";
    }
    close $fh or die $!;

    warn("wrote file $filename") if DEBUG;
}

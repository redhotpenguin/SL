#!/home/phred/dev/perl/bin/perl

eval 'exec /home/phred/dev/perl/bin/perl  -S $0 ${1+"$@"}'
  if 0;    # not running under some shell

use strict;
use warnings FATAL => 'all';

use SL::Model::App;
use DateTime;
use DateTime::Format::Pg;
use Mail::Mailer;

our $FULL_LOCATION_DATA = 0;
our $LOCATIONS          = 0;
our $DEBUG              = 0;

my $ADMIN = 'sl_reports@redhotpenguin.com';
my $FROM  = "SL Reporting Daemon <fred\@redhotpenguin.com>";
my @DAYS  = qw( 1 3 7 14 30 );
unless ($DEBUG) {
    push @DAYS, qw( 45 90 135 180 225 270 315 360);
}

my %results = ();

my @locations =
  SL::Model::App->resultset('Location')->search( { active => 't' } );

my ( $prev, $prev_day );
foreach my $day (@DAYS) {
    print STDERR "processing day $day...\n" if $DEBUG;
    $DB::single = 1;
    my $end   = DateTime->now( time_zone    => 'local' );
    my $start = $end->clone->subtract( days => $day );

    my $start_string = DateTime::Format::Pg->format_datetime($start);
    my $end_string   = DateTime::Format::Pg->format_datetime($end);

    my $views_count =
      SL::Model::App->resultset('View')
      ->search( { cts => { -between => [ $start_string, $end_string ] } } )
      ->count;

    my $clicks_count =
      SL::Model::App->resultset('Click')
      ->search( { cts => { -between => [ $start_string, $end_string ] } } )
      ->count;

    $results{$day}{views}  = $views_count;
    $results{$day}{clicks} = $clicks_count;

    if ($prev) {
        $prev->{views_diff} =
          ( $results{$day}{views} == 0 )
          ? 0
          : ( $prev->{views} / $prev_day - $results{$day}{views} / $day ) /
          ( $results{$day}{views} / $day ) * 100;

        $prev->{clicks_diff} =
          ( $results{$day}{clicks} == 0 )
          ? 0
          : ( $prev->{clicks} / $prev_day - $results{$day}{clicks} / $day ) /
          ( $results{$day}{clicks} / $day ) * 100;
    }

    #############################
    # fix me later, this is pretty slow
    if ($LOCATIONS) {
        foreach my $location (@locations) {
            print STDERR "==> processing location " . $location->ip . "\n"
              if $DEBUG;
            my ( $loc_views_count, $views_ary_ref ) =
              $location->views( $start, $end );
            my ( $loc_clicks_count, $clicks_ary_ref ) =
              $location->clicks( $start, $end );

            if (   ( $loc_views_count > 0 )
                or ( $loc_clicks_count > 0 ) )
            {

                # get the routers registered to this location
                my @router__locations = $location->router__locations;
                my $router_names = join ( ' - ',
                    map { $_->router_id->name || $location->ip }
                      @router__locations );

                push @{ $results{$day}{locations} },
                  [ $router_names, $loc_views_count ];

                if ($FULL_LOCATION_DATA) {
                    $results{$day}{data} ||= [];
                    push @{ $results{$day}{data} },
                      {
                        ip     => $location->ip,
                        views  => $loc_views_count,
                        clicks => $loc_clicks_count,
                        rate   => ( $loc_views_count == 0 )
                        ? 0
                        : ( ( $clicks_count / $views_count ) * 100 ),
                      };
                    $results{$day}{views}  += $views_count;
                    $results{$day}{clicks} += $clicks_count;
                }
            }
        }
    }
    ###############################

    $results{$day}{rate} =
      ( $results{$day}{views} == 0 )
      ? 0
      : ( ( $results{$day}{clicks} / $results{$day}{views} ) * 100 );
    $prev     = $results{$day};
    $prev_day = $day;
}

# Generate the email
my $mailer;
unless ($DEBUG) {
    $mailer = Mail::Mailer->new('qmail');
    $mailer->open(
        {
            'To'      => $ADMIN,
            'From'    => $FROM,
            'Subject' => 'SL global daily stats'
        }
    );
}

use Number::Format;
my $de  = Number::Format->new();
my $cnt = <<CNT;
This is the global report of views and clicks
Percent change indicates growth or loss from previous average

0% change means that traffic didn't change relative to the previous entry
+% means traffic levels went up
-% means traffic levels went down.

CNT

my $total = 0;
$cnt .= "------------------------------------------------------\n";
$cnt .= "|  Days  |    Views (% change) |  Clicks      | Rate  |\n";
$cnt .= "------------------------------------------------------\n";

foreach my $day (@DAYS) {
    $cnt .= sprintf(
        "|   %3s  |  %8s (%.1f%%) | %3s (%.1f%%) |  %.2f%%  |\n",
        $day,
        $de->format_number( $results{$day}{views} ),
        $results{$day}{views_diff} || '0',
        $results{$day}{clicks},
        $results{$day}{clicks_diff} || '0',
        $results{$day}{rate},
    );
    $cnt .= "------------------------------------------------------\n";
}

if ($LOCATIONS) {
    $cnt .= "\nBreakdown of most active routers\n\n";
    foreach my $day (@DAYS) {
        $cnt .= "Last $day days\n";
        foreach my $location ( sort { $b->[1] <=> $a->[1] }
            @{ $results{$day}{locations} } )
        {
            $cnt .= sprintf( "  Router %s had %u views\n",
                $location->[0], $location->[1] );
        }
        $cnt .= "\n";
    }
}

$cnt .= "\nHave a nice day :)\n";

print STDERR $cnt if $DEBUG;
print $mailer $cnt unless $DEBUG;
$mailer->close     unless $DEBUG;

#!/home/phred/dev/perl/bin/perl

eval 'exec /home/phred/dev/perl/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use warnings FATAL => 'all';

use SL::Model::App;
use DateTime;
use DateTime::Format::Pg;
use Mail::Mailer;

our $location = 0;
our $DEBUG    = 0;

my $ADMIN = 'sl_reports@redhotpenguin.com';
my $FROM  = "SL Reporting Daemon <fred\@redhotpenguin.com>";
my @DAYS  = qw( 1 3 7 14 30 45 90 135 180 225 270 315 360);

my %results = ();

my @locations =
  SL::Model::App->resultset('Location')->search( { active => 't' } );

my ( $prev, $prev_day );
foreach my $day (@DAYS) {
    print STDERR "processing day $day...\n" if $DEBUG;

    my $end   = DateTime->now;
    my $start = $end->clone->subtract( days => $day );

    $start = DateTime::Format::Pg->format_datetime($start);
    $end   = DateTime::Format::Pg->format_datetime($end);

    my $views_count =
      SL::Model::App->resultset('View')
      ->search( { cts => { -between => [ $start, $end ] } } )->count;

    my $clicks_count =
      SL::Model::App->resultset('Click')
      ->search( { cts => { -between => [ $start, $end ] } } )->count;

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
    if ($location) {
        foreach my $location (@locations) {
            print STDERR "==> processing location " . $location->ip . "\n"
              if $DEBUG;
            my ( $views_count, $views_ary_ref ) =
              $location->views( $start, $end );
            my ( $clicks_count, $clicks_ary_ref ) =
              $location->clicks( $start, $end );

            if (   ( $views_count > 0 )
                or ( $clicks_count > 0 ) )
            {

                $results{$day}{data} ||= [];
                push @{ $results{$day}{data} },
                  {
                    ip     => $location->ip,
                    views  => $views_count,
                    clicks => $clicks_count,
                    rate   => ( $views_count == 0 )
                    ? 0
                    : ( ( $clicks_count / $views_count ) * 100 ),
                  };
                $results{$day}{views}  += $views_count;
                $results{$day}{clicks} += $clicks_count;
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
my $mailer = Mail::Mailer->new('qmail');
$mailer->open(
    {
        'To'      => $ADMIN,
        'From'    => $FROM,
        'Subject' => 'SL global daily stats'
    }
);

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

$cnt .= "\nHave a nice day :)\n";

print STDERR $cnt if $DEBUG;
print $mailer $cnt;
$mailer->close;

#!/home/phred/dev/perl/bin/perl

eval 'exec /home/phred/dev/perl/bin/perl  -S $0 ${1+"$@"}'
  if 0;    # not running under some shell

use strict;
use warnings FATAL => 'all';

use SL::Model::App;
use DateTime;
use DateTime::Format::Pg;
use Mail::Mailer;

our $ROUTERS = 1;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

my $ADMIN = 'sl_reports@redhotpenguin.com';
my $FROM  = "SL Reporting Daemon <support\@silverliningnetworks.com>";
my @DAYS  = qw( 1 3 7 14 30 );

unless (DEBUG) {
    push @DAYS, qw( 45 90 135 180 225 270 315 360);
}

my %results = ();

my @routers = SL::Model::App->resultset('Router')->search()->all;

my ( $prev, $prev_day );
foreach my $day (@DAYS) {
    print STDERR "processing day $day...\n" if DEBUG;

    my $end   = DateTime->now( time_zone    => 'local' );
    my $start = $end->clone->subtract( days => $day );

    my $start_string = DateTime::Format::Pg->format_datetime($start);
    my $end_string   = DateTime::Format::Pg->format_datetime($end);

    my $views_count =
      SL::Model::App->resultset('View')
      ->search( { cts => { -between => [ $start_string, $end_string ] } } )
      ->count;

    $results{$day}{views}  = $views_count;

    if ($prev) {
        $prev->{views_diff} =
          ( $results{$day}{views} == 0 )
          ? 0
          : ( $prev->{views} / $prev_day - $results{$day}{views} / $day ) /
          ( $results{$day}{views} / $day ) * 100;
   }

    # breakdown by routers
    if ($ROUTERS) {
        foreach my $router (@routers) {
            print STDERR sprintf(
                "==> processing router id %d, name '%s', mac %s\n",
                $router->id,
                $router->name    || 'unknown',
                $router->macaddr || 'unknown'
              )
              if DEBUG;

            my ( $router_views_count, $views_ary_ref ) =
              $router->ad_views( $start, $end );

            if (  $router_views_count > 0 )
            {
                push @{ $results{$day}{routers} },
                  [ $router->name || $router->macaddr, $router_views_count ];
            }

            # HACK - update the router count
            if ($day == 1) {
              $router->views_daily($router_views_count);
              $router->update;
            }
        }
    }

    $prev     = $results{$day};
    $prev_day = $day;
}

# Generate the email
my $mailer;
unless (DEBUG) {
    $mailer = Mail::Mailer->new('qmail');
    $mailer->open(
        {
            'To'      => $ADMIN,
            'From'    => $FROM,
            'Subject' => 'SL Global Daily Stats'
        }
    );
}

use Number::Format;
my $de  = Number::Format->new();
my $cnt = <<CNT;
This is the global report of ad insertions
Percent change indicates growth or loss from previous average

0% change means that traffic didn't change relative to the previous entry
+% means traffic levels went up
-% means traffic levels went down.

CNT

my $total = 0;
$cnt .= "------------------------------------\n";
$cnt .= "|  Days  |  Insertions (% change)  |\n";
$cnt .= "------------------------------------\n";

foreach my $day (@DAYS) {
    $cnt .= sprintf(
        "|   %3s  |    %8s (%.1f%%)         |\n",
        $day,
        $de->format_number( $results{$day}{views} ),
        $results{$day}{views_diff} || '0',
    );
    $cnt .= "------------------------------------------------------\n";
}

if ($ROUTERS) {
    $cnt .= "\nBreakdown of most active routers\n\n";
    foreach my $day (@DAYS) {
        $cnt .= "Last $day days\n";
        foreach my $router ( sort { $b->[1] <=> $a->[1] }
            @{ $results{$day}{routers} } )
        {
            $cnt .= sprintf( "  Router %s had %u views\n",
                $router->[0], $router->[1] );
        }
        $cnt .= "\n";
    }
}

$cnt .= "\nHave a nice day :)\n";

print STDERR $cnt if DEBUG;
print $mailer $cnt unless DEBUG;
$mailer->close     unless DEBUG;

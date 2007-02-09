#!perl

use strict;
use warnings;

use lib '../lib';
use DateTime;
use SL::Model::Report;
use Mail::Mailer;

my $ADMIN = 'info@redhotpenguin.com';
my @DAYS  = qw( 1 3 7 14 30 );

# generate the results
my $start = DateTime->now;

my $end = DateTime->now;
my %results;
foreach my $day (@DAYS) {
    my $end = DateTime->now->subtract( days => $day );
    $results{$day}{views}  = SL::Model::Report->views( $end,  $start );
    $results{$day}{clicks} = SL::Model::Report->clicks( $end, $start );
}

# Generate the email
my $mailer = Mail::Mailer->new('qmail');
$mailer->open(
    {
        'To'      => $ADMIN,
        'From'    => "silverlining reporting daemon <fred\@redhotpenguin.com>",
        'Subject' => 'Latest silverlining reporting stats'
    }
);

my $cnt = '';
foreach my $day (@DAYS) {
    my $total = 0;
    $cnt .= "-------------------------------\n";
    $cnt .= "Last $day days worth of ad views by ip\n";
    $cnt .= "       IP        |   Ad Views  \n";
    $cnt .= "-------------------------------\n";
    foreach my $row ( @{ $results{$day}{views} } ) {
        $cnt .= $row->[0] . ' => ' . $row->[1] . "\n";
        $total += $row->[1];
    }
    $cnt .= "-------------------------------\n";
    $cnt .= "Total views for the last $day days: $total\n";
    $cnt .= "-------------------------------\n";
    $cnt .= "-------------------------------\n";

    $total = 0;
    $cnt .= "Last $day days of clicks by link\n";
    $cnt .= "     Link     |    Clicks \n";
    $cnt .= "-------------------------------\n";
    if ( @{ $results{$day}{clicks} } ) {
        foreach my $row ( @{ $results{$day}{clicks} } ) {
            $cnt .= $row->[0] . " => " . $row->[1] . "\n";
            $total += $row->[1];
        }
        $cnt .= "-------------------------------\n";
        $cnt .= "Total clicks for the last $day days: $total\n";
        $cnt .= "-------------------------------\n";
        $cnt .= "-------------------------------\n";
    }
    else {
        $cnt .= "uh oh, no clicks for you monkeys in the last $day days\n";
        $cnt .= "Time to get to work or no banana\n";
        $cnt .= "-------------------------------\n\n";
    }
}

$cnt .= "\nHave a nice day :)\n";
$DB::single = 1;
print $mailer $cnt;
$mailer->close;

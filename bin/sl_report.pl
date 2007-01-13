#!/home/fred/dev/perl/bin/perl

use strict;
use warnings;
use lib '../lib';
use DateTime;
use SL::Model::Report;
use Mail::Mailer;

my $ADMIN = 'info@redhotpenguin.com';
my @DAYS = qw( 1 3 7 14 30 );

# generate the results
my $start = DateTime->now;
my $end = DateTime->now;
my %results;
foreach my $day ( @DAYS ) {
    my $end = DateTime->now->subtract( days => $day );
    $results{$day}{views} = SL::Model::Report->views($end, $start);
    $results{$day}{clicks} = SL::Model::Report->clicks($end, $start);
}

# Generate the email
my $mailer = Mail::Mailer->new('qmail');
$mailer->open({
  'To' => $ADMIN,
  'From' => "silverlining reporting daemon <fred\@redhotpenguin.com>",
  'Subject' => 'Latest silverlining reporting stats' });

foreach my $day (@DAYS) {
	my $total = 0;
print $mailer "-------------------------------\n";
  print $mailer "Last $day days worth of ad views by ip\n";
  print $mailer "       IP        |   Ad Views  \n";
  print $mailer "-------------------------------\n";
    foreach my $row ( @{$results{$day}{views}} ) {
      print $mailer $row->[0] . ' => ' . $row->[1] . "\n";
	$total += $row->[1];
    }
    print $mailer "-------------------------------\n";
    print $mailer "Total views for the last $day days: $total\n";
    print $mailer "-------------------------------\n";
    print $mailer "-------------------------------\n";

    $total=0;
    print $mailer "Last $day days of clicks by link\n";
    print $mailer "     Link     |    Clicks \n";
  print $mailer "-------------------------------\n";
if (@{$results{$day}{clicks}} ) {
foreach my $row ( @{$results{$day}{clicks}} ) {
  print $mailer $row->[0] . " => " . $row->[1] . "\n";
  $total += $row->[1];
}
  print $mailer "-------------------------------\n";
print $mailer "Total clicks for the last $day days: $total\n";
  print $mailer "-------------------------------\n";
  print $mailer "-------------------------------\n";
} else {
print $mailer "uh oh, no clicks for you monkeys in the last $day days\n";
print $mailer "Time to get to work or no banana\n";
  print $mailer "-------------------------------\n\n";
}


}

print $mailer "\nHave a nice day :)\n";
  $mailer->close;

  

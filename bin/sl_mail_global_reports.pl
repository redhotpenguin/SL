use strict;
use warnings;

=head1 NAME

 sl_mail_global_reports.pl

=head1 SYNOPSIS

 perl sl_mail_global_reports.pl --to=recip@rhp.com --interval=daily --interval=weekly --interval=monthly --interval=quarterly

 perl sl_mail_global_reports.pl --help
 
 perl sl_mail_global_reports.pl --man

=cut

use Getopt::Long;
use Pod::Usage;

my (@intervals, $to);
my ($help, $man);

pod2usage(1) unless @ARGV;
GetOptions(
	'to=s' => \$to,
	'interval=s' => \@intervals,
	'help' => \$help,
	'man' => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2) if $man;

use MIME::Lite;

my $FROM    = "SL Reporting Daemon <fred\@redhotpenguin.com>";
my $SUBJECT = "Global SL Report Graphs";
my $dir     = "/tmp/data/sl/global";

my $msg = MIME::Lite->new(
    From    => $FROM,
    To      => $to,
    Subject => $SUBJECT,
    Type    => 'TEXT',
    Data    => "Reports for all routers attached"
);

foreach my $temporal ( @intervals ) {
	foreach my $type qw( views clicks rates ads ) {
		$msg->attach(
			Type     => 'image/png',
			Path     => "$dir/$temporal/$type.png",
			Filename => "$temporal\_$type.png",
		) if (-e "$dir/$temporal/$type.png");
	}
}
$msg->send;


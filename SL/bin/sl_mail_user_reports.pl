use strict;
use warnings;

=head1 NAME

 sl_mail_user_reports.pl

=head1 SYNOPSIS

 perl sl_mail_user_reports.pl --to=specific_user_email --interval=daily --interval=weekly --interval=monthly --interval=quarterly

 perl sl_mail_user_reports.pl --help
 
 perl sl_mail_user_reports.pl --man

=cut

use Getopt::Long;
use Pod::Usage;

my (@intervals, $to);
my ($help, $man);

pod2usage(1) unless @ARGV;
GetOptions(
    'to=s'    => \$to,
    'interval=s' => \@intervals,
    'help' => \$help,
    'man' => \$man,
) or pod2usage(2);

pod2usage(1) unless ($intervals[0]);
pod2usage(1) if $help;
pod2usage( -verbose => 2) if $man;

use MIME::Lite;
use SL::Model::App;

my $FROM    = "SL Reporting Daemon <support\@silverliningnetworks.com>";
my $SUBJECT = "SilverLining Report Graphs";
my @users;

if ($to) {
    @users = SL::Model::App->resultset('Reg')->search({ email => $to });
    unless (@users) {
        print "Sorry we couldn't find $to in our database\n";
        exit(1);
    }
} else {
	my %where;
	foreach my $int (@intervals) {
        $where{"send_reports_$int"} = 1;
	}
    @users = SL::Model::App->resultset('Reg')->search( -or => [ %where ] );
}

foreach my $user (@users) {
    my $msg = MIME::Lite->new(
        From    => $FROM,
        To      => $user->email,
        Subject => $SUBJECT,
        Type    => 'TEXT',
        Data    => "SilverLining Reporting Graphs attached"
    );
	my $dir     = "/tmp/data/sl/" . $user->reg_id . "/" . $user->ip;
    foreach my $temporal ( @intervals ) {
        my $method = "send_reports_$temporal";
        next unless $user->$method;

        foreach my $type qw( views clicks rates ads ) {
            $msg->attach(
                Type     => 'image/png',
                Path     => "$dir/$temporal/$type.png",
                Filename => "$temporal\_$type.png",
            ) if (-e "$dir/$temporal/$type.png");
        }
    }

    $msg->send;
}



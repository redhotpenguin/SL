use strict;
use warnings;

=head1 NAME

 sl_mail_user_reports.pl

=head1 SYNOPSIS

 perl sl_mail_user_reports.pl --to=specific_user_email --interval=daily

 perl sl_mail_user_reports.pl --help

 perl sl_mail_user_reports.pl --man

=cut

use Getopt::Long;
use Pod::Usage;

my ( $interval, $to );
my ( $help,     $man );

pod2usage(1) unless @ARGV;
GetOptions(
    'to=s'       => \$to,
    'interval=s' => \$interval,
    'help'       => \$help,
    'man'        => \$man,
) or pod2usage(2);

pod2usage(1) unless ($interval);
pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

use MIME::Lite;
use SL::Model::App;

my $FROM    = "SL Reporting Daemon <support\@silverliningnetworks.com>";
my $SUBJECT = "Silver Lining Report Graphs";
my @users;

if ($to) {
    @users = SL::Model::App->resultset('Reg')->search( { email => $to } );
    unless (@users) {
        print "Sorry we couldn't find $to in our database\n";
        exit(1);
    }
}
else {
    my %where;
    @users = SL::Model::App->resultset('Reg')->search( { active => 't' } );
}

foreach my $user (@users) {
    my $dir = $user->account_id->report_dir_base;
    opendir( DIR, $dir ) || die "could not open $dir: $!";
    my $has_pngs = () = grep { $_ =~ m/\.png$/ } readdir(DIR);
    closedir(DIR);
    next unless $has_pngs;

    next
      unless ( defined $user->report_email_frequency
        && ( $user->report_email_frequency eq $interval ) );

    my $email = $user->email;

    my $data = <<DATA;
Hi $email,

Please find attached the reporting graphs for your Silver Lining nodes.

To edit your report delivery settings visit the Silver Lining dashboard:

https://app.silverliningnetworks.com/sl/app/home/index
DATA

    my $msg = MIME::Lite->new(
        From    => $FROM,
        To      => $user->email,
        Subject => $SUBJECT,
        Type    => 'TEXT',
        Data    => $data,
    );

    my $attached_something = 0;
    foreach
      my $temporal (qw( daily weekly monthly quarterly biannually annually ))
    {

        foreach my $type qw( views users ) {
            my $filename = "$type\_$temporal.png";
            next unless -e "$dir/$filename";

            $msg->attach(
                Type     => 'image/png',
                Path     => "$dir/$filename",
                Filename => $filename,
            );
            $attached_something = 1;
        }
    }

    next unless $attached_something;    # no reports
    $msg->send;
}


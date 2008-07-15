use strict;
use warnings;

=head1 NAME

 sl_mail_user_reports.pl

=head1 SYNOPSIS

 perl sl_mail_user_reports.pl --to=specific_user_email --interval=daily --interval=weekly --interval=monthly --interval=quarterly --interval biannually --interval annually

 perl sl_mail_user_reports.pl --help

 perl sl_mail_user_reports.pl --man

=cut

use Getopt::Long;
use Pod::Usage;

my ( @intervals, $to );
my ( $help,      $man );

pod2usage(1) unless @ARGV;
GetOptions(
    'to=s'       => \$to,
    'interval=s' => \@intervals,
    'help'       => \$help,
    'man'        => \$man,
) or pod2usage(2);

pod2usage(1) unless ( $intervals[0] );
pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

use MIME::Lite;
use SL::Model::App;

my $FROM    = "SL Reporting Daemon <support\@silverliningnetworks.com>";
my $SUBJECT = "SilverLining Report Graphs";
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

    my $email = $user->email;

    my $data = <<DATA;
Hi $email,

Attached are the reporting graphs for your Silver Lining routers.

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
    foreach my $temporal (@intervals) {

        foreach my $type qw( views ) {    # clicks rates ads ) {
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


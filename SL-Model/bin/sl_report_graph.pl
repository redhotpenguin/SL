#!perl

use strict;
use warnings FATAL => 'all';

=head1 NAME

 sl_report_graph.pl

=head1 SYNOPSIS

 perl sl_report_graph.pl --interval=daily --interval=weekly --interval=monthly
	--interval=quarterly --interval biannually --interval annually

 perl sl_report_graph.pl --help

 perl sl_report_graph.pl --man

=cut

use Getopt::Long;
use Pod::Usage;

my @intervals;
my ( $help, $man );

pod2usage(1) unless @ARGV;
GetOptions(
    'interval=s' => \@intervals,
    'help'       => \$help,
    'man'        => \$man,
  )
  or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

die "Bad interval"
  unless
  grep { $_ =~ m/(?:daily|weekly|monthly|quarterly|annually|biannually)/ }
  @intervals;

use DateTime;

use SL::Model::Report;
use SL::Model::Report::Graph;
use SL::Model::App;

our %duration_hash = (

    daily      => '24 hours',
    weekly     => '7 days',
    monthly    => '30 days',
    quarterly  => '90 days',
    biannually => '180 days',
    annually   => '365 days',
);

use constant DEBUG => $ENV{SL_DEBUG} || 0;

my @accounts = SL::Model::App->resultset('Account')->all;

foreach my $temporal (@intervals) {

    print "Processing temporal $temporal\n" if DEBUG;

    foreach my $account ( @accounts ) {
        print sprintf( "=> Processing account %s \n", $account->name ) if DEBUG;

        my @routers = SL::Model::App->resultset('Router')->search({
		account_id => $account->account_id, active => 't' });

        unless (@routers) {
          print STDERR "no routers for account " . $account->name . "\n";
          next;
        }
        
        ######################
        # get the view data
        my $views = SL::Model::Report->views(
            {
                account  => $account,
                temporal => $temporal,
                routers  => \@routers
            }
        );

        # burn the view graph
        my $filename =
          join ( '/', $account->report_dir_base, "views_$temporal.png" );

          SL::Model::Report::Graph->views(
            {
                data_hashref => $views,
                filename     => $filename,
                account      => $account,
                temporal     => $temporal,
            }
        );
        print "==> burned graph $filename\n" if DEBUG;

        ######################
        # get the users data
        my $users = SL::Model::Report->users(
            {
                account  => $account,
                temporal => $temporal,
                routers  => \@routers
            }
        );

        # burn the users graph
        $filename =
          join ( '/', $account->report_dir_base, "users_$temporal.png" );

        SL::Model::Report::Graph->users(
            {
                data_hashref => $users,
                filename     => $filename,
                account      => $account,
                temporal     => $temporal,
            }
        );
        print "==> burned graph $filename\n" if DEBUG;

    }

    print "\nFinished processing $temporal reports\n" if DEBUG;
}

1;

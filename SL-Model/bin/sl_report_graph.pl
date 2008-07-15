use strict;
use warnings FATAL => 'all';

=head1 NAME

 sl_report_graph.pl

=head1 SYNOPSIS

 perl sl_report_graph.pl --interval=daily --interval=weekly --interval=monthly
	--interval=quarterly

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

my @regs = SL::Model::App->resultset('Reg')->search( { active => 1, });
# email => 'fred@redhotpenguin.com' } );

foreach my $temporal (@intervals) {
    my %global;
    my %reg_data;
    print STDERR "Processing temporal $temporal\n";

    foreach my $reg (@regs) {
        print STDERR sprintf( "=> Processing account %s \n", $reg->email )
          if DEBUG;

        my @routers = $reg->get_routers;
        unless (@routers) {
          print STDERR "no routers for " . $reg->email . "\n" if DEBUG;
          next;
        }

        ######################
        # get the view data
        my $views = SL::Model::Report->views(
            {
                reg      => $reg,
                temporal => $temporal,
                routers  => \@routers
            }
        );

        # burn the view graph
        my $filename =
          join ( '/', $reg->report_dir_base, "views_$temporal.png" );
        SL::Model::Report::Graph->views(
            {
                data_hashref => $views,
                filename     => $filename,
                reg          => $reg,
                temporal     => $temporal,
            }
        );
        print STDERR "==> burned graph $filename\n" if DEBUG;

        if (0) {
        ########################
        # get the click data
        my $clicks = SL::Model::Report->clicks(
            {
                reg      => $reg,
                temporal => $temporal,
                routers  => \@routers,
            }
        );

        # burn the click graph
        $filename = join ( '/', $reg->report_dir_base, "clicks_$temporal.png" );
        SL::Model::Report::Graph->clicks(
            {
                data_hashref => $clicks,
                filename     => $filename,
                reg          => $reg,
                temporal     => $temporal,
            }
        );
        print STDERR "==> burned graph $filename\n" if DEBUG;

        #########################
        # get ad breakdown for all routers
        my $ads_by_click = SL::Model::Report->ads_by_click(
            {
                reg       => $reg,
                temporal  => $temporal,
                routers => \@routers,
            }
        );

        # burn the click by ad graph
        $filename = join ( '/', $reg->report_dir_base, "ads_$temporal.png" );
        SL::Model::Report::Graph->ads_by_click(
            {
                data_hashref => $ads_by_click,
                filename     => $filename,
                reg          => $reg,
                temporal     => $temporal,
            }
        );
        print STDERR "==> burned graph $filename\n" if DEBUG;

        #########################
        # click rates
        my $click_rates = SL::Model::Report->click_rates(
            {
                reg       => $reg,
                temporal  => $temporal,
                routers => \@routers,
            }
        );
        print STDERR "==> got ad data for " . $reg->email . "\n" if DEBUG;

        # burn the click by ad graph
        $filename = join ( '/', $reg->report_dir_base, "rates_$temporal.png" );
        SL::Model::Report::Graph->click_rates(
            {
                data_hashref => $click_rates,
                filename     => $filename,
                reg          => $reg,
                temporal     => $temporal,
            }
        );
        print STDERR "==> burned graph $filename\n" if DEBUG;
      }
    }

    print STDERR "\nFinished processing $temporal reports\n" if DEBUG;
}

1;

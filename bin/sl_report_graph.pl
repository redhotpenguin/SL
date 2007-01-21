use strict;
use warnings;

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
my ($help, $man);

pod2usage(1) unless @ARGV;
GetOptions(
	'interval=s' => \@intervals,
	'help' => \$help,
	'man' => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2) if $man;

die "Bad interval" unless grep { $_ =~ m/(?:daily|weekly|monthly|quarterly)/ }
	@intervals;

use DateTime;
use SL::Model::Report;
use SL::Model::Report::Graph;
use SL::Model::App;

my @accounts = SL::Model::App->resultset('Reg')->search( { active => 1 } );

use SL::Config;
my $config = SL::Config->new();

my $DATA_ROOT = $config->data_root;

my %duration_hash = (
    daily     => '24 hours',
    weekly    => '7 days',
    monthly   => '30 days',
    quarterly => '90 days',
);

foreach my $temporal ( @intervals ) {
    my %global;
    my %account_info;
    print STDERR "Processing temporal $temporal\n";
    foreach my $account (@accounts) {
        print STDERR "Processing account " . $account->email . "\n";

        my $account_id = $account->reg_id;
        my $ip         = $account->ip;
        $account_info{$ip} = $account->email;

        my $dir = "$DATA_ROOT/$account_id/$ip/$temporal";

        unless ( -d $dir ) {
            ( system("mkdir -p $dir") == 0 ) or die $!;
        }
        
		# Grab the last 24 hours of data for this ip
        my (
            $max_view_results,  $view_results_ref, $max_click_results,
            $click_results_ref, $max_click_rate,   $click_rate_ref
        ) = SL::Model::Report->data_for_ip( $ip, $temporal );
        $DB::single = 1;
		## Build the graph of views for the last 24 hours
        my $filename = "$dir/views.png";
        my $ok       = eval {
            SL::Model::Report::Graph->bars(
                {
                    filename => $filename,
                    title    => "Ad Views "
                      . $duration_hash{$temporal} . " - "
                      . DateTime->now( time_zone => "local" )
                      ->strftime("%a %b %e,%l:%m %p"),
                    y_label       => 'Number of Views',
                    y_max_value   => $max_view_results,
                    y_tick_number => 10,
                    data_ref      => $view_results_ref,
                    colors_ref    => [qw(lblue)],
                }
            );
        };
        die $@ if $@;

        # Build the graph for the number of clicks
        $filename = "$dir/clicks.png";
        $ok       = eval {
            SL::Model::Report::Graph->bars(
                {
                    filename => $filename,
                    title    => "Ad Clicks "
                      . $duration_hash{$temporal} . " - "
                      . DateTime->now( time_zone => "local" )
                      ->strftime("%a %b %e,%l:%m %p"),
                    y_max_value   => $max_click_results,
                    y_label       => 'Number of Clicks',
                    y_tick_number => $max_click_results,
                    data_ref      => $click_results_ref,
                    colors_ref    => [qw(lblue)],
                }
            );
        };
        die $@ if $@;

        # Build the graph for the click rates
        $filename = "$dir/rates.png";
        $ok       = eval {
            SL::Model::Report::Graph->bars(
                {
                    title => "Click Rate "
                      . $duration_hash{$temporal} . " - "
                      . DateTime->now( time_zone => "local" )
                      ->strftime("%a %b %e,%l:%m %p"),
                    filename        => $filename,
                    y_max_value     => $max_click_rate,
                    y_label         => 'Click Rate',
                    x_label         => 'Date Interval',
                    y_tick_number   => $max_click_rate,
                    y_number_format => '%.1f%%',
                    data_ref        => $click_rate_ref,
                    colors_ref      => [qw(lblue)],
                }
            );
        };
        die $@ if $@;

        # Build the graph for the ads clicked summary
        ## Click aggregation for time period
        # somead => 1 click
        # other_ad => 2 clicks
        my $now        = DateTime->now->truncate( to => 'hour' );
        my $start_date = $now->clone->subtract( days => 1 );
        my ( $max_ad_clicks, $ad_clicks_data_ref ) =
          SL::Model::Report->ad_clicks_summary( $ip, $start_date, $now );
        $max_ad_clicks           ||= 1;
        $ad_clicks_data_ref->[0] ||= [0];
        $ad_clicks_data_ref->[1] ||= [0];
        $filename = "$dir/ads.png";

        $ok = eval {
            SL::Model::Report::Graph->hbars(
                {
                    title => "Ads Clicked "
                      . $duration_hash{$temporal} . " - "
                      . DateTime->now( time_zone => "local" )
                      ->strftime("%a %b %e,%l:%m %p"),
                    filename      => $filename,
                    y_max_value   => $max_ad_clicks,
                    y_label       => 'Clicks 24 Hours',
                    y_tick_number => $max_ad_clicks,
                    data_ref      => $ad_clicks_data_ref,
                }
            );
        };
        die $@ if $@;

        # stash the data for the big graph
		# if there is data to stash...  grep over each element to see that it's
		# defined and not zero
        if ( grep { (defined $view_results_ref->[1]->[$_])
				&& ($view_results_ref->[1]->[$_] != 0 ) }
            0 .. scalar( @{$view_results_ref->[1]} ) )
        {
            $global{$account_id}{$ip}{views}{max}   = $max_view_results;
            $global{$account_id}{$ip}{views}{data}  = $view_results_ref;
            $global{$account_id}{$ip}{clicks}{max}  = $max_click_results;
            $global{$account_id}{$ip}{clicks}{data} = $click_results_ref;
            $global{$account_id}{$ip}{rates}{max}   = $max_click_rate;
            $global{$account_id}{$ip}{rates}{data}  = $click_rate_ref;
            $global{$account_id}{$ip}{ads}{max}     = $max_ad_clicks;
            $global{$account_id}{$ip}{ads}{data}    = $ad_clicks_data_ref;
        }
    }

    # Now build the overall usage stats for the root user
    my $dir = "$DATA_ROOT/global/$temporal";

    unless ( -d $dir ) {
        ( system("mkdir -p $dir") == 0 ) or die $!;
    }

    ## Build the globals for the last 24 hours
    ##
    my ( $max_views, $max_clicks, $max_rates, $max_ads ) = 0;
    my ( $view_data_ref, $click_data_ref, $rate_data_ref, $ad_data_ref );
    my $headers = 0;
    my @series;
    foreach my $account_id ( keys %global ) {
        foreach my $ip ( keys %{ $global{$account_id} } ) {
            ### first compute the maximum value
            $max_views  += $global{$account_id}{$ip}{views}{max};
            $max_clicks += $global{$account_id}{$ip}{clicks}{max};
            $max_rates  += $global{$account_id}{$ip}{rates}{max};
            $max_ads    += $global{$account_id}{$ip}{ads}{max};

            ### add the headers
            unless ($headers) {
                push @{$view_data_ref},
                  @{ $global{$account_id}{$ip}{views}{data} }[0];
                push @{$click_data_ref},
                  @{ $global{$account_id}{$ip}{clicks}{data} }[0];
                push @{$rate_data_ref},
                  @{ $global{$account_id}{$ip}{rates}{data} }[0];
                $headers++;
            }

            ### add the data for views. rates, and clicks
            push @{$view_data_ref},
              @{ $global{$account_id}{$ip}{views}{data} }[1];
            push @{$click_data_ref},
              @{ $global{$account_id}{$ip}{clicks}{data} }[1];
            push @{$rate_data_ref},
              @{ $global{$account_id}{$ip}{rates}{data} }[1];

            push @{ $ad_data_ref->[0] },
              @{ $global{$account_id}{$ip}{ads}{data} }[0];
            push @{ $ad_data_ref->[1] },
              @{ $global{$account_id}{$ip}{ads}{data} }[1];

            push @series, join( '', $account_info{$ip}, ' - ', $ip );
        }
    }

   $DB::single = 1;
    my $filename = "$dir/views.png";
    my $ok       = eval {
        SL::Model::Report::Graph->bars_many(
            {
                filename => $filename,
                title    => "Global Ad Views "
                  . $duration_hash{$temporal} . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value   => $max_views,
                y_tick_number => 10,
                y_label       => 'Number of ad views',
                data_ref      => $view_data_ref,
                legend        => \@series,
            }
        );
    };
    die $@ if $@;

    $filename = "$dir/clicks.png";
    $ok       = eval {
        SL::Model::Report::Graph->bars_many(
            {
                filename => $filename,
                title    => "Global Ad Clicks "
                  . $duration_hash{$temporal} . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value   => $max_clicks,
                y_tick_number => $max_clicks,
                y_label       => 'Number of ad clicks',
                data_ref      => $click_data_ref,
                legend        => \@series,
            }
        );
    };
    die $@ if $@;

    $filename = "$dir/rates.png";
    $ok       = eval {
        SL::Model::Report::Graph->bars_many(
            {
                filename => $filename,
                title    => "Global Click Rate "
                  . $duration_hash{$temporal} . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value     => $max_clicks,
                y_tick_number   => $max_clicks,
                data_ref        => $click_data_ref,
                legend          => \@series,
                y_number_format => '%.1f%%',
                y_label         => 'Click Rate',
                cumulate        => 0,
            }
        );
    };
    die $@ if $@;

#    $DB::single = 1;

    # [ 'ad_one', 'ad_two' ]
    # [ 'account_one_clicks_for_ad_one', 'account_one_clicks_for_ad_two' ]
    # munge the ad_data_ref into a friendly structure
    # if there was only a friendlier way to do this...
    my @ads_seen;
    push @ads_seen, @{$_} for @{ $ad_data_ref->[0] };
    my @graph_array;
    push @graph_array, \@ads_seen;

    # use this hash to make dealing with the array easier
    my $i = 0;
    my %ads_seen_hash = map { $_ => $i++ } @ads_seen;
    foreach my $account (@accounts) {
        foreach my $ip ( keys %{ $global{ $account->reg_id } } ) {

            # this tracks the actual click numbers for the ad for the ip
            # initialize each element of the array to 0
            my @ad_clicks = map { 0 } 0 .. $#ads_seen;

            # Cycle through the ad clicks recorded for this ip
            for (
                my $i = 0 ;
                $i < @{ $global{ $account->reg_id }{$ip}{ads}{data}[0] } ;
                $i++
              )
            {

                # grab the index
                my $ad = $global{ $account->reg_id }{$ip}{ads}{data}[0]->[$i];
                my $ad_seen_index = $ads_seen_hash{$ad};

                # Update the ad_click value
                $ad_clicks[$ad_seen_index] =
                  $global{ $account->reg_id }{$ip}{ads}{data}[1]->[$i];

            }

            # whew! almost there (for this ip!)
            push @graph_array, \@ad_clicks;
        }
    }

    $filename = "$dir/ads.png";
    $ok       = eval {
        SL::Model::Report::Graph->hbars_many(
            {
                filename => $filename,
                title    => "Global Ads Clicked "
                  . $duration_hash{$temporal} . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value   => $max_ads,
                y_tick_number => $max_ads,
                y_label       => 'Number of clicks',
                data_ref      => \@graph_array,
                legend        => \@series,
            }
        );
    };
    die $@ if $@;

}

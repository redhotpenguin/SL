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
use File::Path qw(mkpath);

use SL::Model::Report;
use SL::Model::Report::Graph;
use SL::Model::App;

my @regs = SL::Model::App->resultset('Reg')->search( { active => 1 } );

use SL::Config;
my $config = SL::Config->new();

my $DATA_ROOT = $config->sl_data_root;

my %duration_hash = (
    daily     => '24 hours',
    weekly    => '7 days',
    monthly   => '30 days',
    quarterly => '90 days',
);

foreach my $temporal ( @intervals ) {
    my %global;
    my %reg_data;
    print STDERR "Processing temporal $temporal\n";
    foreach my $reg (@regs) {
        print STDERR "\n=> Processing account " . $reg->email . "\n";

        # make the directory to store the reporting data
        my $dir = "$DATA_ROOT/" . $reg->reg_id . "/$temporal";
        mkpath($dir) unless ( -d $dir );
       
        # grab all the routers for this registration
        my @routers = SL::Model::App->resultset('Router')->search({
             reg_id => $reg->reg_id });

        unless (@routers) {
          print STDERR "Account " . $reg->email . " has no registered routers\n";
          next;
        }

        my $now        = DateTime->now->truncate( to => 'hour' );
        my @temporal_args = reverse(split(/\s/, $duration_hash{$temporal}));
        my $start      = $now->clone;
        $start->subtract(@temporal_args);

        # compute the reporting data for that router
        foreach my $router (@routers) {
            print STDERR "==> Building graphs for " . $reg->email 
              . ", router ip " . $router->ip . "\n";
            my $router_dir = "$dir/" . $router->ip;
            mkpath($router_dir) unless ( -d $router_dir );

            #################################
            # views clicks and rates
            my $views_clicks_rates_hashref =
              SL::Model::Report->data_for_ip( $router->ip, $temporal );
            $reg_data{$reg->reg_id}{$router->ip}{views_clicks_rates} =
              $views_clicks_rates_hashref;


            SL::Model::Report::Graph->single_router_views({
               dir => $router_dir,
               data => $views_clicks_rates_hashref->{views_data},
               max  => $views_clicks_rates_hashref->{max_views},
               temporal => $temporal,
           });

            SL::Model::Report::Graph->single_router_clicks({
               dir => $router_dir,
               data => $views_clicks_rates_hashref->{clicks_data},
               max  => $views_clicks_rates_hashref->{max_clicks},
               temporal => $temporal,
            });

            SL::Model::Report::Graph->single_router_rates({
               dir => $router_dir,
               data => $views_clicks_rates_hashref->{rates_data},
               max  => $views_clicks_rates_hashref->{max_rates},
               temporal => $temporal,
            });

            ################################
            # ad clicks summary data
            my $ad_summary_hashref =
              SL::Model::Report->ad_summary( $router->ip, $start, $now );
            $reg_data{ $reg->reg_id }{ $router->ip }{ads} = $ad_summary_hashref;

            SL::Model::Report::Graph->single_router_ad_summary(
                {
                    dir      => $router_dir,
                    data     => $ad_summary_hashref->{data},
                    max      => $ad_summary_hashref->{max},
                    temporal => $temporal,
                }
            );


            # stash the data for the big graph
            # if there is data to stash...  grep over each element to see that it's
            # defined and not zero
            my $v_c_r_ref = $views_clicks_rates_hashref;
            if ( grep { ( defined $v_c_r_ref->{views_data}->[1]->[$_] ) 
                          && ( $v_c_r_ref->{views_data}->[1]->[$_] != 0 ) }
                 0 .. scalar( @{$v_c_r_ref->{views_data}->[1]} ) )
#            if ( grep { (defined $view_results_ref->[1]->[$_])
 #                         && ($view_results_ref->[1]->[$_] != 0 ) }
#                 0 .. scalar( @{$view_results_ref->[1]} ) )
              {
#                $global{$reg->reg_id}{$router->ip}{views}{max}   = $max_view_results;
                $global{$reg->reg_id}{$router->ip}{views}{max}   = $v_c_r_ref->{max_views};
#                $global{$reg->reg_id}{$router->ip}{views}{data}  = $view_results_ref;
                $global{$reg->reg_id}{$router->ip}{views}{data}  = $v_c_r_ref->{views_data};
#                $global{$reg->reg_id}{$router->ip}{clicks}{max}  = $max_click_results;
                $global{$reg->reg_id}{$router->ip}{clicks}{max}  = $v_c_r_ref->{max_clicks};
#                $global{$reg->reg_id}{$router->ip}{clicks}{data} = $click_results_ref;
                $global{$reg->reg_id}{$router->ip}{clicks}{data} = $v_c_r_ref->{clicks_data};
#                $global{$reg->reg_id}{$router->ip}{rates}{max}   = $max_click_rate;
                $global{$reg->reg_id}{$router->ip}{rates}{max}   = $v_c_r_ref->{max_rates};
#                $global{$reg->reg_id}{$router->ip}{rates}{data}  = $click_rate_ref;
                $global{$reg->reg_id}{$router->ip}{rates}{data}  = $v_c_r_ref->{rates_data};
#                $global{$reg->reg_id}{$router->ip}{ads}{max}     = $max_ad_clicks;
                $global{$reg->reg_id}{$router->ip}{ads}{max}     = $ad_summary_hashref->{max};
#                $global{$reg->reg_id}{$router->ip}{ads}{data}    = $ad_clicks_data_ref;
                $global{$reg->reg_id}{$router->ip}{ads}{data}    = $ad_summary_hashref->{data};
              }

          }

        ##########################################
        # build the composite graph for this reg
        print STDERR "==> Building composite report for " . $reg->email . "\n";

        SL::Model::Report::Graph->composite_account_views({
               dir => $dir,
               reg => $reg,
               data_hashref => $reg_data{$reg->reg_id},
               temporal => $temporal,
       });

        SL::Model::Report::Graph->composite_account_clicks({
               dir => $dir,
               reg => $reg,
               data_hashref => $reg_data{$reg->reg_id},
               temporal => $temporal,
       });

        SL::Model::Report::Graph->composite_account_rates({
               dir => $dir,
               reg => $reg,
               data_hashref => $reg_data{$reg->reg_id},
               temporal => $temporal,
       });

        SL::Model::Report::Graph->composite_account_ads({
               dir => $dir,
               reg => $reg,
               data_hashref => $reg_data{$reg->reg_id},
               temporal => $temporal,
        });

    }

    # Now build the overall usage stats for the root user
    my $dir = "$DATA_ROOT/global/$temporal";
    mkpath($dir) unless ( -d $dir );

    ## Build the globals
    print STDERR "\n=> Building $temporal global reports\n";
    my ( $max_views, $max_clicks, $max_rates, $max_ads ) = 0;
    my ( $view_data_ref, $click_data_ref, $rate_data_ref, $ad_data_ref );
    my $headers = 0;
    my @series;
    print STDERR "==> Summarizing the data\n";
    foreach my $account_id ( keys %global ) {
#      $DB::single = 1;
        foreach my $ip ( keys %{ $global{$account_id} } ) {
            ### first compute the maximum value
            $max_views  += $global{$account_id}{$ip}{views}{max};
            $max_clicks += $global{$account_id}{$ip}{clicks}{max};
            $max_rates  += $global{$account_id}{$ip}{rates}{max};
         #   $DB::single = 1;
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

            my ($reg) = SL::Model::App->resultset('Reg')->search({ reg_id => $account_id });
            push @series, join( '', $reg->email, ' - ', $ip );
        }
    }
    print STDERR "==> Burning the graphs\n";

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

    print STDERR "==> Doing funny stuff to compute most seen ads\n";
    # use this hash to make dealing with the array easier
    my $i = 0;
    my %ads_seen_hash = map { $_ => $i++ } @ads_seen;
    foreach my $account (@regs) {
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

    print STDERR "\nFinished processing $temporal reports\n";
}

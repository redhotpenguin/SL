#!/home/fred/dev/perl/bin/perl

use strict;
use warnings;
use lib '../lib';
use DateTime;
use SL::Model::Report;
use SL::Model::Report::Graph;

use SL::Model::App;

my @accounts = SL::Model::App->resultset('Reg')->search( { active => 1 } );

my $DATA_ROOT = "/tmp/data/sl";
my $duration  = "24 hours";

my %global;
my %account_info;

foreach my $account (@accounts) {

    my $account_id = $account->reg_id;
    my $ip         = $account->ip;
    $account_info{$ip} = $account->email;
    my $dir = "$DATA_ROOT/$account_id/$ip/daily";
    unless ( -d $dir ) {
        ( system("mkdir -p $dir") == 0 ) or die $!;
    }

    # Grab the last 24 hours of data for this ip
    my (
        $max_view_results,  $view_results_ref, $max_click_results,
        $click_results_ref, $max_click_rate,   $click_rate_ref
    ) = SL::Model::Report->data_daily_ip($ip);

    ## Build the graph of views for the last 24 hours
    my $filename = "$dir/views.png";
    my $ok       = eval {
        SL::Model::Report::Graph->bars(
            {
                filename      => $filename,
                title         => "Ad Views in Last $duration",
                y_max_value   => $max_view_results * 1.1,
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
                filename      => $filename,
                title         => "Ad Clicks in Last $duration",
                y_max_value   => $max_click_results * 1.1,
                y_label       => 'Number of Clicks',
                y_tick_number => $max_click_results * 1.1,
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
                title           => "Click Rate Last $duration",
                filename        => $filename,
                y_max_value     => $max_click_rate * 1.1,
                y_label         => 'Number of Clicks',
                y_tick_number   => 3,
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
    $ok       = eval {
        SL::Model::Report::Graph->hbars(
            {
                title         => "Ads Clicked in Last $duration",
                filename      => $filename,
                y_max_value   => $max_ad_clicks * 1.1,
                y_label       => 'Clicks in Last 24 Hours',
                y_tick_number => $max_ad_clicks * 1.1,
                data_ref      => $ad_clicks_data_ref,

            }
        );
    };
    die $@ if $@;

    # stash the data for the big graph;
    if ( grep { $view_results_ref->[1]->[$_] != 0 }
        0 .. scalar( @{$view_results_ref} ) )
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
my $dir = "$DATA_ROOT/global/daily";
unless ( -d $dir ) {
    ( system("mkdir -p $dir") == 0 ) or die $!;
}

## Build the graph of views for the last 24 hours
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
            push @{$ad_data_ref}, @{ $global{$account_id}{$ip}{ads}{data} }[0];
            $headers++;
        }

        ### add the data
        push @{$view_data_ref}, @{ $global{$account_id}{$ip}{views}{data} }[1];
        push @{$click_data_ref},
          @{ $global{$account_id}{$ip}{clicks}{data} }[1];
        push @{$rate_data_ref}, @{ $global{$account_id}{$ip}{rates}{data} }[1];
        push @{$ad_data_ref},   @{ $global{$account_id}{$ip}{ads}{data} }[1];
        push @series, join( '', $account_info{$ip}, ' - ', $ip );
    }
}

my $filename = "$dir/views.png";
my $ok       = eval {
    SL::Model::Report::Graph->bars_many(
        {
            filename      => $filename,
            title         => "Global Ad Views in Last $duration",
            y_max_value   => $max_views * 1.1,
            y_tick_number => 10,
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
            filename      => $filename,
            title         => "Global Ad Clicks in Last $duration",
            y_max_value   => $max_clicks * 1.1,
            y_tick_number => $max_clicks * 1.1,
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
            filename        => $filename,
            title           => "Global Ad Clicks in Last $duration",
            y_max_value     => $max_clicks * 1.1,
            y_tick_number   => 3,
            data_ref        => $click_data_ref,
            legend          => \@series,
            y_number_format => '%.1f%%',
            y_label         => 'Number of Clicks',
        }
    );
};
die $@ if $@;

$filename = "$dir/ads.png";
$ok       = eval {
    SL::Model::Report::Graph->hbars_many(
        {
            filename      => $filename,
            title         => "Global Ads Clicked in Last $duration",
            y_max_value   => $max_ads * 1.1,
            y_label       => 'Global Clicks in Last 24 Hours',
            data_ref      => $ad_data_ref,
            legend        => \@series,
        }
    );
};
die $@ if $@;



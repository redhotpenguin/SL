#!/home/fred/dev/perl/bin/perl

use strict;
use warnings;
use lib '../lib';
use DateTime;
use SL::Model::Report;
use Mail::Mailer;

my $ADMIN = 'fred@redhotpenguin.com';

#my $ADMIN = 'info@redhotpenguin.com';
my $DATA_ROOT = "/tmp/data/sl";

my %accounts = ( 1 => [qw(70.239.239.57)], );

foreach my $account_id ( sort keys %accounts ) {
    foreach my $ip ( $accounts{$account_id} ) {

        # Grab the last 24 hours of data for this ip
        my (
            $max_view_results,  $view_results_ref, $max_click_results,
            $click_results_ref, $max_click_rate,   $click_rate_ref
          )
          = SL::Model::Report->data_daily_ip($ip);

        ## Build the graph of views for the last 24 hours
        my $duration = "24 hours";
        my $filename = "$DATA_ROOT/$account_id/$ip/views_daily.png";
        $title = "Ad Views in Last $duration";
        my $ok = eval {
            SL::Model::Report::Graph->bars(
                {
                    filename      => $filename,
                    title         => $title,
                    y_max_value   => $max_view_results * 1.1,
                    y_tick_number => 10,
                    data_ref      => $view_results_ref,
                    colors_ref    => [qw(lblue)],
                }
            );
        };
        die $@ if $@;

        # Build the graph for the number of clicks
        $filename = "$DATA_ROOT/$account_id/$ip/clicks_daily.png";
        my $title = "Ad Clicks in Last $duration";
        my $ok = eval {
            SL::Model::Report::Graph->bars(
                {
                    filename      => $filename,
                    title         => $title,
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
        $filename = "$DATA_ROOT/$account_id/$ip/rates_daily.png";
        my $ok = eval {
            SL::Model::Report::Graph->bars(
                {
                    title           => "Click Rate Last $duration",
                    filename        => $filename,
                    title           => $title,
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

        $filename = "$DATA_ROOT/$account_id/$ip/ads_daily.png";
        my $ok = eval {
            SL::Model::Report::Graph->bars(
                {
                    title         => "Ads Clicked in Last $duration",
                    filename      => $filename,
                    title         => $title,
                    y_max_value   => $max_ad_clicks * 1.1,
                    y_label       => 'Clicks in Last 24 Hours',
                    y_tick_number => $max_ad_clicks * 1.1,

                }
            );
        };
        die $@ if $@;

    }

}


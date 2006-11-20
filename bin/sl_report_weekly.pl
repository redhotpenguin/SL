#!/home/fred/dev/perl/bin/perl

use strict;
use warnings;
use lib '../lib';
use DateTime;
use SL::Model::Report;
use Mail::Mailer;
use GD::Graph;
use GD::Graph::bars;
use GD::Graph::hbars;

my $ADMIN = 'fred@redhotpenguin.com';

#my $ADMIN = 'info@redhotpenguin.com';
my $ip = '70.239.239.57';

# build the clicks and views reports
my $now = DateTime->now( time_zone => 'local' );
$now->truncate( to => 'hour' );
my ( @view_results, @click_results, @click_rates );
my $max_view_results  = 0;
my $max_click_results = 0;
my $max_click_rate    = 0;
for ( 0 .. 6 ) {
    my $previous = $now->clone->subtract( days => 1 );
    my $views_count = SL::Model::Report->ip_count_views( $previous, $now, $ip );
    unshift @{ $view_results[0] }, $now->strftime("%A");
    unshift @{ $view_results[1] }, $views_count->[0]->[0];
    if ( $views_count->[0]->[0] > $max_view_results ) {
        $max_view_results = $views_count->[0]->[0];
    }

    my $clicks_count =
      SL::Model::Report->ip_count_links( $previous, $now, $ip );
    unshift @{ $click_results[0] }, $now->strftime("%A");
    unshift @{ $click_results[1] }, $clicks_count->[0]->[0];
    if ( $clicks_count->[0]->[0] > $max_click_results ) {
        $max_click_results = $clicks_count->[0]->[0];
    }

    unshift @{ $click_rates[0] }, $now->strftime("%A");
    my $click_rate;
    if ( $views_count->[0]->[0] == 0 ) {
        $click_rate = 0;
    }
    else {
        $click_rate = 100 * $clicks_count->[0]->[0] / $views_count->[0]->[0];
    }
    unshift @{ $click_rates[1] }, $click_rate;
    if ( $click_rate > $max_click_rate ) {
        $max_click_rate = $click_rate;
    }

    $now = $previous->clone;
}

# build the ad summary
$now = DateTime->now->truncate( to => 'hour' );
my $yesterday = $now->clone->subtract( weeks => 1 );
my $ad_clicks_ref = SL::Model::Report->ip_links( $yesterday, $now, $ip );
use Text::Wrap;
$Text::Wrap::columns = 25;
my @ad_clicks_data;
my $max_ads_results = 0;
foreach my $ref ( sort { $a->[1] <=> $b->[1] } @{$ad_clicks_ref} ) {

    if ( length( $ref->[0] ) > 25 ) {
        $ref->[0] = wrap( "", "", $ref->[0] );
    }
    unshift @{ $ad_clicks_data[0] }, $ref->[0];
    unshift @{ $ad_clicks_data[1] }, $ref->[1];
    if ( $ref->[1] > $max_ads_results ) {
        $max_ads_results = $ref->[1];
    }
}

# Build the graphs
my $graph = GD::Graph::bars->new( 600, 450 );
my $duration = 'Week';

# Views first
$graph->set(
    title             => "Ad Views in Last $duration",
    y_max_value       => $max_view_results * 1.1,
    y_tick_number     => 10,
    y_number_format   => '%d',
    x_labels_vertical => 1,
    y_long_ticks      => 1,
    dclrs             => [qw(lblue)],
    bar_spacing       => 2,
) or die $graph->error;
$graph->set_title_font( '/usr/share/fonts/corefonts/verdanab.ttf', 16 );
$graph->set_x_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );

my $gd = $graph->plot( \@view_results )
  or die $graph->error;

my $fh;
open( $fh, '> /tmp/sl/views/weekly.png' ) or die $!;
print $fh $gd->png;
close($fh);

# Now clicks
$graph = GD::Graph::bars->new( 600, 450 );
$graph->set(
    title             => "Ad Clicks in Last $duration",
    y_max_value       => $max_click_results * 1.1,
    y_tick_number     => $max_click_results * 1.1,
    y_number_format   => '%d',
    y_label           => 'Number of Clicks',
    x_labels_vertical => 1,
    y_long_ticks      => 1,
    dclrs             => [qw(lred)],
    bar_spacing       => 2,
) or die $graph->error;
$graph->set_title_font( '/usr/share/fonts/corefonts/verdanab.ttf', 16 );
$graph->set_x_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_label_font( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );

$gd = $graph->plot( \@click_results )
  or die $graph->error;

open( $fh, '> /tmp/sl/clicks/weekly.png' ) or die $!;
print $fh $gd->png;
close($fh);

# Now the ad breakdown
$graph = GD::Graph::hbars->new( 600, 500 );
$graph->set(
    title           => "Ads Clicked in Last $duration",
    y_max_value     => $max_ads_results * 1.1,
    y_number_format => '%d',
    y_tick_number   => $max_ads_results * 1.1,
    y_label         => "Clicks in Last $duration",
    y_long_ticks    => 1,
    dclrs           => [qw(lblue)],
    bar_spacing     => 20,
) or die $graph->error;
$graph->set_title_font( '/usr/share/fonts/corefonts/verdanab.ttf', 16 );
$graph->set_x_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_label_font( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );
$graph->set_values_font( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );

$gd = $graph->plot( \@ad_clicks_data )
  or die $graph->error;

open( $fh, '> /tmp/sl/ads/weekly.png' ) or die $!;
print $fh $gd->png;
close($fh);

# Click rates
$graph = GD::Graph::bars->new( 600, 500 );
$graph->set(
    title             => "Click Rate Last $duration",
    y_max_value       => $max_click_rate * 1.1,
    y_tick_number     => 3,
    y_number_format   => '%.1f%%',
    x_labels_vertical => 1,
    y_long_ticks      => 1,
    dclrs             => [qw(lblue)],
    bar_spacing       => 2,
) or die $graph->error;
$graph->set_title_font( '/usr/share/fonts/corefonts/verdanab.ttf', 16 );
$graph->set_x_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_axis_font( '/usr/share/fonts/corefonts/verdana.ttf', 10 );
$graph->set_y_label_font( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );
$graph->set_values_font( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );

$gd = $graph->plot( \@click_rates )
  or die $graph->error;

open( $fh, '> /tmp/sl/crs/weekly.png' ) or die $!;
print $fh $gd->png;
close($fh);


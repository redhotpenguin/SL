package SL::Model::Report::Graph;

use strict;
use warnings;

use GD::Graph;
use GD::Graph::bars;
use GD::Graph::hbars;

our $WIDTH  = 600;
our $HEIGHT = 500;

our @TITLE_FONT   = ( '/usr/share/fonts/corefonts/verdanab.ttf', 14 );
our @X_AXIS_FONT  = ( '/usr/share/fonts/corefonts/verdana.ttf',  10 );
our @Y_AXIS_FONT  = ( '/usr/share/fonts/corefonts/verdana.ttf',  10 );
our @Y_LABEL_FONT = ( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );
our @VALUES_FONT  = ( '/usr/share/fonts/corefonts/verdanab.ttf', 12 );

sub bars {
    my ( $class, $args_ref ) = @_;

    my $graph = GD::Graph::bars->new( $WIDTH, $HEIGHT );
    $graph->set(
        title             => $args_ref->{title},
		x_labels_vertical => 1,
        y_max_value       => sprintf("%d", ($args_ref->{y_max_value}* 1.1)+1),
        y_tick_number     => sprintf("%d", 
			($args_ref->{y_tick_number}*1.1+1)) || 5,
        y_number_format   => $args_ref->{y_number_format} || '%d',
        y_label           => $args_ref->{y_label},
        y_long_ticks      => 1,
        dclrs             => $args_ref->{colors_ref} || [qw(lblue)],
    ) or die $graph->error;
    $graph->set_title_font(@TITLE_FONT);
    $graph->set_x_axis_font(@X_AXIS_FONT);
    $graph->set_y_axis_font(@Y_AXIS_FONT);
    $graph->set_y_label_font(@Y_LABEL_FONT);
    $graph->set_values_font(@VALUES_FONT);
    my $gd = $graph->plot( $args_ref->{data_ref} )
      or die $graph->error;

    my $fh;
    open( $fh, ">", $args_ref->{filename} ) 
    	or die "Could not open file " . $args_ref->{filename} . " " . $!;
    print $fh $gd->png;
    close($fh);
    return 1;
}

sub bars_many {
    my ( $class, $args_ref ) = @_;

    my $graph = GD::Graph::bars->new( $WIDTH, $HEIGHT );
    $graph->set(
        title             => $args_ref->{title},
        x_labels_vertical => 1,
        y_max_value       => sprintf("%d", ($args_ref->{y_max_value}* 1.1)+1),
        y_tick_number     => sprintf("%d", 
			($args_ref->{y_tick_number}*1.1+1)) || 5,
        y_number_format   => $args_ref->{y_number_format} || '%d',
        y_label           => $args_ref->{y_label},
        y_long_ticks      => 1,
        bargroup_spacing  => 4,
        cumulate          => $args_ref->{cumulate} || 1,
    ) or die $graph->error;
    $graph->set_legend( @{ $args_ref->{legend} } );
    $graph->set_title_font(@TITLE_FONT);
    $graph->set_x_axis_font(@X_AXIS_FONT);
    $graph->set_y_axis_font(@Y_AXIS_FONT);
    $graph->set_y_label_font(@Y_LABEL_FONT);
    $graph->set_values_font(@VALUES_FONT);

	unless (defined $args_ref->{data_ref}) {
		$args_ref->{data_ref} = [[0, 0], [0,0]];
	}
	my $gd = $graph->plot( $args_ref->{data_ref} )
      or die $graph->error;

    my $fh;
    open( $fh, ">", $args_ref->{filename} ) or die $!;
    print $fh $gd->png;
    close($fh);
    return 1;
}

sub hbars_many {
    my ( $class, $args_ref ) = @_;

    my $graph = GD::Graph::hbars->new( $WIDTH, $HEIGHT );
    $graph->set(
        title             => $args_ref->{title},
#        x_labels_vertical => 1,
        y_max_value       => sprintf("%d", ($args_ref->{y_max_value}* 1.1)+1),
        y_tick_number     => sprintf("%d", 
			($args_ref->{y_tick_number}*1.1+1)) || 5,
        y_number_format   => $args_ref->{y_number_format} || '%d',
        y_label           => $args_ref->{y_label},
        y_long_ticks      => 1,
        bar_spacing       => 5,
		#    bargroup_spacing  => 4,
        cumulate          => 1,
    ) or die $graph->error;
    $graph->set_legend( @{ $args_ref->{legend} } );
    $graph->set_title_font(@TITLE_FONT);
    $graph->set_x_axis_font(@X_AXIS_FONT);
    $graph->set_y_axis_font(@Y_AXIS_FONT);
    $graph->set_y_label_font(@Y_LABEL_FONT);
    $graph->set_values_font(@VALUES_FONT);
    my $gd = $graph->plot( $args_ref->{data_ref} )
      or die $graph->error;

    my $fh;
    open( $fh, ">", $args_ref->{filename} ) or die $!;
    print $fh $gd->png;
    close($fh);
    return 1;
}

sub hbars {
    my ( $class, $args_ref ) = @_;
    my $graph = GD::Graph::hbars->new( $WIDTH, $HEIGHT );
    $graph->set(
        title             => $args_ref->{title},
		#x_labels_vertical => 1,
        y_max_value       => sprintf("%d", ($args_ref->{y_max_value}* 1.1)+1),
        y_tick_number     => sprintf("%d", 
			($args_ref->{y_tick_number}*1.1+1)) || 5,
        y_number_format   => $args_ref->{y_number_format} || '%d',
        y_label           => $args_ref->{y_label},
        y_long_ticks      => 1,
        dclrs             => $args_ref->{colors_ref} || [qw(lblue)],
        bar_spacing       => 20,
    ) or die $graph->error;

    $graph->set_title_font(@TITLE_FONT);
    $graph->set_x_axis_font(@X_AXIS_FONT);
    $graph->set_y_axis_font(@Y_AXIS_FONT);
    $graph->set_y_label_font(@Y_LABEL_FONT);
    $graph->set_values_font(@VALUES_FONT);

    my $gd = $graph->plot( $args_ref->{data_ref} )
      or die $graph->error;

    my $fh;
    open( $fh, ">", $args_ref->{filename} ) or die $!;
    print $fh $gd->png;
    close($fh);
    return 1;
}
my %duration_hash = (
    daily     => '24 hours',
    weekly    => '7 days',
    monthly   => '30 days',
    quarterly => '90 days',
);


sub single_router_views {
    my ( $class, $params_ref ) = @_;

    eval {
        SL::Model::Report::Graph->bars({
                filename => $params_ref->{dir} . "/views.png",
                title    => "Ad Views "
                  . $duration_hash{ $params_ref->{temporal} } . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_label       => 'Number of Views',
                y_max_value   => $params_ref->{max},
                y_tick_number => 10,
                data_ref      => $params_ref->{data},
                colors_ref    => [qw(lblue)],
            });
    };
    die $@ if $@;
    return 1;
}

sub single_router_clicks {
    my ( $class, $params_ref ) = @_;

    # Build the graph for the number of clicks
    eval {
        SL::Model::Report::Graph->bars(
            {
                filename => $params_ref->{dir} . "/clicks.png",
                title    => "Ad Clicks "
                  . $duration_hash{ $params_ref->{temporal} } . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value   => $params_ref->{max},
                y_label       => 'Number of Clicks',
                y_tick_number => $params_ref->{max},
                data_ref      => $params_ref->{data},
                colors_ref    => [qw(lblue)],
            }
        );
    };
    die $@ if $@;
    return 1;
}

sub single_router_rates {
    my ( $class, $params_ref ) = @_;


    die unless (exists $params_ref->{max} && exists $params_ref->{data} &&
                exists $params_ref->{temporal} && exists $params_ref->{dir});

    # Build the graph for the click rates
    eval {
        SL::Model::Report::Graph->bars(
            {
                title => "Click Rate "
                  . $duration_hash{ $params_ref->{temporal} } . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                filename        => $params_ref->{dir} . "/rates.png",
                y_max_value     => $params_ref->{max},
                y_label         => 'Click Rate',
                x_label         => 'Date Interval',
                y_tick_number   => $params_ref->{max},
                y_number_format => '%.1f%%',
                data_ref        => $params_ref->{data},
                colors_ref      => [qw(lblue)],
            }
        );
    };
    die $@ if $@;
    return 1;
}

sub single_router_ad_summary {
    my ( $class, $params_ref ) = @_;

    eval {
        $class->hbars(
            {
                title => "Ads Clicked "
                  . $duration_hash{ $params_ref->{temporal} } . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                filename      => $params_ref->{dir} . "/ads.png",
                y_max_value   => $params_ref->{max},
                y_label       => 'Clicks 24 Hours',
                y_tick_number => $params_ref->{max},
                data_ref      => $params_ref->{data},
            }
        );
    };
    die $@ if $@;
    return 1;
}

sub composite_account_views {
    my ( $class, $params_ref ) = @_;

    my $max_views = 0;
    my $views_data_ref;
    my $headers = 0;
    my @series;

    # summarize the data
    foreach my $ip ( keys %{ $params_ref->{data_hashref} } ) {
        ## first compute the maximum values
        $max_views +=
          $params_ref->{data_hashref}{$ip}{views_clicks_rates}{max_views};

        # add the header data
        unless ($headers) {
            push @{$views_data_ref},
              @{ $params_ref->{data_hashref}{$ip}{views_clicks_rates}
                   {views_data} }[0];
            $headers++;
        }

        # add the actual data
        push @{$views_data_ref},
          @{ $params_ref->{data_hashref}{$ip}{views_clicks_rates}
              {views_data} }[1];

        # add this data set to the series
        push @series, join ( '', $params_ref->{reg}->email, ' - ', $ip );
    }

    # burn the graph
    eval {
        $class->bars_many(
            {
               filename => $params_ref->{dir} . "/views.png",
               title    => "Ad Views for " . $params_ref->{reg}->email
                . ", last " . $duration_hash{ $params_ref->{temporal} } . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value   => $max_views,
                y_tick_number => 10,
                y_label       => 'Number of ad views',
                data_ref      => $views_data_ref,
                legend        => \@series,
            }
        );
    };
    die $@ if $@;

    return 1;
}

sub composite_account_clicks {
    my ( $class, $params_ref ) = @_;

    my $max_clicks = 0;
    my $clicks_data_ref;
    my $headers = 0;
    my @series;

    # summarize the data
    foreach my $ip ( keys %{ $params_ref->{data_hashref} } ) {
        ## first compute the maximum values
        $max_clicks +=
          $params_ref->{data_hashref}{$ip}{views_clicks_rates}{max_clicks};

        # add the header data
        unless ($headers) {
            push @{$clicks_data_ref},
              @{ $params_ref->{data_hashref}{$ip}{views_clicks_rates}
                  {clicks_data} }[0];
            $headers++;
        }

        # add the actual data
        push @{$clicks_data_ref},
          @{ $params_ref->{data_hashref}{$ip}{views_clicks_rates}
              {clicks_data} }[1];

        # add this data set to the series
        push @series, join ( '', $params_ref->{reg}->email, ' - ', $ip );
    }

    eval {
        SL::Model::Report::Graph->bars_many(
            {
                filename => $params_ref->{dir} . "/clicks.png",
                title    => "Ad Clicks for "
                  . $params_ref->{reg}->email
                  . $duration_hash{ $params_ref->{temporal} } . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value   => $max_clicks,
                y_tick_number => $max_clicks,
                y_label       => 'Number of ad clicks',
                data_ref      => $clicks_data_ref,
                legend        => \@series,
            }
        );
    };
    die $@ if $@;
    return 1;
}


sub composite_account_rates {
  my ($class, $params_ref ) = @_;

  my $max_rates = 0;
  my $rates_data_ref;
  my $headers = 0;
  my @series;

    # summarize the data
    foreach my $ip ( keys %{ $params_ref->{data_hashref} } ) {
        ## first compute the maximum values
        $max_rates +=
          $params_ref->{data_hashref}{$ip}{views_clicks_rates}{max_rates};

        # add the header data
        unless ($headers) {
            push @{$rates_data_ref},
              @{ $params_ref->{data_hashref}{$ip}{views_clicks_rates}
                  {rates_data} }[0];
            $headers++;
        }

        # add the actual data
        push @{$rates_data_ref},
          @{ $params_ref->{data_hashref}{$ip}{views_clicks_rates}
              {rates_data} }[1];

        # add this data set to the series
        push @series, join ( '', $params_ref->{reg}->email, ' - ', $ip );
    }

    eval {
        SL::Model::Report::Graph->bars_many(
            {
                filename => $params_ref->{dir} . "/rates.png",
                title    => "Click Rates for " . $params_ref->{reg}->email
                  . $duration_hash{$params_ref->{temporal}} . " - "
                  . DateTime->now( time_zone => "local" )
                  ->strftime("%a %b %e,%l:%m %p"),
                y_max_value     => $max_rates,
                y_tick_number   => $max_rates,
                data_ref        => $rates_data_ref,
                legend          => \@series,
                y_number_format => '%.1f%%',
                y_label         => 'Click Rate',
                cumulate        => 0,
            }
        );
    };
    die $@ if $@;
  return 1;
}

sub composite_account_ads {
    my ( $class, $params_ref ) = @_;

    my $max_ads = 0;
    my $ads_data_ref;
    my $headers = 0;
    my @series;

    # summarize the data
    foreach my $ip ( keys %{ $params_ref->{data_hashref} } ) {
        ## first compute the maximum values
        $max_ads += $params_ref->{data_hashref}{$ip}{ads}{max};

        # add the actual data
        push @{ $ads_data_ref->[0] },
          @{ $params_ref->{data_hashref}{$ip}{ads}{data} }[0];
        push @{ $ads_data_ref->[1] },
          @{ $params_ref->{data_hashref}{$ip}{ads}{data} }[1];
        push @series, join ( '', $params_ref->{reg}->email, '-', $ip );
    }

    # [ 'ad_one', 'ad_two' ]
    # [ 'account_one_clicks_for_ad_one', 'account_one_clicks_for_ad_two' ]
    # munge the ad_data_ref into a friendly structure
    # if there was only a friendlier way to do this...
    my @ads_seen;
    push @ads_seen, @{$_} for @{ $ads_data_ref->[0] };
    my @graph_array;
    push @graph_array, \@ads_seen;

    # use this hash to make dealing with the array easier
    my $i             = 0;
    my %ads_seen_hash = map { $_ => $i++ } @ads_seen;

    foreach my $ip ( keys %{ $params_ref->{data_hashref} } ) {

        # this tracks the actual click numbers for the ad for the ip
        # initialize each element of the array to 0
        my @ad_clicks = map { 0 } 0 .. $#ads_seen;

        # Cycle through the ad clicks recorded for this ip
        for (
            my $i = 0 ;
            $i < @{ $params_ref->{data_hashref}{$ip}{ads}{data}[0] } ;
            $i++
          )
        {

            # grab the index
            my $ad = $params_ref->{data_hashref}{$ip}{ads}{data}[0]->[$i];
            my $ad_seen_index = $ads_seen_hash{$ad};

            # Update the ad_click value
            $ad_clicks[$ad_seen_index] =
              $params_ref->{data_hashref}{$ip}{ads}{data}[1]->[$i];

        }

        # whew! almost there (for this ip!)
        push @graph_array, \@ad_clicks;
    }

    eval {
        $class->hbars_many(
            {
                filename => $params_ref->{dir} . "/ads.png",
                title    => "Ads Clicked for "
                  . $params_ref->{reg}->email
                  . $duration_hash{$params_ref->{temporal}} . " - "
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
    return 1;
}


1;

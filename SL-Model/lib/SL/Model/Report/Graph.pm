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
        y_max_value => sprintf( "%d", ( $args_ref->{y_max_value} * 1.1 ) + 1 ),
        y_tick_number =>
          sprintf( "%d", ( $args_ref->{y_tick_number} * 1.1 + 1 ) ) || 5,
        y_number_format => $args_ref->{y_number_format} || '%d',
        y_label         => $args_ref->{y_label},
        y_long_ticks    => 1,
        dclrs           => $args_ref->{colors_ref}      || [qw(lblue)],
      )
      or die $graph->error;
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
        y_max_value => sprintf( "%d", ( $args_ref->{y_max_value} * 1.1 ) + 1 ),
        y_tick_number =>
          sprintf( "%d", ( $args_ref->{y_tick_number} * 1.1 + 1 ) ) || 5,
        y_number_format => $args_ref->{y_number_format} || '%d',
        y_label         => $args_ref->{y_label},
        y_long_ticks    => 1,
        bargroup_spacing => 4,
        cumulate         => $args_ref->{cumulate} || 1,
      )
      or die $graph->error;
    $graph->set_legend( @{ $args_ref->{legend} } );
    $graph->set_title_font(@TITLE_FONT);
    $graph->set_x_axis_font(@X_AXIS_FONT);
    $graph->set_y_axis_font(@Y_AXIS_FONT);
    $graph->set_y_label_font(@Y_LABEL_FONT);
    $graph->set_values_font(@VALUES_FONT);

    unless ( defined $args_ref->{data_ref} ) {
        $args_ref->{data_ref} = [ [ 0, 0 ], [ 0, 0 ] ];
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
        title => $args_ref->{title},

        #        x_labels_vertical => 1,
        y_max_value => sprintf( "%d", ( $args_ref->{y_max_value} * 1.1 ) + 1 ),
        y_tick_number =>
          sprintf( "%d", ( $args_ref->{y_tick_number} * 1.1 + 1 ) ) || 5,
        y_number_format => $args_ref->{y_number_format} || '%d',
        y_label         => $args_ref->{y_label},
        y_long_ticks    => 1,
        bar_spacing     => 5,

        #    bargroup_spacing  => 4,
        cumulate => 1,
      )
      or die $graph->error;
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
        title => $args_ref->{title},

        #x_labels_vertical => 1,
        y_max_value => sprintf( "%d", ( $args_ref->{y_max_value} * 1.1 ) + 1 ),
        y_tick_number =>
          sprintf( "%d", ( $args_ref->{y_tick_number} * 1.1 + 1 ) ) || 5,
        y_number_format => $args_ref->{y_number_format} || '%d',
        y_label         => $args_ref->{y_label},
        y_long_ticks    => 1,
        dclrs           => $args_ref->{colors_ref}      || [qw(lblue)],
        bar_spacing     => 20,
      )
      or die $graph->error;

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

##################################################

sub views {
    my ( $class, $params_ref ) = @_;

    # unpack
    my $filename     = $params_ref->{filename}     or die;
    my $reg          = $params_ref->{reg}          or die;
    my $data_hashref = $params_ref->{data_hashref} or die;
    my $temporal     = $params_ref->{temporal}     or die;

    my $duration = join ( ' - ',
        $duration_hash{ $params_ref->{temporal} },
        DateTime->now( time_zone => "local" )->strftime("%a %b %e,%l:%m %p") );

    # burn the graph
    eval {
        $class->bars_many(
            {
                filename => $filename,
                title    =>
                  sprintf( "Ad Views for %s, last %s", $reg->email, $duration ),
                y_max_value   => $data_hashref->{max},
                y_tick_number => 10,
                y_label       => 'Number of ad views',
                data_ref      => [
                    [ @{ $data_hashref->{headers} } ],
                    @{ $data_hashref->{data} }
                ],
                legend => $data_hashref->{series},
            }
        );
    };
    die $@ if $@;

    return 1;
}

sub clicks {
    my ( $class, $params_ref ) = @_;

    # unpack
    my $filename     = $params_ref->{filename}     or die;
    my $reg          = $params_ref->{reg}          or die;
    my $data_hashref = $params_ref->{data_hashref} or die;
    my $temporal     = $params_ref->{temporal}     or die;

    my $duration = join ( ' - ',
        $duration_hash{ $params_ref->{temporal} },
        DateTime->now( time_zone => "local" )->strftime("%a %b %e,%l:%m %p") );

    eval {
        SL::Model::Report::Graph->bars_many(
            {
                filename => $filename,
                title    => sprintf(
                    "Ad Clicks for %s, last %s", $reg->email, $duration
                ),
                y_max_value   => $data_hashref->{max},
                y_tick_number => 10,
                y_label       => 'Number of ad clicks',
                data_ref      => [
                    [ @{ $data_hashref->{headers} } ],
                    @{ $data_hashref->{data} }
                ],
                legend => $data_hashref->{series},
            }
        );
    };
    die $@ if $@;
    return 1;
}

sub ads_by_click {
    my ( $class, $params_ref ) = @_;

    # unpack
    my $filename     = $params_ref->{filename}     or die;
    my $reg          = $params_ref->{reg}          or die;
    my $data_hashref = $params_ref->{data_hashref} or die;
    my $temporal     = $params_ref->{temporal}     or die;

    my $duration = join ( ' - ',
        $duration_hash{ $params_ref->{temporal} },
        DateTime->now( time_zone => "local" )->strftime("%a %b %e,%l:%m %p") );

    # burn the graph
    eval {
        $class->hbars(
            {
                filename => $filename,
                title    => sprintf(
                    "Clicks by Ad for %s, last %s",
                    $reg->email, $duration
                ),
                y_max_value   => $data_hashref->{max},
                y_tick_number => 10,
                y_label       => 'Clicks',
                data_ref      => [
                    [ @{ $data_hashref->{headers} } ],
                    @{ $data_hashref->{data} }
                ],
                legend => $data_hashref->{series},
            }
        );
    };
    die $@ if $@;

    return 1;
}

sub click_rates {
    my ( $class, $params_ref ) = @_;

    # unpack
    my $filename     = $params_ref->{filename}     or die;
    my $reg          = $params_ref->{reg}          or die;
    my $data_hashref = $params_ref->{data_hashref} or die;
    my $temporal     = $params_ref->{temporal}     or die;

    my $duration = join ( ' - ',
        $duration_hash{ $params_ref->{temporal} },
        DateTime->now( time_zone => "local" )->strftime("%a %b %e,%l:%m %p") );

    # burn the graph
    eval {
        SL::Model::Report::Graph->hbars(
            {
                filename => $filename,
                title    => sprintf(
                    "Ad Click Rates for %s, last %s",
                    $reg->email, $duration
                ),
                y_max_value   => $data_hashref->{max},
                y_tick_number => 2.5,
                data_ref      => [
                    [ @{ $data_hashref->{headers} } ],
                    @{ $data_hashref->{data} }
                ],
                legend          => $data_hashref->{series},
                y_number_format => '%.1f%%',
                y_label         => 'Click Rate',
            }
        );
    };
    die $@ if $@;

    return 1;
}

##########################################

1;

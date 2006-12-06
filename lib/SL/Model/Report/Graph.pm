package SL::Model::Report::Graph;

use strict;
use warnings;

use GD::Graph;
use GD::Graph::bars;
use GD::Graph::hbars;

our $WIDTH  = 600;
our $HEIGHT = 500;

our @TITLE_FONT   = ( '/usr/share/fonts/corefonts/verdanab.ttf', 16 );
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

1;

package SL::Model::Report;

use strict;
use warnings;

use base 'SL::Model';
use SL::Model::App;

use Carp qw/croak/;
use DateTime::Format::Pg;
use DBD::Pg qw(:pg_types);
use Text::Wrap;
$Text::Wrap::columns = 25;

use Number::Format;
my $de = Number::Format->new;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

sub _ad_text_from_id {
    my ( $class, $ad_id ) = @_;

    my ( $return, $ad_text, $ad );
    if ( ($ad) =
        SL::Model::App->resultset('AdLinkshare')->search( { ad_id => $ad_id } )
      )
    {

        # look in linkshare first;
        $ad_text = $ad->displaytext;
    }
    else {

        # it's an sl ad
        ($ad) =
          SL::Model::App->resultset('AdSl')->search( { ad_id => $ad_id } );
        die "Couldn't find ad $ad_id" unless $ad;
        $ad_text = $ad->text;
    }

    # wrap the text if the length is greater than the wrap length
    if ( length($ad_text) >= $Text::Wrap::columns ) {
        $ad_text = wrap( "", "", $ad_text );
    }
    return $ad_text;
}

# set the DateTime object minute to the previous 15 minute interval
sub last_fifteen {
    my ( $class, $dt ) = @_;
    die unless ( $class->isa(__PACKAGE__) && $dt->isa('DateTime') );
    my $dt_start = $dt->clone;
    $dt_start->truncate( to => 'hour' );
    my $minutes = 15;
    for ( 1 .. 4 ) {
        $dt_start->add( minutes => $minutes );
        if ( $dt < $dt_start ) {
            $dt->set_minute(
                $dt_start->subtract( minutes => $minutes )->minute );
            return 1;
        }
    }
    die "Could not calculate last_fifteen";
}

# hash to facilitate reporting
my %time_hash = (
    daily => {
        range    => [ 0 .. 23 ],
        interval => [ hours => 1 ],
        format   => "%a %l %p",
        subtract => { days => 1 },
    },
    weekly => {
        range    => [ 0 .. 6 ],
        interval => [ days => 1 ],
        format   => "%a %e, %l %p",
        subtract => { weeks => 1 },
    },
    monthly => {
        range    => [ 0 .. 29 ],
        interval => [ days => 1 ],
        format   => "%a %b %e",
        subtract => { months => 1 },
    },
    quarterly => {
        range    => [ 0 .. 11 ],
        interval => [ weeks => 1 ],
        format   => "%a %b %e",
        subtract => { months => 3 },
    },
    biannually => {
        range    => [ 0 .. 5 ],
        interval => [ months => 1 ],
        format   => "%a %b %e",
        subtract => { months => 6 },
    },
    annually => {
        range    => [ 0 .. 11 ],
        interval => [ months => 1 ],
        format   => "%a %b %e",
        subtract => { months => 12 },
    },
);

sub validate {
    my ( $class, $params ) = @_;

    # validate
    my $reg      = $params->{reg}      or die;
    my $temporal = $params->{temporal} or die;
    my $routers_aryref = $params->{routers}
      or ( require Carp && Carp::confess("no routers") );

    require Carp && Carp::confess 'not a router object'
      unless defined $routers_aryref->[0] && 
        $routers_aryref->[0]->isa('SL::Model::App::Router');

    die "Invalid temporal parameter passed"
      unless grep { $temporal eq $_ } keys %time_hash;

    return ( $reg, $temporal, $routers_aryref );
}

sub _series {
  my $routers_aryref = shift;
  return [ map { sprintf('%s (%s)', $_->name, $_->ssid) }
                           sort { $a->router_id <=> $b->router_id }
                           @{ $routers_aryref } ];
}

# generates the graph data for view counts
#
# return data structure, first array index is headers, rest are data
# $results = {
#          headers => [ 'Sun May 5th', 'Mon May 6th' ], # x values
#          data    => [                                 # y values
#                       [  '100', '420' ],              # location one
#                       [  '150', '120' ],              # location two
#                     ],
#          series  => [ 'location one desc', 'location two desc' ],
#          max     => [ '420' ]  # used to determine max y value
#          total  =>  '15235' # total number of views
# };

sub views {
    my ( $class, $params ) = @_;
    my ( $reg, $temporal, $routers_aryref ) = $class->validate($params);

    # init
    my $results =
      { max => 0, headers => [], data => [], series => [], total => 0 };

    # report end time
    my $end = DateTime->now( time_zone => 'local' );
    $end->truncate( to => 'hour' );

    # create the series
    $results->{series} = _series($routers_aryref);

    for ( @{ $time_hash{$temporal}->{range} } ) {

        print STDERR "processing time slice $_\n" if DEBUG;

        # add the date in the format specified, this is the header
        my $start =
          $end->clone->subtract( @{ $time_hash{$temporal}->{interval} } );
        unshift @{ $results->{headers} },
          $start->strftime( $time_hash{$temporal}->{format} );

        # Ads viewed data for routers
        my $views_hashref = $reg->views_count( $start, $end, $routers_aryref );

        # add the data
        my $i = 0;    # router1, router2, etc
        foreach my $router_id ( sort {$a <=> $b }
                                keys %{ $views_hashref->{routers} } ) {
            unshift @{ $results->{data}->[ $i++ ] },
              $views_hashref->{routers}->{$router_id}->{count};
        }

        # update the max
        if ( $views_hashref->{total} > $results->{max} ) {
            $results->{max} = $views_hashref->{total};
        }

        $results->{total} += $views_hashref->{total};

        # shift the end point
        $end = $start->clone;
    }

    # now weed out the series that don't have any data other than 0
    my @series = @{ $results->{series} };
    my @remove_indices;
    for ( 0 .. $#series ) {
        my $row_aryref = $results->{data}->[$_];
        my $only_zeros = 1;
        foreach my $col ( @{$row_aryref} ) {
            if ( $col != 0 ) {
                $only_zeros = 0;
                last;
            }
        }
        if ( $only_zeros == 1 ) {

            # this series only has zeros, so splice the arrays
            push @remove_indices, $_;
        }
    }
    my $num_splices = 0;
    foreach my $index (@remove_indices) {
        $index -= $num_splices++;
        splice( @{ $results->{series} }, $index, 1 );
        splice( @{ $results->{data} },   $index, 1 );

    }

    # make sure we are left with something
    if ( scalar( @{ $results->{data} } ) == 0 ) {
        push @{ $results->{data} },
          [0] for 0 .. scalar( @{ $results->{headers} } );
        $results->{series}->[0] = 'empty dataset';
    }

    $results->{total} = $de->format_number( $results->{total} );
    return $results;
}

sub clicks {
    my ( $class, $params ) = @_;
    my ( $reg, $temporal, $routers_aryref ) = $class->validate($params);

    # init
    my $results =
      { max => 0, headers => [], data => [], series => [], total => 0 };

    # report end time
    my $end = DateTime->now( time_zone => 'local' );
    $end->truncate( to => 'hour' );

    # create the series
    $results->{series} = _series($routers_aryref);

    for ( @{ $time_hash{$temporal}->{range} } ) {

        print STDERR "processing time slice $_\n" if DEBUG;

        # add the date in the format specified, this is the header
        my $start =
          $end->clone->subtract( @{ $time_hash{$temporal}->{interval} } );
        push @{ $results->{headers} },
          $start->strftime( $time_hash{$temporal}->{format} ) . ' - '
          . $end->strftime( $time_hash{$temporal}->{format} );

        # Ads clicks data for locations
        my $clicks_hashref =
          $reg->clicks_count( $start, $end, $routers_aryref );

        # add the data
        my $i = 0;    # location1, location2, etc
        foreach my $router_id ( keys %{ $clicks_hashref->{routers} } ) {
            push @{ $results->{data}->[ $i++ ] },
              $clicks_hashref->{routers}->{$router_id}->{count};
        }

        # update the max
        if ( $clicks_hashref->{total} > $results->{max} ) {
            $results->{max} = $clicks_hashref->{total};
        }

        $results->{total} += $clicks_hashref->{total};

        # shift the end point
        $end = $start->clone;
    }
    $results->{total} = $de->format_number( $results->{total} );
    return $results;
}

# $results = {
#          headers => [ 'Sun May 5th', 'Mon May 6th' ], # x values
#          data    => [                                 # y values
#                       [  '100', '420' ],              # location one
#                       [  '150', '120' ],              # location two
#                     ],
#          series  => [ 'location one desc', 'location two desc' ],
#          max     => [ '420' ]  # used to determine max y value
# };

sub ads_by_click {
    my ( $class, $params ) = @_;
    my ( $reg, $temporal, $routers_aryref ) = $class->validate($params);

    die "no routers passed\n" unless $routers_aryref->[0]->isa("SL::Model::App::Router");

    # init
    my $results = { max => 0, headers => [], data => [], series => [] };
    my $max     = 0;

    # report times
    my $end = DateTime->now( time_zone => 'local' );
    $end->truncate( to => 'hour' );
    my $start = $end->clone->subtract( $time_hash{$temporal}->{subtract} );

    # get the ads grcouped
    my $ads_by_click = $reg->ads_by_click( $start, $end, $routers_aryref );

    $results->{max} = $ads_by_click->{max};

    foreach my $ad_id ( keys %{ $ads_by_click->{ads} } ) {

        push @{ $results->{headers} },
          $class->_ad_text_from_id($ad_id);           # header
        push @{ $results->{data} },
          $ads_by_click->{ads}->{$ad_id}->{count};    # data

        if ( $ads_by_click->{ads}->{$ad_id}->{count} > $max ) {
            $max = $ads_by_click->{ads}->{$ad_id};
        }
    }

    # handle race condition
    if ( scalar( @{ $results->{headers} } ) == 0 ) {
        $results->{headers} = ['No Ad Clicks'];
        $results->{data}    = [0];
    }

    # create the series
    @{ $results->{series} } = ('Ad Clicks for all locations');

    return $results;
}

sub click_rates {
    my ( $class, $params ) = @_;
    my ( $reg, $temporal, $routers_aryref ) = $class->validate($params);
    die "no routers passed\n" unless $routers_aryref->[0]->isa("SL::Model::App::Router");

    # init
    my $results = { max => 0, headers => [], data => [], series => [] };
    my $max     = 0;

    # report times
    my $end = DateTime->now( time_zone => 'local' );
    $end->truncate( to => 'hour' );
    my $start = $end->clone->subtract( $time_hash{$temporal}->{subtract} );

    # get the click rates
    my $click_rates = $reg->click_rates( $start, $end, $routers_aryref );

    $results->{max} = $click_rates->{max};

    foreach my $ad_id ( keys %{ $click_rates->{ads} } ) {
        push @{ $results->{headers} },
          $class->_ad_text_from_id($ad_id);         # header
        push @{ $results->{data} },
          $click_rates->{ads}->{$ad_id}->{rate};    # data
    }

    # handle race condition
    if ( scalar( @{ $results->{headers} } ) == 0 ) {
        $results->{headers} = ['No Ad Clicks'];
        $results->{data}    = [0];
    }

    # create the series
    @{ $results->{series} } = ('Ad Clicks for all routers');

    return $results;
}

1;

__END__


# SL::Model::Report
# bubild the ad summary
sub ad_summary {
    my ( $class, $ip, $start_date, $now ) = @_;
    my $ad_clicks_ref = SL::Model::Report->ip_clicks( $start_date, $now, $ip );

    my @ad_clicks_data;
    my $max_ad_clicks = 0;
    # sort by count of ad_id
    foreach my $ref ( sort { $a->[1] <=> $b->[1] } @{$ad_clicks_ref} ) {

        my $ad_text = $ref->[0];

        unshift @{ $ad_clicks_data[0] }, $ad_text;
        unshift @{ $ad_clicks_data[1] }, $ref->[1];

        # set the max number of ad clicks
        if ( $ref->[1] > $max_ad_clicks ) {
            $max_ad_clicks = $ref->[1];
        }
    }

    # handle those unfortunately empty report entries
    $max_ad_clicks ||= 1;
    $ad_clicks_data[0] ||= [0];
    $ad_clicks_data[1] ||= [0];

    my %return = (
                  max => $max_ad_clicks,
                  data => \@ad_clicks_data,
                  );
    return \%return;
}


#####################################

# queries for the reporting page
my $ip_views = <<SQL;
SELECT ad_id, count(view_id) 
FROM view
WHERE view.cts BETWEEN ? AND ?
AND ip = ?
GROUP BY ad_id
SQL

# returns views for an ip within for $start to $end
sub ip_views {
    my ( $class, $start, $end, $ip ) = @_;
    die unless $start->isa('DateTime');
    die unless $end->isa('DateTime');
    die unless $end > $start;

    my $ary_ref = $class->run_query( $ip_views, $start, $end, $ip );

    my @ary = map { { ad_id => $_->[0], count => $_->[1] } } @{$ary_ref};
    return \@ary;
}

sub ip_count_views {
    my ( $class, $start, $end, $ip ) = @_;

    my $ip_views = $class->ip_views( $start, $end, $ip );
    my $count = 0;
    foreach my $view (@{$ip_views}) {
      $count += $view->{count};
    }
    return $count;
}


########################################


my $ip_clicks = <<SQL;
SELECT ad_id, count(click_id)
FROM click
WHERE cts BETWEEN ? AND ?
AND ip = ?
GROUP BY click_id
SQL

# returns clicks for an ip within for $start to $end
sub ip_clicks {
    my ( $class, $start, $end, $ip ) = @_;

    die unless $start->isa('DateTime');
    die unless $end->isa('DateTime');
    die unless $end > $start;

    my $ary_ref = $class->run_query( $ip_views, $start, $end, $ip );

    my @ary = map { { ad_id => $_->[0], count => $_->[1] } } @{$ary_ref};
    return \@ary;
}

sub ip_count_clicks {
    my ( $class, $start, $end, $ip ) = @_;

    my $ip_clicks = $class->ip_clicks( $start, $end, $ip );
    my $count = 0;
    foreach my $clicks (@{$ip_clicks}) {
      $count += $clicks->{count};
    }
    return $count;
}

sub data_weekly_ip {
    my ( $class, $ip ) = @_;

    my (
        $max_view_results, @view_results,   $max_click_results,
        @click_results,    $max_click_rate, @click_rates
    );
    $max_view_results = $max_click_results = $max_click_rate = 0;

    my $now = DateTime->now( time_zone => 'local' );
    $now->truncate( to => 'hour' );

    for ( 0 .. 6 ) {
        my $previous = $now->clone->subtract( hours => 24 );

        # Ads viewed
        my $views_count =
          SL::Model::Report->ip_count_views( $previous, $now, $ip );

        # add the date in the format "Mon 1pm to Mon 2pm"
        unshift @{ $view_results[0] },
          $previous->strftime("%a %l %p");
        unshift @{ $view_results[1] }, $views_count->[0]->[0];
        if ( $views_count->[0]->[0] > $max_view_results ) {
            $max_view_results = $views_count->[0]->[0];
        }

    }

}

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
our $De = Number::Format->new;

use constant DEBUG => $ENV{SL_DEBUG} || 1;

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
    my $account      = $params->{account}      or die;
    my $temporal = $params->{temporal} or die;
    my $routers_aryref = $params->{routers}
      or ( require Carp && Carp::confess("no routers") );

    require Carp && Carp::confess 'not a router object'
      unless defined $routers_aryref->[0] && 
        $routers_aryref->[0]->isa('SL::Model::App::Router');

    die "Invalid temporal parameter passed"
      unless grep { $temporal eq $_ } keys %time_hash;

    return ( $account, $temporal, $routers_aryref );
}

sub _series {
  my $routers_aryref = shift;
 
  return [ map { sprintf('%s (%s)', $_->name || 'unnamed', $_->ssid || 'no ssid') }
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

    my ( $account, $temporal, $routers_aryref ) = $class->validate($params);

    # init
    my $results =
      { max => 0, headers => [], data => [], series => [], total => 0 };

    # report end time
    my $end = DateTime->now( time_zone => 'local' );
    $end->truncate( to => 'hour' );

    # create the series
    $results->{series} = _series($routers_aryref);

    for ( @{ $time_hash{$temporal}->{range} } ) {

        print STDERR "==> processing time slice $_\n" if DEBUG;

        # add the date in the format specified, this is the header
        my $start =
          $end->clone->subtract( @{ $time_hash{$temporal}->{interval} } );
        unshift @{ $results->{headers} },
          $start->strftime( $time_hash{$temporal}->{format} );

        # Ads viewed data for routers
        my $views_hashref = $account->views_count( $start, $end, $routers_aryref );

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

    $results->{total} = $De->format_number( $results->{total} );
    return $results;
}

1;


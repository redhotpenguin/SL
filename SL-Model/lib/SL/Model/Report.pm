package SL::Model::Report;

use strict;
use warnings;

use base 'SL::Model';
use Carp qw/croak/;
use DateTime::Format::Pg;
use DBD::Pg qw(:pg_types);
use SL::Model::App;

my $ad_sql = <<SQL;
SELECT ad.ad_id, ad.text
FROM ad
SQL

sub _ad_text_from_id {
  my ($class, $ad_id) = @_;
  # look in linkshare first;
  my $return;
  my $ad;
  if (($ad) = SL::Model::App->resultset('AdLinkshare')->search({ 
                  ad_id => $ad_id})) {
    return $ad->displaytext;
  } else {
    # it's an sl ad
    ($ad) = SL::Model::App->resultset('AdSl')->search({ ad_id => $ad_id});
    die "Couldn't find ad $ad_id" unless $ad;
    return $ad->text;
  }
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

###############################################################

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

# SL::Model::Report
# build the ad summary
sub ad_summary {
    my ( $class, $ip, $start_date, $now ) = @_;
    my $ad_clicks_ref = SL::Model::Report->ip_clicks( $start_date, $now, $ip );

    # wrap the text if too long
    use Text::Wrap;
    $Text::Wrap::columns = 25;

    my @ad_clicks_data;
    my $max_ad_clicks = 0;
    # sort by count of ad_id
    foreach my $ref ( sort { $a->[1] <=> $b->[1] } @{$ad_clicks_ref} ) {

        my $ad_text = $ref->[0];

        # wrap the text if the length is greater than the wrap length
        if ( length( $ad_text ) >= $Text::Wrap::columns ) {
            $ad_text = wrap( "", "", $ad_text );
        }
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

# Last 24 hours of data for an ip and a given temporal range
# ( daily, weekly, monthly, quarterly )
sub data_for_ip {
    my ( $class, $ip, $temporal ) = @_;

    die "No IP passed to data_for_ip" unless $ip;
    die "No temporal param passed"    unless $temporal;

    my (
        $max_view_results, @view_results,   $max_click_results,
        @click_results,    $max_click_rate, @click_rates
    );
    $max_view_results = $max_click_results = $max_click_rate = 0;

    my $now = DateTime->now( time_zone => 'local' );
    $now->truncate( to => 'hour' );

    my %time_hash = (
        daily => {
            range    => [ 0 .. 23 ],
            interval => [ hours => 1],
            format   => "%a %l %p"
        },
        weekly =>
          { range => [ 0 .. 6 ], interval => [ days => 1 ], format => "%a %e, %l %p" },
        monthly => { range => [ 0 .. 29 ], interval => [ days => 1 ], format => "%a %b %e" },
        quarterly =>
          { range => [ 0 .. 11 ], interval => [ weeks => 1 ], format => "%a %b %e" },
    );
    die "Invalid temporal parameter passed"
      unless grep { $temporal eq $_ } keys %time_hash;

    for ( @{ $time_hash{$temporal}->{range} } ) {
        my $previous =
          $now->clone->subtract( @{$time_hash{$temporal}->{interval}} );

        # Ads viewed
        my $views_count =
          SL::Model::Report->ip_count_views( $previous, $now, $ip );

        # add the date in the format specified
        unshift @{ $view_results[0] },
          $previous->strftime( $time_hash{$temporal}->{format} ) . ' - '
          . $now->strftime( $time_hash{$temporal}->{format} );

        # then the data
        unshift @{ $view_results[1] }, $views_count->[0]->[0];
        if ( $views_count->[0]->[0] > $max_view_results ) {
            $max_view_results = $views_count->[0]->[0];
        }

        # Ads clicked
        my $clicks_count =
          SL::Model::Report->ip_count_clicks( $previous, $now, $ip );

        # date
        unshift @{ $click_results[0] },
          $previous->strftime( $time_hash{$temporal}->{format} ) . ' - '
          . $now->strftime( $time_hash{$temporal}->{format} );

        # data
        unshift @{ $click_results[1] }, $clicks_count->[0]->[0];
        if ( $clicks_count->[0]->[0] > $max_click_results ) {
            $max_click_results = $clicks_count->[0]->[0];
        }

        # Click rate
        unshift @{ $click_rates[0] },
          $previous->strftime( $time_hash{$temporal}->{format} ) . ' - '
          . $now->strftime( $time_hash{$temporal}->{format} );
        my $click_rate;
        if ( $views_count->[0]->[0] == 0 ) {

            # sometimes the view count is zero, and can't divide by zero
            $click_rate = 0;
        }
        else {
            $click_rate =
              100 * $clicks_count->[0]->[0] / $views_count->[0]->[0];
        }
        unshift @{ $click_rates[1] }, $click_rate;
        if ( $click_rate > $max_click_rate ) {
            $max_click_rate = $click_rate;
        }

        $now = $previous->clone;
    }

    my %return = (
        max_views        => $max_view_results,
        views_data       => \@view_results,
        max_clicks       => $max_click_results,
        clicks_data      => \@click_results,
        max_rates  => $max_click_rate,
        rates_data => \@click_rates,
    );

    return \%return;
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
          $previous->strftime("%a %l %p") . ' - ' . $now->strftime("%a %l %p");
        unshift @{ $view_results[1] }, $views_count->[0]->[0];
        if ( $views_count->[0]->[0] > $max_view_results ) {
            $max_view_results = $views_count->[0]->[0];
        }

    }

}

1;

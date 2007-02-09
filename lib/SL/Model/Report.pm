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

my $link_sql = <<SQL;
SELECT link.link_id, link.uri
FROM link
WHERE link.ad_id = ?
SQL

# clicks for a given time period
my $click_sql = <<SQL;
SELECT click.click_id, click.cts
FROM click
INNER JOIN link
USING(link_id)
WHERE link_id = ? AND
click.ts BETWEEN ? AND ?
SQL

# views for a given time period
my $view_sql = <<SQL;
SELECT ip, count(ip) FROM view
WHERE view.cts between
? and  ?
GROUP BY ip
ORDER BY count(ip) DESC
SQL

# what adss were clicked for a given time period
my $clicks = <<SQL;
SELECT ad_id, count(click_id) FROM click
WHERE cts BETWEEN ? AND ?
GROUP BY ad_id
SQL

my $ad_ids_clicked_by_ip = <<SQL;
SELECT ad_id, count(click_id) FROM click
WHERE cts BETWEEN ? AND ?
AND ip = ?
GROUP BY ad_id
SQL

# queries for the reporting page
my $ip_views = <<SQL;
SELECT ad_id, count(view_id) 
FROM view
WHERE view.cts BETWEEN ? AND ?
AND ip = ?
GROUP BY ad_id
SQL

my $ip_count_views = <<SQL;
SELECT count(ad_id) 
FROM view
WHERE view.cts BETWEEN ? AND ?
AND ip = ?
SQL

my $ip_count_clicks = <<SQL;
SELECT count(click_id)
FROM click
WHERE cts BETWEEN ? AND ?
AND ip = ?
SQL

my $ip_clicks = <<SQL;
SELECT click_id, count(click_id)
FROM click
WHERE cts BETWEEN ? AND ?
AND ip = ?
GROUP BY click_id
SQL

sub run_query {
    my ( $class, $sql, $start, $end, $ip ) = @_;

    die unless $sql && $start && $end;

    unless ( $start->isa('DateTime') && $end->isa('DateTime') ) {
        croak('No start and end times passed!');
    }
    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare_cached($sql);

    $sth->bind_param( 1, DateTime::Format::Pg->format_datetime($start) );
    $sth->bind_param( 2, DateTime::Format::Pg->format_datetime($end) );
    $sth->bind_param( 3, $ip ) if $ip;
    my $rv      = $sth->execute;
    my $ary_ref = $sth->fetchall_arrayref;
    return $ary_ref;
}

sub views {
    my ( $class, $start, $end ) = @_;
    my $ary_ref = $class->run_query( $view_sql, $start, $end );
    my $dbh = SL::Model->db_Main();
    my $sql = <<SQL;
SELECT reg.email, router.ip, router.name
FROM router
LEFT JOIN reg using (reg_id)
WHERE ip = ?
SQL
    my $sth = $dbh->prepare($sql);
    foreach my $entry ( @{$ary_ref} ) {
        # add the email and router name/ip to the entry
        $sth->bind_param(1, $entry->[0]);
        $sth->execute;
        my $reg_ary_ref = $sth->fetchrow_arrayref;
        if ($reg_ary_ref) {
            $entry->[0] = join(' - ', @{$reg_ary_ref}[0..1], 
                               $reg_ary_ref->[2] || '');
        }
    }
    return $ary_ref;
}

sub _ad_text_from_id {
  my ($class, $ad_id) = @_;
  # look in linkshare first;
  my $return;
  if (my ($ad) = SL::Model::App->resultset('AdLinkshare')->search({ 
                  ad_id => $ad_id}) {
    return $ad->displaytext;
  } else {
    # it's an sl ad
    my ($ad) = SL::Model::App->resultset('AdSl')->search({ ad_id => $ad_id});
    die "Couldn't find ad $ad_id" unless $ad;
    return $ad->text;
  }
}

sub clicks {
    my ( $class, $start, $end ) = @_;
    
    my $clicks_ref = $class->run_query( $clicks, $start, $end );

    foreach my $c (@{$clicks_ref}) {
      $c->[0] = $class->_ad_text_from_id($c->[0]);
    }
    return $clicks_ref;
}

# returns views for an ip within for $start to $end
sub ip_views {
    my ( $class, $start, $end, $ip ) = @_;
    return $class->run_query( $ip_views, $start, $end, $ip );
}

sub ip_count_views {
    my ( $class, $start, $end, $ip ) = @_;
    return $class->run_query( $ip_count_views, $start, $end, $ip );
}

# returns clicks for an ip within for $start to $end
sub ip_clicks {
    my ( $class, $start, $end, $ip ) = @_;
    my $clicks_ref = 
      $class->run_query( $ad_ids_clicked_by_ip, $start, $end, $ip );
    foreach my $c (@{$clicks_ref}) {
      $c->[0] = $class->_ad_text_from_id($c->[0]);
    }
    return $clicks_ref;
}

sub ip_count_clicks {
    my ( $class, $start, $end, $ip ) = @_;
    return $class->run_query( $ip_count_clicks, $start, $end, $ip );
}

sub interval_by_ts {
    my ( $class, $ts ) = @_;

    croak('No start and end times passed!')
      unless (
        ( ref $ts->{'start'} && UNIVERSAL::isa( $ts->{'start'}, 'DateTime' ) )
        && ( ref $ts->{'end'} && UNIVERSAL::isa( $ts->{'end'}, 'DateTime' ) ) );

    my %return;
    my $dbh = SL::Model->db_Main();

    my $ad_sth = $dbh->prepare_cached($ad_sql);
    my $rv     = $ad_sth->execute;
    die print STDERR "Doh something bad happened during ad fetch\n" unless $rv;

    while ( my $ad = $ad_sth->fetchrow_hashref ) {
        my $link_sth = $dbh->prepare_cached($link_sql);
        $link_sth->bind_param( 1, $ad->{'ad_id'} )
          ;    #, { pg_type => PG_INTEGER } );
        $rv = $link_sth->execute;
        die print STDERR "Something bad happened in link fetch\n" unless $rv;

        while ( my $link = $link_sth->fetchrow_hashref ) {
            my $click_sth = $dbh->prepare_cached($click_sql);
            $click_sth->bind_param( 1, $link->{'link_id'} )
              ;    #, { pg_type => PG_INTEGER });
            $click_sth->bind_param( 2,
                DateTime::Format::Pg->format_datetime( $ts->{'start'} ) );

            #, { pg_type => PG_TIMESTAMP });
            $click_sth->bind_param( 3,
                DateTime::Format::Pg->format_datetime( $ts->{'end'} ) );

            #, { pg_type => PG_TIMESTAMP });
            $rv = $click_sth->execute;
            if ( $rv == 0 ) {
                $return{ $ad->{'name'} }{ $link->{'uri'} }{'count'} = 0;
            }
            else {
                while ( my $click = $click_sth->fetchrow_arrayref ) {
                    push
                      @{ $return{ $ad->{'name'} }{ $link->{'uri'} }{'times'} },
                      $click->[1];
                    $return{ $ad->{'name'} }{ $link->{'uri'} }{'count'}++;
                }

            }
        }
    }
    return \%return;
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

# SL::Model::Report
# build the ad summary
sub ad_clicks_summary {
    my ( $class, $ip, $start_date, $now ) = @_;
    my $ad_clicks_ref = SL::Model::Report->ip_clicks( $start_date, $now, $ip );

    # wrap the text if too long
    use Text::Wrap;
    $Text::Wrap::columns = 25;

    my @ad_clicks_data;
    my $max_ad_clicks = 0;
    # sort by count of ad_id
    foreach my $ref ( sort { $a->[1] <=> $b->[1] } @{$ad_clicks_ref} ) {

        my $ad_text = $class->_ad_text_from_id($ref->[0]);
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
    return ( $max_ad_clicks, \@ad_clicks_data );
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

    return (
        $max_view_results, \@view_results,  $max_click_results,
        \@click_results,   $max_click_rate, \@click_rates
    );
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

package SL::Model::Report;

use strict;
use warnings;

use base 'SL::Model';
use Carp qw/croak/;
use DateTime::Format::Pg;
use DBD::Pg qw(:pg_types);

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
SELECT click.click_id, click.ts
FROM click
INNER JOIN link
USING(link_id)
WHERE link_id = ? AND
click.ts BETWEEN ? AND ?
SQL

# views for a given time period
my $view_sql = <<SQL;
SELECT reg.email, count(ip) FROM view
LEFT JOIN reg USING (ip)
WHERE view.ts between ? and ?
GROUP BY reg.email
ORDER BY count(ip) DESC
SQL

# what links were clicked for a given time period
my $links_clicked = <<SQL;
SELECT ad.text, count(link_id) from click
left join link
 using (link_id)
 left join ad using (ad_id)
WHERE ts BETWEEN ? AND ?
 GROUP BY ad.text
 ORDER BY count(link_id) DESC
SQL

my $links_clicked_ip = <<SQL;
SELECT ad.text, count(link_id) from click
left join link
 using (link_id)
 left join ad using (ad_id)
WHERE ts BETWEEN ? AND ?
AND ip = ?
 GROUP BY ad.text
 ORDER BY count(link_id) DESC
SQL

# queries for the reporting page
my $ip_views = <<SQL;
SELECT ad_id, count(ad_id) 
FROM view
WHERE view.ts BETWEEN ? AND ?
AND ip = ?
GROUP BY ad_id
SQL

my $ip_count_views = <<SQL;
SELECT count(ad_id) 
FROM view
WHERE view.ts BETWEEN ? AND ?
AND ip = ?
SQL

my $ip_count_links = <<SQL;
SELECT count(link_id)
FROM click
WHERE ts BETWEEN ? AND ?
AND ip = ?
SQL

my $ip_links = <<SQL;
SELECT link_id, count(link_id)
FROM click
WHERE ts BETWEEN ? AND ?
AND ip = ?
GROUP BY link_id
SQL

sub run_query {
    my ( $class, $sql, $start, $end, $ip ) = @_;

    die unless $sql && $start && $end;
    unless ( $start->isa('DateTime') && $end->isa('DateTime') ) {
        croak('No start and end times passed!');
    }
    my $dbh = SL::Model->db_Main();
    my $sth = $dbh->prepare_cached($sql);

    #$DB::single = 1;
    $sth->bind_param( 1, DateTime::Format::Pg->format_datetime($start) );
    $sth->bind_param( 2, DateTime::Format::Pg->format_datetime($end) );
    $sth->bind_param( 3, $ip ) if $ip;
    my $rv      = $sth->execute;
    my $ary_ref = $sth->fetchall_arrayref;
    return $ary_ref;
}

sub views {
    my ( $class, $start, $end ) = @_;
    return $class->run_query( $view_sql, $start, $end );
}

sub links {
    my ( $class, $start, $end ) = @_;
    return $class->run_query( $links_clicked, $start, $end );
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
sub ip_links {
    my ( $class, $start, $end, $ip ) = @_;
    return $class->run_query( $links_clicked_ip, $start, $end, $ip );
}

sub ip_count_links {
    my ( $class, $start, $end, $ip ) = @_;
    return $class->run_query( $ip_count_links, $start, $end, $ip );
}

sub interval_by_ts {
    my ( $class, $ts ) = @_;

    unless (
        ( ref $ts->{'start'} && UNIVERSAL::isa( $ts->{'start'}, 'DateTime' ) )
        && ( ref $ts->{'end'} && UNIVERSAL::isa( $ts->{'end'}, 'DateTime' ) ) )
    {
        croak('No start and end times passed!');
    }

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
                print "FOO";
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
    my $ad_clicks_ref = SL::Model::Report->ip_links( $start_date, $now, $ip );
    use Text::Wrap;
    $Text::Wrap::columns = 25;
    my @ad_clicks_data;
    my $max_ad_clicks = 0;
    foreach my $ref ( sort { $a->[1] <=> $b->[1] } @{$ad_clicks_ref} ) {

        if ( length( $ref->[0] ) > 25 ) {
            $ref->[0] = wrap( "", "", $ref->[0] );
        }
        unshift @{ $ad_clicks_data[0] }, $ref->[0];
        unshift @{ $ad_clicks_data[1] }, $ref->[1];
        if ( $ref->[1] > $max_ad_clicks ) {
            $max_ad_clicks = $ref->[1];
        }
    }
    return ( $max_ad_clicks, \@ad_clicks_data );
}

sub data_daily_ip {
    my ( $class, $ip ) = @_;

    my (
        $max_view_results, @view_results,   $max_click_results,
        @click_results,    $max_click_rate, @click_rates
    );
    $max_view_results = $max_click_results = $max_click_rate = 0;

    my $now = DateTime->now( time_zone => 'local' );
    $now->truncate( to => 'hour' );

    for ( 0 .. 23 ) {
        my $previous = $now->clone->subtract( hours => 1 );
        my $views_count =
          SL::Model::Report->ip_count_views( $previous, $now, $ip );
        unshift @{ $view_results[0] }, $now->strftime("%l %p");
        unshift @{ $view_results[1] }, $views_count->[0]->[0];
        if ( $views_count->[0]->[0] > $max_view_results ) {
            $max_view_results = $views_count->[0]->[0];
        }

        my $clicks_count =
          SL::Model::Report->ip_count_links( $previous, $now, $ip );
        unshift @{ $click_results[0] }, $now->strftime("%l %p");
        unshift @{ $click_results[1] }, $clicks_count->[0]->[0];
        if ( $clicks_count->[0]->[0] > $max_click_results ) {
            $max_click_results = $clicks_count->[0]->[0];
        }

        unshift @{ $click_rates[0] }, $now->strftime("%l %p");
        my $click_rate;
        if ( $views_count->[0]->[0] == 0 ) {
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

1;

package SL::CS::Model::Report;

use strict;
use warnings;

use Carp qw/croak/;
use DateTime::Format::Pg;
use DBD::Pg qw(:pg_types);
use SL::CS::Model;

my $ad_sql = <<SQL;
SELECT ad.ad_id, ad.name
FROM ad
SQL

my $link_sql = <<SQL;
SELECT link.link_id, link.uri
FROM link
WHERE link.ad_id = ?
SQL

my $click_sql = <<SQL;
SELECT click.click_id, click.ts
FROM click
INNER JOIN link
USING(link_id)
WHERE link_id = ? AND
click.ts BETWEEN ? AND ?
SQL

# Most active ips
my $view_sql = <<SQL;
SELECT reg.email, count(ip) FROM view
LEFT JOIN reg USING (ip)
WHERE view.ts between ? and ?
GROUP BY reg.email
ORDER BY count(ip) DESC
SQL

# what links were clicked
my $links_clicked = <<SQL;
SELECT ad.name, count(link_id) from click
left join link
 using (link_id)
 left join ad using (ad_id)
WHERE ts BETWEEN ? AND ?
 GROUP BY ad.name
 ORDER BY count(link_id) DESC
SQL

sub run_query {
	my ($class, $sql, $start, $end) = @_;

	die unless $sql && $start && $end;
    unless 
        ( $start->isa('DateTime') && $end->isa('DateTime'))
    {
        croak('No start and end times passed!');
    }
	my $dbh = SL::CS::Model->db_Main();
	my $sth = $dbh->prepare_cached($sql);
	$sth->bind_param(1, DateTime::Format::Pg->format_datetime($start));
	$sth->bind_param(2, DateTime::Format::Pg->format_datetime($end));
	my $rv = $sth->execute;
	my $ary_ref = $sth->fetchall_arrayref;
	return $ary_ref;
}

sub views {
	my ($class, $start, $end) = @_;
	return $class->run_query($view_sql, $start, $end);
}

sub links {
	my ($class, $start, $end) = @_;
	return $class->run_query($links_clicked, $start, $end);
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
    my $dbh = SL::CS::Model->db_Main();

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

1;

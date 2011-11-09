package SL::Search::CityGrid;

use strict;
use warnings;

use WebService::CityGrid::Ads::Custom ();
use Config::SL;
use Time::HiRes;

our $Config = Config::SL->new;

use constant CITYGRID_MAX_RATE => 2;    # queries per second

our $Cg = WebService::CityGrid::Ads::Custom->new(
    publisher => $Config->sl_citygrid_publisher,
);

sub search {
    my ( $class, $q, $last, $zip ) = @_;

    # last citygrid search time
    if ( Time::HiRes::tv_interval( $last, [Time::HiRes::gettimeofday] ) >
        ( 1 / CITYGRID_MAX_RATE ) )
    {

        my @citygrid_results;
        my $cg_query = eval {
            $Cg->query(
                {
                    where => $zip,
                    what  => URI::Escape::uri_escape($q),
                }
            );
        };
        die $@ if $@;

        $last = [Time::HiRes::gettimeofday];

        # mark the last search time
        my $i = 0;
        foreach my $cg_result ( @{$cg_query} ) {
            next unless $cg_result->neighborhood;
            last if ++$i == 4;

            if ( $i == 1 ) {
                $cg_result->top_hit(1);
            }
            push @citygrid_results, $cg_result;
        }

        # and return
        return ( \@citygrid_results, $last );

    }    # end result search
    else {
        return;
    }

}

1;

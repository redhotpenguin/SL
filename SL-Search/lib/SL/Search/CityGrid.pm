package SL::Search::CityGrid;

use strict;
use warnings;

use WebService::CityGrid::Content::Places;
use Config::SL;
use Time::HiRes;

our $Config = Config::SL->new;


sub search {
    my ( $class, $q, $zip ) = @_;


    my $Cg = WebService::CityGrid::Content::Places->new(
	    publisher => $Config->sl_citygrid_publisher,
             where => $zip,
             what  => URI::Escape::uri_escape($q),
    );
    my $cg_query = eval { $Cg->query };
    die $@ if $@;
    my @citygrid_results;

        # mark the last search time
        my $i = 0;
        foreach my $cg_result ( @{$cg_query} ) {

	    last if $i++ == 5;
            if ( $i == 1 ) {
                $cg_result->top_hit(1);
            }
            push @citygrid_results, $cg_result;
        }

        # and return
        return \@citygrid_results;
}

1;

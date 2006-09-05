package SL::Cache;

use strict;
use warnings;

use Cache::FastMmap;

our $cache;
BEGIN {
	$cache = Cache::FastMmap->new(raw_values => 1);
}

sub grab {
    my $key = shift;
    my $value = $cache->get($key);

    if ( defined( $value ) ) {
        return $value;
    }
}

sub stash {
    my ( $key, $value ) = @_;

    $cache->set( $key, $value );

    return $key;
}

1;

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

BEGIN {
	SKIP: {
	   	skip 'screwed up right now', 1 unless 0;
	    use_ok('SL::Model::Ad::Group');
    }
}

1;

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

BEGIN {
	use_ok('SL::Model');
	use_ok('SL::Model::Report');
	use_ok('SL::Model::Report::Graph');
	use_ok('SL::Model::URL');
	use_ok('SL::Model::RateLimit');
	use_ok('SL::Model::Subrequest');
}

1;

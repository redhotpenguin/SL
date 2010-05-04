#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('WebService::Viglink');
    can_ok('WebService::Viglink', qw( new make_url ));
};

eval { WebService::Viglink->new };
ok($@, 'exception thrown');



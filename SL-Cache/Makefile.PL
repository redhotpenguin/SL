#!/usr/bin/env/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Cache',
    VERSION   => '0.10',
    PREREQ_PM => {
        'Cache::FastMmap' => 1.14,
        'SL::Config'      => 0.10,
    },
    ABSTRACT => 'Caching abstraction for SL',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

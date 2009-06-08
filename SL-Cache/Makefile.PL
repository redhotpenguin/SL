#!/usr/bin/env/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Cache',
    VERSION_FROM => 'lib/SL/Cache.pm',
    PREREQ_PM    => {
        'Cache::FastMmap'  => 1.14,
        'SL::Config'       => 0.14,
        'Cache::Memcached' => 1.26,
    },
    ABSTRACT => 'Caching abstraction for SL',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

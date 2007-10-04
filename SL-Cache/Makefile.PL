#!/usr/bin/env/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Cache',
    VERSION_FROM   => 'lib/SL/Cache.pm',
    PREREQ_PM => {
        'HTML::TokeParser' => 2.37,
        'String::Strip'    => 1.01,
        'Cache::FastMmap'  => 1.14,
        'SL::Config'       => 0.10,
        'SL::Static'       => 0.10,
    },
    ABSTRACT => 'Caching abstraction for SL',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

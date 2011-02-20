#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Proxy',
    VERSION_FROM   => 'lib/SL/Proxy.pm',
    PREREQ_PM => {
        'Compress::Zlib'     => 2.007,
        'Compress::Bzip2'    => 2.09,
        'RHP::Timer'         => 0.1,
        'Config::SL'         => 0.01,
    },
    ABSTRACT  => 'A mod_perl caching forward proxy',
    AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
);

1;

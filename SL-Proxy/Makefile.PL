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
        'SL::Proxy::Cache'   => 0.02,
        'Config::SL'         => 0.01,
        'SL::HTTP::Client'   => 0.03,
        'SL::DNS'            => 0.04,
    },
    ABSTRACT  => 'A mod_perl caching forward proxy',
    AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
);

1;

#!/usr/local/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Proxy-Cache',
    VERSION_FROM => 'lib/SL/Proxy/Cache.pm',
    PREREQ_PM    => {
        'SL::Config'       => 0.14,
        'Cache::Memcached' => 1.28,
    },
    ABSTRACT => 'Caching abstraction for SL-Proxy',
    AUTHOR   => 'Fred Moyer <fred@slwifi.com>',
);

1;

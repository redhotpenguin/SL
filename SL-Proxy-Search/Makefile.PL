#!/usr/local/bin/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Proxy-Search',
    VERSION   => '0.01',
    PREREQ_PM => {
        'Compress::Zlib'     => 2.007,
        'Template'           => 2.18,
        'Sys::Load'          => 0.2,
        'SL::BrowserUtil'    => 0.03,
        'SL::Config'         => 0.15,
        'SL::HTTP::Client'   => 0.03,
        'SL::DNS'            => 0.02,
        'RHP::Timer'         => 0.1,
    },
    EXE_FILES => [qw( bin/sl_proxy bin/sl_perlbal_watch )],
    ABSTRACT  => 'Proxy search requests',
    AUTHOR    => 'Fred Moyer <fred@slwifi.com>',
);
1;

#!/usr/local/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Proxy-Search',
    VERSION_FROM => 'lib/SL/Proxy/Search.pm',
    PREREQ_PM => {
        'Compress::Zlib'     => 2.007,
        'Template'           => 2.18,
        'SL::BrowserUtil'    => 0.03,
        'SL::Config'         => 0.15,
        'SL::HTTP::Client'   => 0.03,
        'SL::DNS'            => 0.02,
        'SL::Static'         => 0.14,  
        'RHP::Timer'         => 0.1,
    },
    EXE_FILES => [qw( bin/sl_proxy bin/sl_perlbal_watch bin/sl_httpd_watch )],
    ABSTRACT  => 'Proxy search requests',
    AUTHOR    => 'Fred Moyer <fred@slwifi.com>',
);

1;

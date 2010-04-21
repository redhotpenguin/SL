#!/usr/local/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Proxy-Search',
    VERSION   => '0.02',
    PREREQ_PM => {
        'Google::Search'     => 0.024,
        'HTML::Template'     => 2.9,
        'Template'           => 2.18,
        'SL::Config'         => 0.17,
        'SL::DNS'            => 0.04,
        'SL::Static'         => 0.14,
        'SL::Proxy'          => 0.01,
        'RHP::Timer'         => 0.1,
    },
    EXE_FILES => [qw( bin/sl_proxy bin/sl_perlbal_watch bin/sl_httpd_watch )],
    ABSTRACT  => 'Proxy search requests',
    AUTHOR    => 'Fred Moyer <fred@slwifi.com>',
);

1;

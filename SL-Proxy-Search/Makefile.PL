#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'SL-Proxy-Search',
    VERSION_FROM   => 'lib/SL/Proxy/Search.pm',
    PREREQ_PM => {
        'Template'            => 2.18,
        'SL::Config'          => 0.17,
        'SL::DNS'             => 0.04,
        'SL::Static'          => 0.14,
        'SL::Proxy'           => 0.01,
        'SL::BrowserUtil'     => 0.03,
        'RHP::Timer'          => 0.1,
	'Apache2::Connection::XForwardedFor' => 0.02,
	'Apache2::Connection::SkipDummy'     => 0.01,
    },
    EXE_FILES => [qw( bin/sl_proxy bin/sl_perlbal_watch bin/sl_httpd_watch bin/sl_iptables )],
    ABSTRACT  => 'Proxy search requests',
    AUTHOR    => 'Fred Moyer <fred@slwifi.com>',
);

1;

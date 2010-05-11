#!/usr/local/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Apache2-Search',
    VERSION_FROM => 'lib/SL/Apache2/Search.pm',
    PREREQ_PM    => {
        'Apache2::Connection::XForwardedFor' => 0.01,
        'WebService::VigLink'                => 0.05,
        'Google::Search'                     => 0.025,
        'HTML::Template'                     => 2.9,
        'SL::Config'                         => 0.17,
        'SL::BrowserUtil'                    => 0.03,
        'RHP::Timer'                         => 0.1,
    },
    ABSTRACT => 'Handle search requests',
    AUTHOR   => 'Fred Moyer <fred@slwifi.com>',
);

1;

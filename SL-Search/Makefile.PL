#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Search',
    VERSION_FROM => 'lib/SL/Search.pm',
    PREREQ_PM    => {
        'Config::SL'                         => 0.01,
        'Encode::Guess'                      => 0,
        'Mouse'                              => 0,
        'Google::Search'                     => 0.0025,
        'Digest::MD5'                        => 0,
        'WebService::CityGrid::Search'       => 0.02,
        'Apache2::Connection::XForwardedFor' => 0.02,
        'Template'                           => 0.01,
    },
    ABSTRACT_FROM => 'lib/SL/Search.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>'
);

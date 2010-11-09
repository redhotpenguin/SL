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
        'Google::Search'                     => 0.0027,
        'Digest::MD5'                        => 0,
        'WebService::CityGrid::Search'       => 0.02,
        'Apache2::Connection::XForwardedFor' => 0.02,
        'WebService::Yahoo::BOSS'            => 0.01,
        'SL::Model'                          => 0.21,
    },
    ABSTRACT_FROM => 'lib/SL/Search.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>'
);

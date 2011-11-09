#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Search',
    VERSION_FROM => 'lib/SL/Search.pm',
    PREREQ_PM    => {
        'RHP::Timer'                         => 0.01,
        'Config::SL'                         => 0.01,
        'Encode::Guess'                      => 0,
        'Mouse'                              => 0,
        'Apache::DBI'                        => 0,
        'Google::Search'                     => 0.0027,
        'Digest::MD5'                        => 0,
        'Apache2::Connection::XForwardedFor' => 0.02,
        'WebService::Yahoo::BOSS'            => 0.01,
        'WebService::CityGrid::Ads::Custom'  => 0.01,
        'SL::Model'                          => 0.21,
        'Crypt::CBC'                         => 0,
        'Crypt::Blowfish'                    => 0,
    },
    EXE_FILES     => [ 'bin/startup.pl', 'bin/sl_search' ],
    ABSTRACT_FROM => 'lib/SL/Search.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>'
);

#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService::CityGrid::Search',
    VERSION_FROM  => 'lib/WebService/CityGrid/Search.pm',
    PREREQ_PM     => { 'Any::Moose' => 0, 'Any::URI::Escape' => 0 },
    ABSTRACT_FROM => 'lib/WebService/CityGrid/Search.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>'
);

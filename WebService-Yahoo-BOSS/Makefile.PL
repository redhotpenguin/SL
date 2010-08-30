#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::Yahoo::BOSS',
    VERSION_FROM => 'lib/WebService/Yahoo/BOSS.pm',
    PREREQ_PM    => {
        'Any::Moose'       => 0,
        'Any::URI::Escape' => 0,
        'XML::LibXML'      => 1.70
    },
    ABSTRACT_FROM => 'lib/WebService/Yahoo/BOSS.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>'
);

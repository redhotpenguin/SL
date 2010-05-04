#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WebService::Viglink',
    VERSION_FROM      => 'lib/WebService/Viglink.pm',
    PREREQ_PM         => {'URI::Escape' => 0},
    ABSTRACT_FROM  => 'lib/WebService/Viglink.pm',
    AUTHOR         => 'Fred Moyer <fred@slwifi.com>',
);

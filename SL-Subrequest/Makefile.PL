#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL::Subrequest',
    VERSION_FROM => 'lib/SL/Subrequest.pm',
    PREREQ_PM    => {
        'HTML::TokeParser' => 2.37,
        'SL::Static'       => 0.12,
        'SL::Cache'        => 0.23,
        'SL::Config'       => 0.14,
        'String::Strip'    => 1.01,
    },
    ABSTRACT => 'extracts and replaces http subrequests',
    AUTHOR   => 'Fred Moyer <phred@redhotpenguin.com>'
);

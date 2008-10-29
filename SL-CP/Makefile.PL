#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-CP',
    VERSION_FROM => 'lib/SL/CP.pm',
    PREREQ_PM    => {
        'SL::Config'     => 0.16,
        'Template'       => 2.18,
        'LWP::UserAgent' => 2.33,
    },
    ABSTRACT_FROM => 'lib/SL/CP.pm',
    AUTHOR        => 'Fred Moyer <fred@silverliningnetworks.com>',

);

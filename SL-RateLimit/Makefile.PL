#!perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL::RateLimit',
    VERSION_FROM => 'lib/SL/RateLimit.pm',    # finds $VERSION
    PREREQ_PM    => {
        'SL::Cache'  => 0.23,
        'SL::Config' => 0.14
    },
    ABSTRACT => 'makes sure we do not serve ads too fast',
    AUTHOR   => 'Fred Moyer <phred@redhotpenguin.com>',
);

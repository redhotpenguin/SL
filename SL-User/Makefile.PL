#!perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL::User',
    VERSION_FROM => 'lib/SL/User.pm',
    PREREQ_PM    => {
        'SL::Cache'  => 0.23,
        'SL::Config' => 0.14,
    },
    ABSTRACT => 'handles users of silver lining',
    AUTHOR   => 'Fred Moyer <phred@redhotpenguin.com>',
);

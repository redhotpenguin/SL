#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'SL::ProxyServer',
    VERSION_FROM   => 'lib/SL/Apache.pm',
    PREREQ_PM      => {
        'Cache::FastMmap' => 1.09,
        'Text::Template' => 1.44,
        'Bundle::LWP' => 1.11,
        'Regexp::Assemble' => 0.24,
    },
    ABSTRACT_FROM  => 'README',
    AUTHOR         => 'Fred Moyer <fred@redhotpenguin.com>',
);

use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# generate the test harness (t/TEST)
Apache::TestRunPerl->generate_script();

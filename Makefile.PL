#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL',
              VERSION   => '0.6',
              PREREQ_PM => {
                            'Apache::DBI'          => 0.9901,
                            'Cache::FastMmap'      => 1.09,
                            'Config::ApacheFormat' => 1.2,
                            'DBI'                  => 1.50,
                            'DBD::Pg'              => 1.48,
                            'Text::Template'       => 1.44,
                            'Bundle::LWP'          => 1.11,
                            'Template'             => 2.14,
                            'Regexp::Assemble'     => 0.24,
                            'Perl6::Slurp'         => 0.03,
                           },
              ABSTRACT => 'An ad serving proxy server',
              AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
             );

use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# generate the test harness (t/TEST)
Apache::TestRunPerl->generate_script();

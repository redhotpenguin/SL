#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL',
              VERSION   => '0.6',
              PREREQ_PM => {
                            'Apache::DBI'          => 0.9901,
                            'Cache::FastMmap'      => 1.14,
                            'Class::DBI::Pg'       => 0.09,
                            'Config::ApacheFormat' => 1.2,
                            'Crypt::Blowfish'      => 2.10,
                            'Crypt::CBC'           => 2.22,
                            'Data::FormValidator'  => 4.40,
                            'DBI'                  => 1.50,
                            'DBIx::Class'          => 0.7001,
                            'DBIx::Class::Schema::Loader' => 0.3007,
                            'DBD::Pg'              => 1.48,
                            'LWP'                  => 5.805,
                            'Text::Template'       => 1.44,
                            'Bundle::LWP'          => 1.11,
                            'Template'             => 2.14,
                            'Regexp::Assemble'     => 0.24,
                            'SOAP::Lite'           => 0.69,
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

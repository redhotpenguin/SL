#!/usr/bin/env/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL',
              VERSION   => '0.12',
              PREREQ_PM => {
                            'Apache::DBI'          => 1.06,
                            'Cache::FastMmap'      => 1.14,
                            'Config::ApacheFormat' => 1.2,
                            'Compress::Zlib'       => 2.007,
                            'Crypt::CBC'           => 2.22,
                            'Digest::SHA1'         => 2.11,
                            'LWP'                  => 5.805,
                            'Template'             => 2.14,
                            'Regexp::Assemble'     => 0.24,
                            'Sys::Load'            => 0.2,
                            'SL::Cache'            => 0.19,
                            'SL::Config'           => 0.13,
                            'SL::Model'            => 0.12,
                            'SL::UserAgent'        => 0.1,
                            'SL::HTTP::Request'    => 0.1,
                            'RHP::Timer'           => 0.1,
                           },
              EXE_FILES => [qw( bin/sl_proxy )],
              ABSTRACT  => 'An ad serving proxy server',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );
1;

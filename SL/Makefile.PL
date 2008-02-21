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
                            'Compress::Bzip2'      => 2.09,
                            'Crypt::Blowfish_PP'   => 1.12,
                            'Crypt::CBC'           => 2.22,
                            'Digest::SHA1'         => 2.11,
                            'LWP'                  => 5.805,
                            'Template'             => 2.14,
                            'Regexp::Assemble'     => 0.24,
                            'Sys::Load'            => 0.2,
                            'SL::BrowserUtil'      => 0.02,
                            'SL::Cache'            => 0.21,
                            'SL::Config'           => 0.14,
                            'SL::Model'            => 0.14,
                            'RHP::Timer'           => 0.1,
                           },
              EXE_FILES => [qw( bin/sl_proxy )],
              ABSTRACT  => 'An ad serving proxy server',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );
1;

#!/usr/bin/env/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL',
              VERSION   => '0.8',
              PREREQ_PM => {
                            'Apache::DBI'          => 1.06,
                            'Cache::FastMmap'      => 1.14,
                            'Config::ApacheFormat' => 1.2,
                            'Crypt::CBC'           => 2.22,
                            'Data::FormValidator'  => 4.40,
                            'Digest::SHA1'         => 2.11,
                            'LWP'                  => 5.805,
                            'Template'             => 2.14,
                            'Regexp::Assemble'     => 0.24,
                            'Sys::Load'            => 0.2,
                            'SL::Model'            => 0.1,
                            'SL::UserAgent'        => 0.1,
                            'SL::HTTP::Request'    => 0.1,
                            'RHP::Timer'           => 0.1,
                           },
              EXE_FILES => [qw( bin/sl_proxy bin/sl_app )],
              ABSTRACT  => 'An ad serving proxy server',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );
1;

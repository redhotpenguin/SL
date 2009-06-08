#!/usr/bin/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL',
              VERSION   => '0.14',
              PREREQ_PM => {
                            'Apache::DBI'          => 1.06,
                            'Cache::FastMmap'      => 1.14,
                            'Compress::Zlib'       => 2.007,
                            'Compress::Bzip2'      => 2.09,
                            'Crypt::Blowfish_PP'   => 1.12,
                            'Crypt::CBC'           => 2.30,
                            'Digest::SHA1'         => 2.12,
                            'Template'             => 2.14,
			    'Net::DNS'             => 0.64,
                            'Sys::Load'            => 0.2,
                            'SL::BrowserUtil'      => 0.02,
                            'SL::Cache'            => 0.21,
                            'SL::RateLimit'        => 0.01,
                            'SL::Subrequest'       => 0.02,
                            'SL::Config'           => 0.15,
                            'SL::Context'          => 0.03,
                            'SL::HTTP::Client'     => 0.02,
                            'SL::Static'           => 0.12,
                            'SL::Model'            => 0.14,
                            'SL::User'             => 0.02,
                            'RHP::Timer'           => 0.1,
                           },
              EXE_FILES => [qw( bin/sl_proxy bin/sl_perlbal_watch )],
              ABSTRACT  => 'An ad serving proxy server',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );
1;

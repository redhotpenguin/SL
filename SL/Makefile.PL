#!/usr/bin/env/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL',
              VERSION   => '0.7',
              PREREQ_PM => {
                            'Apache::DBI'          => 1.06,
                            'Cache::FastMmap'      => 1.14,
                            'Config::ApacheFormat' => 1.2,
                            'Crypt::CBC'           => 2.22,
                            'Data::FormValidator'  => 4.40,
                            'Digest::SHA1'         => 2.11,
							'DBI'                  => 1.55,
                            'DBIx::Class'          => 0.07001,
                            'DBIx::Class::Schema::Loader' => 0.03007,
                            'DBD::Pg'              => 1.49,
                            'LWP'                  => 5.805,
                            'Params::Validate'     => 0.76,
							'Text::Template'       => 1.44,
                            'Template'             => 2.14,
                            'Regexp::Assemble'     => 0.24,
                            'SOAP::Lite'           => 0.69,
                            'Sys::Load'            => 0.2,   
						},
			  EXE_FILES => [ qw( bin/sl_proxy bin/sl_app ) ],
              ABSTRACT => 'An ad serving proxy server',
              AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
             );

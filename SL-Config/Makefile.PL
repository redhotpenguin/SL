#!/usr/bin/env/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL-Config',
              VERSION   => '0.10',
              PREREQ_PM => {
                            'Config::ApacheFormat' => 1.2,
                           },
              ABSTRACT  => 'Configuration abstraction for SL libraries',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );
1;

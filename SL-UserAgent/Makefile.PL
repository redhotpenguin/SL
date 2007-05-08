#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL::UserAgent',
              VERSION   => '0.1',
              PREREQ_PM => {'LWP::UserAgent' => 2.033},
              ABSTRACT  => 'SL specific user agent',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );

1;

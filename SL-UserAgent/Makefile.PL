#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL::UserAgent',
              VERSION_FROM   => 'lib/SL/UserAgent.pm',
              PREREQ_PM => {'LWP::UserAgent' => 2.033},
              ABSTRACT  => 'SL specific user agent',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );

1;

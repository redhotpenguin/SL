#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL::HTTP',
              VERSION   => '0.1',
              PREREQ_PM => {'Net::HTTP' => 1.00,},
              ABSTRACT  => 'SL specific http abstractions',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );

1;

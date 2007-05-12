#!/usr/bin/env perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL::HTTP::Request',
              VERSION   => '0.1',
              PREREQ_PM => {'Net::HTTP' => 1.00,},
              ABSTRACT  => 'SL specific http request',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );

1;

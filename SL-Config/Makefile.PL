#!/usr/bin/perl:

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Config',
    VERSION_FROM => 'lib/SL/Config.pm',
    PREREQ_PM    => { 'Config::ApacheFormat' => 1.2, },
    ABSTRACT     => 'Configuration abstraction for SL libraries',
    AUTHOR       => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

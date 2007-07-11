#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Static',
    VERSION_FROM => 'lib/SL/Static.pm',
    PREREQ_PM    => { 'Regexp::Assemble' => 0.31, },
    ABSTRACT     => 'Regexes for static content and friends',
    AUTHOR       => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

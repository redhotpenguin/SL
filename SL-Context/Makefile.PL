#!perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL::Context',
    VERSION_FROM => 'lib/SL/Context.pm',
    PREREQ_PM    => { 'HTML::TokeParser' => 2.37, },
    ABSTRACT     => 'happy fun keywords',
    AUTHOR       => 'Fred Moyer <phred@redhotpenguin.com>',
);

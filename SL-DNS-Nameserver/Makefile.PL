#!/usr/bin/env perl

use strict;
use warnings;
use 5.014001;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SL-DNS-Nameserver',
    VERSION_FROM => 'lib/SL/DNS/Nameserver.pm',
    PREREQ_PM    => { 'Config::SL' => 0 },
    ABSTRACT     => 'SL Nameserver',
    AUTHOR       => 'Fred Moyer <phred@redhotpenguin.com>',
);

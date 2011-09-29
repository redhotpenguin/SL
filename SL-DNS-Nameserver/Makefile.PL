#!/usr/bin/perl

use strict;
use warnings;
use 5.010001;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SL-DNS-Nameserver',
    VERSION_FROM => 'lib/SL/DNS/Nameserver.pm',
    PREREQ_PM =>
      { 'Config::SL' => 0.01, 'Net::DNS' => 0.66, 'Cache::Memcached' => 1.28, 'Time::HiRes' => 0 },
    EXE_FILES => ['bin/sl_nameserver'],
    ABSTRACT  => 'SL Nameserver',
    AUTHOR    => 'Fred Moyer <phred@redhotpenguin.com>',
);

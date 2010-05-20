#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Search',
    VERSION_FROM => 'lib/SL/Search.pm',
    PREREQ_PM    => {
        'Encode::Guess'       => 0,
        'Mouse'               => 0,
        'Google::Search'      => 0.0025,
        'Digest::MD5'         => 0,
        'WebService::VigLink' => 0.06,
    },
    ABSTRACT_FROM => 'lib/SL/Search.pm',
    AUTHOR        => 'Fred Moyer <phred@redhotpenguin.com>'
);

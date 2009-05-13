#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-CP',
    VERSION_FROM => 'lib/SL/CP.pm',
    PREREQ_PM    => {
	'SL::BrowserUtil' => 0.03,
    	'SL::Config'     => 0.16,
        'Template'       => 2.18,
        'LWP::UserAgent' => 2.33,
	'Crypt::SSLeay'  => 0.57,
    },
    ABSTRACT      => 'Silver Lining Captive Portal',
    AUTHOR        => 'Fred Moyer <fred@silverliningnetworks.com>',

);

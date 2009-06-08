#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-HTTP-Client',
    VERSION_FROM => 'lib/SL/HTTP/Client.pm',
    PREREQ_PM    => {
		URI => 1.38, 
		'SL::Config' 	       => 0.14,
                'LWP::UserAgent'       => 5.826,
 	},
    ABSTRACT => 'Silver Lining HTTP Proxy Client',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);

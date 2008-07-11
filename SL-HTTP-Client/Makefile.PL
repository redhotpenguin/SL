#!perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-HTTP-Client',
    VERSION_FROM => 'lib/SL/HTTP/Client.pm',
    PREREQ_PM    => { URI => 1.35, 'Net::HTTP' => 1.0, 'SL::Config' => 0.14 },
    ABSTRACT => 'a proxy http client',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);

use 5.008008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-Map',
    VERSION_FROM => 'lib/SL/Map.pm',
    PREREQ_PM    => {
        'HTML::GoogleMaps' => 0,
        'SL::Model'        => 0,
    },
    ABSTRACT => 'Handles map functions',
    AUTHOR   => 'Fred Moyer <phred@redhotpenguin.com>',
);

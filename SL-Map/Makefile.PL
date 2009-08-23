use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'SL-Map',
    VERSION_FROM  => 'lib/SL/Map.pm', 
    PREREQ_PM     => { HTML::GoogleMaps => 0,
                       SL::Model => 0,},
    ABSTRACT_FROM => 'lib/SL/Map.pm',
    AUTHOR => 'Fred Moyer <phred@redhotpenguin.com>',
);

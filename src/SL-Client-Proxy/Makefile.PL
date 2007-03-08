# generated via h2xs -X
use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL::Client',
    VERSION_FROM => 'lib/SL/Client.pm',
    PREREQ_PM    => { Regexp::Assemble => 0.25 },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/SL/Client.pm', # retrieve abstract from module
            AUTHOR => 'Fred Moyer <phred@redhotpenguin.com>'
          )
        : ()
    ),
);

use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SL-Openx',
    VERSION_FROM      => 'lib/SL-Openx.pm', # finds $VERSION
    PREREQ_PM         => {'XML::Feed' => 0.41,
                          'XML::RPC' => 0.9,
                          }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SL-Openx.pm', # retrieve abstract from module
       AUTHOR         => 'Fred Moyer <phred@redhotpenguin.com>') : ()),
);

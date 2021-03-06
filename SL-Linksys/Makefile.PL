use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SL-Linksys',
    VERSION           => '0.19',
    PREREQ_PM         => { CGI => '1.0'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Silver Lining linksys client software',
       AUTHOR         => 'Fred Moyer <fred@redhotpenguin.com>') : ()),
);

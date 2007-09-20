use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SL-Page-Cache',
    VERSION_FROM      => 'lib/SL/Page/Cache.pm', # finds $VERSION
    PREREQ_PM         => { MogileFS::Client => 1.08, }, 
    ABSTRACT         => 'web page storage wrapper over mogilefs',
    AUTHOR         => 'Fred Moyer <phred@redhotpenguin.com>',
);

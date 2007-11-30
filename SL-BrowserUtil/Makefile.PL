use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SL-BrowserUtil',
    VERSION_FROM => 'lib/SL/BrowserUtil.pm',    # finds $VERSION
    PREREQ_PM    => {},                         # e.g., Module::Name => 1.1
    ABSTRACT     => 'Browser or not?',
    AUTHOR => 'Fred Moyer <phred@redhotpenguin.com>',
);

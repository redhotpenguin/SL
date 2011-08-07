use 5.012002;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Apache2::Proxy',
    VERSION_FROM => 'lib/Apache2/Proxy.pm',    # finds $VERSION
    PREREQ_PM     => { 'Compress::Zlib' => 0, 'Compress::Bzip2' => 0, },
    ABSTRACT_FROM => 'lib/Apache2/Proxy.pm',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>',
);

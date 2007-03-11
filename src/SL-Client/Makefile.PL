use 5.008005;
use strict;
use warnings FATAL => 'all';

use Apache::TestMM ();
Apache::TestMM->import(qw(test clean));
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

use ModPerl::MM;
ModPerl::MM::WriteMakefile(
    NAME          => 'SL::Client',
    VERSION_FROM  => 'lib/SL/Client.pm',
    PREREQ_PM => {
                  'Cache::FastMmap' => 1.14,
    },
    ABSTRACT_FROM => 'lib/SL/Client.pm',
    AUTHOR => 'Fred Moyer <phred@redhotpenguin.com>',
);

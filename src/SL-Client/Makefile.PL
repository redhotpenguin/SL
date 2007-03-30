use 5.008005;
use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'SL::Client',
    VERSION_FROM  => 'lib/SL/Client.pm',
    PREREQ_PM => {
                  'Cache::FastMmap'  => 1.14,
                  'LWP::UserAgent'   => 2.033,
				  'Params::Validate' => 0.88,
    },
    ABSTRACT_FROM => 'lib/SL/Client.pm',
    EXE_FILES     => ['bin/sl_proxy_ping', 'bin/sl_config_update', 
	    'bin/sl_fw_ha', 'bin/sl_maintd'],
    AUTHOR => 'Fred Moyer <phred@redhotpenguin.com>',
);

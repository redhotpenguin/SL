use 5.008005;
use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'SL::Client',
    VERSION      => '0.3',
    PREREQ_PM => {
                  'Cache::FastMmap'  => 1.14,
                  'LWP::UserAgent'   => 2.033,
                  'Net::DNS'         => 0,
                  'IPC::Run3'        => 0,
                  'Mail::Mailer'     => 0,
				  'Params::Validate' => 0.88,
    },
    ABSTRACT       => 'SilverLining client libraries and utilities',
    EXE_FILES     => ['bin/sl_tunnel', 'bin/sl_config_update', 
	    'bin/sl_fw_ha', 'bin/sl_maintd'],
    AUTHOR => 'Fred Moyer <phred@redhotpenguin.com>',
);

#!perl:

use strict;
use warnings FATAL => 'all';

use Apache::TestMM;
Apache::TestMM->import(qw(test clean));
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

use ModPerl::MM;
ModPerl::MM::WriteMakefile(
    NAME         => 'SL-App',
    VERSION_FROM => 'lib/SL/Apache/App.pm',
    PREREQ_PM    => {
        'Apache::Reload'      => 0.10,
        'Apache::Dispatch'    => 0.10,
        'Apache::DBI'         => 1.06,
        'Apache::Session'     => 1.83,
        'Crypt::Blowfish'     => 2.10,
        'Crypt::DES'          => 2.05,
        'Data::FormValidator' => 4.50,
        'DBD::Pg'             => 1.49,
        'Digest::MD5'         => 2.33,
        'MIME::Lite'          => 3.01,
        'Template'            => 2.14,
        'SL::Config'          => 0.14,
        'SL::Model'           => 0.16,
    },
    EXE_FILES => [qw( bin/sl_app )],
    ABSTRACT  => 'The Silver Lining web application',
    AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

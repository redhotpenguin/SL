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
        'Apache::DBI'         => 1.06,
        'Apache::Dispatch'    => 0.10_02,
        'Apache::Session'     => 1.83,
        'Crypt::CBC'          => 2.22,
        'Crypt::DES'          => 2.05,
        'Data::FormValidator' => 4.40,
        'DBD::Pg'             => 1.49,
        'Digest::MD5'         => 2.33,
        'MIME::Lite'          => 3.01,
        'Template'            => 2.14,
        'SL::Config'          => 0.11,
        'SL::Cache'           => 0.13,
        'SL::Model'           => 0.07,
    },
    EXE_FILES => [qw( bin/sl_app )],
    ABSTRACT  => 'The Silver Lining web application',
    AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

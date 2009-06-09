#!/usr/bin/perl:

use strict;
use warnings FATAL => 'all';

use Apache::TestMM;
use Apache::TestRunPerl;
Apache::TestMM::filter_args();
Apache::TestRunPerl->generate_script();

use ModPerl::MM;
ModPerl::MM::WriteMakefile(
    NAME         => 'SL-App',
    VERSION_FROM => 'lib/SL/App.pm',
    PREREQ_PM    => {
        'Apache::Reload'             => 0.10,
        'Apache::Dispatch::Util'     => 0.12,
        'Apache::DBI'                => 1.06,
        'Apache::Session'            => 1.83,
        'Crypt::Blowfish'            => 2.10,
        'Crypt::CBC'                 => 2.22,
        'Crypt::DES'                 => 2.05,
        'Data::FormValidator'        => 4.50,
        'DBD::Pg'                    => 1.49,
        'Image::Size'                => 3.2,
        'Digest::MD5'                => 2.33,
        'MIME::Lite'                 => 3.01,
        'Template'                   => 2.14,
        'Template::Plugin::DateTime' => 0.06001,
        'XML::Feed'                  => 0.42,
        'SL::Config'                 => 0.14,
        'SL::Model'                  => 0.20,
        'SL::Payment'                => 0.05,
    },
    EXE_FILES => [qw( bin/sl_app )],
    ABSTRACT  => 'The Silver Lining web application',
    AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

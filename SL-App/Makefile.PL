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
        'Apache2::Dispatch'          => 0.15,
        'Apache2::Request'          => 0.01,
        'Apache::DBI'                => 1.09,
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
        'Template::Plugin::Number::Format' => 0.01,
        'XML::Feed'                  => 0.42,
        'Config::SL'                 => 0.01,
        'SL::Model'                  => 0.20,
        'SL::Payment'                => 0.05,
        'String::Strip'              => 0,
        'Geo::Coder::Google'         => 0,
        'Linux::Pid'                 => 0,
    },
    EXE_FILES => [qw( bin/sl_app )],
    ABSTRACT  => 'The Silver Lining web application',
    AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
);
1;

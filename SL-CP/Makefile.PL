#!/usr/bin/perl

use strict;
use warnings;

use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SL-CP',
    VERSION_FROM => 'lib/SL/CP.pm',
    PREREQ_PM    => {
        'SL::BrowserUtil' => 0.03,
        'SL::Config'      => 0.17,
        'Template'        => 2.18,
        'LWP::UserAgent'  => 5.834,
        'URI::Escape'     => 3.30,
        'Crypt::SSLeay'   => 0.57,
        'Apache2::Connection::XForwardedFor' => 0.01,
        'Apache2::Connection::Arp'           => 0.01,
    },
    EXE_FILES => [qw( bin/sl_cp bin/sl_httpd_watch bin/sl_cp_check
                      bin/sl_cp_bouncer )],
    ABSTRACT      => 'Silver Lining Captive Portal',
    AUTHOR        => 'Fred Moyer <fred@slwifi.com>',

);

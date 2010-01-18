#!/usr/bin/perl

use strict;
use warnings;
use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SL::Model',
    VERSION_FROM => 'lib/SL/Model.pm',
    PREREQ_PM    => {
        'Class::C3'                   => 0.21,
        'Crypt::SSLeay'               => 0.57,
        'DBI'                         => 1.605,
        'GD::Graph'                   => 1.44,
        'DateTime::Format::Pg'        => 0.16003,
        'DBIx::Class'                 => 0.08107,
        'DBIx::Class::Schema::Loader' => 0.041,
        'DBD::Pg'                     => 1.49,
        'Number::Format'              => 1.70,
        'Regexp::Assemble'            => 0.34,
        'URI'                         => 1.38,
        'Text::Wrap'                  => 2005.0824_01,
	'SL::Cache'                   => 0.23,
        'Geo::Distance'               => 0,
    },
    EXE_FILES => [
        qw( bin/sl_mail_user_reports.pl
          bin/sl_report.pl bin/sl_report_graph.pl
          bin/sl_pay.pl bin/sl_network_overview.pl )
    ],
    ABSTRACT => 'The database abstraction layer for SL',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);

use 5.008006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SL::Model',
    VERSION_FROM => 'lib/SL/Model.pm',
    PREREQ_PM    => {
        'Business::PayPal::API'       => 0.61,
        'Crypt::SSLeay'               => 0.57,
        'DBI'                         => 1.605,
        'GD::Graph'                   => 1.44,
        'DateTime::Format::Pg'        => 0.16001,
        'DBIx::Class'                 => 0.08010,
        'DBIx::Class::Schema::Loader' => 0.04005,
        'DBD::Pg'                     => 1.49,
        'Number::Format'              => 1.60,
        'Params::Validate'            => 0.76,
        'Regexp::Assemble'            => 0.34,
        'URI'                         => 1.37,
        'Text::Wrap'                  => 2005.0824_01,
        'Cache::Memcached'            => 1.24,
    },
    EXE_FILES => [
        qw( bin/sl_mail_user_reports.pl
          bin/sl_report.pl bin/sl_report_graph.pl
          bin/sl_close_expire.pl )
    ],
    ABSTRACT => 'The database abstraction layer for SL',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);

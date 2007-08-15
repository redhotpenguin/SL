use 5.008006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SL::Model',
    VERSION_FROM => 'lib/SL/Model.pm',
    PREREQ_PM    => {
        'DBI'                         => 1.50,
        'GD::Graph'                   => 1.44,
        'DateTime::Format::Pg'        => 0.1,
        'DBIx::Class'                 => 0.08003,
        'DBIx::Class::Schema::Loader' => 0.04002,
        'DBD::Pg'                     => 1.49,
        'Number::Format'              => 1.52,
        'Params::Validate'            => 0.76,
        'Regexp::Assemble'            => 0.31,
        'URI'                         => 1.35,
        'SOAP::Lite'                  => 0.69,

    },
    EXE_FILES => [
        qw( bin/sl_mail_global_reports.pl bin/sl_mail_user_reports.pl bin/sl_rate_limit_cleanup.pl bin/sl_report.pl bin/sl_report_graph.pl bin/sl_update_linkshare.pl )
    ],
    ABSTRACT => 'The database abstraction layer for SL',
    AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com>',
);

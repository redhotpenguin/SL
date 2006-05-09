#!perl

my %makefile_params = (
    NAME           => 'SL::ClickServer',
	VERSION		   => 0.5,
	PREREQ_PM      => {
	 'Apache::DBI' => 0.9901,
	 'DBI'		   => 1.50,
	 'DBD::Pg'	   => 1.48,
	},
	ABSTRACT_FROM  => 'README',
	AUTHOR         => 'Fred Moyer <fred@redhotpenguin.com>',
);

use ModPerl::MM;
ModPerl::MM::WriteMakefile(%makefile_params);

use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# generate the test harness (t/TEST)
Apache::TestRunPerl->generate_script();


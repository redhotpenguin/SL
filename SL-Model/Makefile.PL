use 5.008006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              NAME      => 'SL::Model',
              VERSION   => '0.1',
              PREREQ_PM => {'DBI' => 1.50, 
							'GD::Graph' => 1.44,
                            'DBIx::Class'                 => 0.07001,
                            'DBIx::Class::Schema::Loader' => 0.03007,
                            'DBD::Pg'                     => 1.49,
                            'Params::Validate'            => 0.76,
							'URI'                         => 1.35,
			  
			  },
              ABSTRACT  => 'The database abstraction layer for SL',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com',
             );

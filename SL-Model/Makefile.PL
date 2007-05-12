use 5.008006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              NAME      => 'SL::Model',
              VERSION   => '0.1',
              PREREQ_PM => {'DBI' => 1.50, 'GD::Graph' => 1.44},
              ABSTRACT  => 'The database abstraction layer for SL',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com',
             );

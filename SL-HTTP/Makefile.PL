use 5.008006;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME      => 'SL::HTTP',
              VERSION   => '0.1',
              PREREQ_PM => {'Net::HTTP => 1.4', 'LWP::UserAgent' => 2.033},
              ABSTRACT  => 'SL specific http abstractions',
              AUTHOR    => 'Fred Moyer <fred@redhotpenguin.com>',
             );

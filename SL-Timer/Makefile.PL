use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME      => 'SL::Timer',
              VERSION   => '0.1',
              PREREQ_PM => {Time::HiRes => '1.65'},
              (
               ABSTRACT => 'The silverlining timer abstration',
               AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com'
              ),
             );
1;

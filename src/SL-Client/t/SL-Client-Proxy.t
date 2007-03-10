use strict;
use warnings FATAL => 'all';
use Apache::test;
use Apache::TestRequest;
use Test::More tests => 1;

plan tests => 2;

my $res = GET '/image.gif';
ok($res->code == 200); 

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Test::More;

plan tests => 2, \&have_lwp;

my $uri = '/cookies/one_cookie';
my $res = GET $uri;
cmp_ok($res->code, '==', 200, 'returned a 200');
ok($res->headers->header('Set-Cookie') =~ m/sl/);
print STDERR $res->headers->as_string;

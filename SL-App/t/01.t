use strict;
use warnings FATAL => 'all';

use Apache::Test qw(ok plan :withtestmore );
use Apache::TestRequest qw(GET GET_OK);

plan tests => 2, need_lwp;

# Test Apache2::Foo->dispatch_index
my $uri = '/';
ok GET_OK $uri;

# Test Apache2::Foo->dispatch_foo
$uri = '/app';
ok GET_OK $uri;


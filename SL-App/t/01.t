use strict;
use warnings FATAL => 'all';

use Apache::Test qw( :withtestmore );
use Test::More;
use Apache::TestRequest qw(GET GET_OK POST POST_OK);
use Apache::TestUtil;

plan tests => 22, need_lwp;

# Test Apache2::Foo->dispatch_index
my $uri = '/';
ok GET_OK $uri;

# Test Apache2::Foo->dispatch_foo
$uri = '/app';
ok GET_OK $uri;

# now login
$uri = '/login';
ok GET_OK $uri;

my $email = 'phredwolf@yahoo.com';
my $password = 'yomaing420';
my $res = POST $uri, [email => $email, password => $password ];

t_cmp($res->code, 302, '302 on successful post');
like($res->headers->header('Location'), qr{/app$}, 'redirect to /app ok');

# run through all the website links to first make sure we don't get
# any 404s or 500s
my @uris = qw(
              /app/home/index
              /app/settings/index
              /app/ad/index
              /app/report/index

              /app/blacklist/index
              /app/blacklist/edit/?url_id=-1

              /app/router/index
              /app/router/list
              /app/router/edit

              /app/ad/ads/index
              /app/ad/ads/edit
              /app/ad/ads/list

              /app/ad/groups/index
              /app/ad/groups/edit
              /app/ad/groups/list


              /app/ad/bugs/index
              /app/ad/bugs/list
              /app/ad/bugs/edit
);

foreach my $uri ( @uris ) {
 ok  GET_OK $uri;
}

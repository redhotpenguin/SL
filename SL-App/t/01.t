use strict;
use warnings FATAL => 'all';

use Apache::Test qw( :withtestmore );
use Test::More;
use Apache::TestRequest qw(GET GET_OK POST POST_OK);
use Apache::TestUtil;

# don't follow redirects
Apache::TestRequest::user_agent(requests_redirectable => 0, cookie_jar => {});

plan tests => 34, need_lwp;

# Test Apache2::Foo->dispatch_index
my $uri = '/';
ok GET_OK $uri;

# Test Apache2::Foo->dispatch_foo
$uri = '/app/home/index';
my $res = GET $uri;
cmp_ok($res->code, '==', 302);
like($res->header('Location'), qr/\Q\/login\/?dest=\/app\E/);

# now login
$uri = '/login';
ok GET_OK $uri;

my $email = 'fred@redhotpenguin.com';
my $password = 'yomaing420';
$res = POST $uri, [email => $email, password => $password ];

t_cmp($res->code, 302, '302 on successful post');
like($res->header('Location'), qr{/app/home/index}, 'redirect to /app ok');

# run through all the website links to first make sure we don't get
# any 404s or 500s
my @uris = qw(
              /app/home/index

              /app/settings/index
              /app/settings/users

              /app/ad/index
              /app/report/index

              /app/blacklist/index
              /app/blacklist/edit/?url_id=-1

              /app/router/list
              /app/router/edit

              /app/ad/groups/list
              /app/ad/groups/edit

              /app/ad/bugs/list
              /app/ad/bugs/edit
);

foreach my $uri ( @uris ) {
  diag("grabbing uri $uri");
 ok  GET_OK $uri;
}

# test the reporting links
foreach my $type qw( views clicks rates ads) {
  foreach my $temporal qw( daily weekly monthly quarterly ) {
    ok GET_OK "/app/report/index/?type=$type&temporal=$temporal";
  }
}

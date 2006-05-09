# the handler is configured in modperl_extra.pl via
# Apache2::ServerUtil->server->add_config

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET';

my $module = 'SL::CS::Apache::Click';
my $url    = Apache::TestRequest::module2url($module);

t_debug("connecting to $url");
my $res = GET $url;

if ($res->is_success) {
    print $res->content;
} else {
    print "No content";
}

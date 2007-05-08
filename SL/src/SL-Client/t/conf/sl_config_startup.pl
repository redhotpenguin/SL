use Apache2::Module;
use Apache2::ServerUtil;
use Apache2::ServerRec;

my $server = Apache2::ServerUtil->server;
$|++;
use Data::Dumper;
for (my $s = $server; $s; $s = $s->next) {
	print STDERR "\nServer: ", $s->server_hostname, " port:", $s->port, "\n";
	my $cfg = Apache2::Module::get_config('SL::Client::Config', $s);
#	MyModule->init($s, $cfg);
	print STDERR "\n2Startup.pl: " . Dumper($cfg) . "\n";
}

1;

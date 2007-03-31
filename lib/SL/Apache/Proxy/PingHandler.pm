package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::Log ();
use Sys::Load ();
use SL::Model ();

our $MAX_LOAD = 1.5;

sub handler {
	my $r = shift;

	# first check that a database handle is available
	my $dbh = SL::Model->connect();
	unless ($dbh) {
		$r->log->error("Database has gone away :(");
		return Apache2::Const::SERVER_ERROR;
	}

	# now check the load
	my $minute_avg = [Sys::Load::getload()]->[0];
    return Apache2::Const::OK if $minute_avg < $MAX_LOAD;
	$r->log->error("System max load $MAX_LOAD exceeded: $minute_avg");
	return Apache2::Const::SERVER_ERROR;
}

1;
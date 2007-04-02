package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( HTTP_SERVICE_UNAVAILABLE DONE );
use Apache2::Log ();
use Sys::Load ();
use SL::Model ();

our $MAX_LOAD = 2;

sub handler {
	my $r = shift;

	my $minute_avg = [Sys::Load::getload()]->[0];
	my $dbh = SL::Model->connect();
	unless ($dbh) {
		$r->log->error("Database is not responding: sysload $minute_avg");
		return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
	}	
	
    return Apache2::Const::DONE if $minute_avg < $MAX_LOAD;
	$r->log->error("System max load $MAX_LOAD exceeded: $minute_avg");
	return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
}

1;
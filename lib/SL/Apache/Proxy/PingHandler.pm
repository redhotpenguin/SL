package SL::Apache::Proxy::PingHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::Log ();
use Sys::Load ();

our $MAX_LOAD = 1;

sub handler {
	my $r = shift;
    my $minute_avg = [Sys::Load::getload()]->[0];
    return Apache2::Const::OK if $minute_avg < $MAX_LOAD;
	$r->log->error("System max load $MAX_LOAD exceeded: $minute_avg");
	return Apache2::Const::SERVER_ERROR;
}

1;
package SL::Apache::Proxy::PostReadRequestHandler;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw( OK DONE );
use Apache2::Log ();
use APR::Table ();
use Apache2::RequestUtil ();

sub handler {
	my $r = shift;

    my $ua      = $r->headers_in->{'user-agent'};
    $r->pnotes('ua'      => $ua);
	if ($ua eq 'Apache (internal dummy connection)') {
		$r->subprocess_env(SL_URL => 'sl_dummy');
		return Apache2::Const::DONE;
	}
	return Apache2::Const::OK;
}

1;
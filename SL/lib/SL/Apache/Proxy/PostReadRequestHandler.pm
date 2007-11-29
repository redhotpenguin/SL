package SL::Apache::Proxy::PostReadRequestHandler;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw( OK DONE );
use Apache2::Log ();
use APR::Table ();
use Apache2::RequestUtil ();

use constant TIMING => $ENV{SL_TIMING} || 0;
use constant REQ_TIMING => $ENV{SL_REQ_TIMING} || 0;

my $TIMER;
if (TIMING or REQ_TIMING) {
  require RHP::Timer;
  $TIMER = RHP::Timer->new();
}

sub handler {
	my $r = shift;

    my $ua      = $r->headers_in->{'user-agent'};
	unless ($ua) {
		$ua = 'none';
	}
	$r->pnotes('ua'      => $ua);
	if ($ua eq 'Apache (internal dummy connection)') {
		$r->subprocess_env(SL_URL => 'sl_dummy');
		return Apache2::Const::DONE;
	}

    $TIMER->start('global_request_timer') if (TIMING or REQ_TIMING);
	$r->pnotes('global_request_timer' => $TIMER) if (TIMING or REQ_TIMING);
	return Apache2::Const::OK;
}

1;

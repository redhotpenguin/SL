package SL::Apache::Proxy::PostReadRequestHandler;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw( OK DONE );
use Apache2::Log         ();
use APR::Table           ();
use Apache2::RequestUtil ();

use constant DEBUG      => $ENV{SL_DEBUG}      || 0;
use constant TIMING     => $ENV{SL_TIMING}     || 0;
use constant REQ_TIMING => $ENV{SL_REQ_TIMING} || 0;

my $TIMER;
if ( TIMING or REQ_TIMING ) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

sub handler {
    my $r = shift;

    my $ua = $r->headers_in->{'user-agent'};
    unless ($ua) {
        $r->log->error("$$ no user agent, request " . $r->as_string);
        $ua = 'none';
    }
    $r->pnotes( 'ua' => $ua );

    if ( length($ua) > 25 ) {
        my $potential_dummy = substr( $ua, ( length($ua) - 27 ), length($ua) );

        if ( $potential_dummy eq '(internal dummy connection)' ) {
            $r->log->debug("$$ dummy connection") if DEBUG;

            $r->subprocess_env( SL_URL => 'sl_dummy' );
            $r->set_handlers( PerlResponseHandler => undef );
            return Apache2::Const::DONE;
        }
    }

    $TIMER->start('global_request_timer') if ( TIMING or REQ_TIMING );
    $r->pnotes( 'global_request_timer' => $TIMER ) if ( TIMING or REQ_TIMING );
    return Apache2::Const::DECLINED;
}

1;

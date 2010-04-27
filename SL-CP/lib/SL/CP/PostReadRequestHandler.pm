package SL::CP::PostReadRequestHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( DECLINED DONE HTTP_BAD_REQUEST );

=cut
use Apache2::RequestRec ();
use Apache2::Log         ();
use APR::Table           ();
use Apache2::RequestUtil ();
=cut


use constant DEBUG         => $ENV{SL_DEBUG}         || 0;
use constant VERBOSE_DEBUG => $ENV{SL_VERBOSE_DEBUG} || 0;
use constant TIMING        => $ENV{SL_TIMING}        || 0;
use constant REQ_TIMING    => $ENV{SL_REQ_TIMING}    || 0;

our $TIMER;
if ( TIMING or REQ_TIMING ) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

# handle missing user agent and apache internal mod_proxy connections
# also start the global request timer

sub handler {
    my $r = shift;

    $r->log->debug("$$ " . __PACKAGE__ . ", req: " . $r->as_string)
        if VERBOSE_DEBUG;

    my $ua = $r->headers_in->{'user-agent'} || '';
    $r->pnotes( 'ua' => $ua );

    if ( length($ua) > 25 ) {
        my $potential_dummy = substr( $ua, ( length($ua) - 27 ), length($ua) );

        if ( $potential_dummy eq '(internal dummy connection)' ) {
            $r->log->debug("$$ dummy connection") if VERBOSE_DEBUG;

            $r->subprocess_env( SL_URL => 'sl_dummy' );
            $r->set_handlers( PerlResponseHandler => undef );
            return Apache2::Const::DONE;
        }
    }

    # delete the X-Forwarded header and set the connection ip
    if ( defined $r->headers_in->{'X-Forwarded-For'} ) {
        $r->connection->remote_ip( $r->headers_in->{'X-Forwarded-For'} );
        $r->headers_in->unset('X-Forwarded-For');
    }

    # hack for unpatched perlbal
    $r->headers_in->unset('X-Proxy-Capabilities');

    $TIMER->start('global_request_timer') if ( TIMING or REQ_TIMING );
    $r->pnotes( 'global_request_timer' => $TIMER ) if ( TIMING or REQ_TIMING );
    return Apache2::Const::DECLINED;
}

1;
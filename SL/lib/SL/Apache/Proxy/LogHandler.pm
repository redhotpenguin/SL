package SL::Apache::Proxy::LogHandler;

use strict;
use warnings;

use SL::Model::Ad ();
use Apache2::Const -compile => qw( DECLINED LOG_INFO);
use Apache2::RequestUtil ();
use Apache2::Log         ();

use SL::Config;
our $CONFIG;

BEGIN {
    $CONFIG = SL::Config->new;
}

use constant TIMING     => $ENV{SL_TIMING}     || 0;
use constant REQ_TIMING => $ENV{SL_REQ_TIMING} || 0;
use constant DEBUG      => $ENV{SL_DEBUG}      || 0;
use constant VERBOSE_DEBUG      => $ENV{SL_VERBOSE_DEBUG}      || 0;


use constant DEFAULT_HASH_MAC => $CONFIG->sl_default_hash_mac || die 'hash_mac';
use constant DEFAULT_ROUTER_MAC => $CONFIG->sl_default_router_mac
  || die 'identity';

my $TIMER;
if (TIMING) {
    require RHP::Timer;
    $TIMER = RHP::Timer->new();
}

use constant THRESHOLD => $CONFIG->sl_proxy_apache_request_threshold || 0;

sub handler {
    my $r = shift;

    my $url = $r->pnotes('url');
    unless ($url) {
        $r->log->error("$$ no url in loghandler, something is broken");
        return Apache2::Const::DECLINED;
      }

    $r->log->debug("$$ executing LogHandler for url $url") if VERBOSE_DEBUG;
    if ( $url =~ m/sl_secret/ ) {
        $r->log->debug("$$ secret url, no log handling") if VERBOSE_DEBUG;
        return Apache2::Const::DECLINED;
    }

	if (($r->pnotes('hash_mac') eq DEFAULT_HASH_MAC) or
		($r->pnotes('router_mac') eq DEFAULT_ROUTER_MAC)) {
		# something is weird, so log it
		$r->log->error(sprintf(
			"Default client encountered, sl_header %s, hash_mac %s, router %s, url %s, ip %s, ad_id %d", $r->pnotes('sl_header'), $r->pnotes('hash_mac'),
                     $r->pnotes('router_mac'),
			$r->pnotes('url'), $r->connection->remote_ip, $r->pnotes('ad_id')));
}

    $r->subprocess_env( "SL_URL" => sprintf( 'sl_url|%s', $url ) );

    if ( TIMING || REQ_TIMING ) {    # grab the total request time
        my $total = @{ $r->pnotes('global_request_timer')->checkpoint }[4];

        my $request_time = sprintf( "sl_request_total|%f", $total );
        $r->log->info("$$ request time $request_time for $url");

        $r->log->error("$$ *** REQ THRESHOLD TIMEOVER:  $total for $url")
          if ( $total > THRESHOLD );

        $r->subprocess_env( "SL_TIMER" => $request_time );
    }

    # for subrequests we don't have any log_data since no ad was inserted
    return Apache2::Const::DECLINED unless $r->pnotes('ad_id');

    $TIMER->start('log_ad_view') if TIMING;
    my $logged = SL::Model::Ad->log_view(
        {
            ad_id   => $r->pnotes('ad_id'),
            ip      => $r->connection->remote_ip,
            user    => $r->pnotes('hash_mac'),
            mac     => $r->pnotes('router_mac'),
            url     => $r->pnotes('url'),
            referer => $r->pnotes('referer') || ''
        }
    );
    $r->log->debug(
        sprintf(
            "$$ logging view for url %s, ad_id %d",
            $url, $r->pnotes('ad_id')
        )
      )
      if DEBUG;

    $r->log->error(
        sprintf( "$$ Error logging view  ad_id %d",
            @{ $r->pnotes('log_data') } )
      )
      unless $logged;

    # checkpoint
    $r->log->info( sprintf( "$$ timer %s %s %d %s %f", @{ $TIMER->checkpoint } ) )
      if TIMING;

    return Apache2::Const::DECLINED;
}

1;

package SL::Apache::Proxy::LogHandler;

use strict;
use warnings;

use SL::Model::Ad ();
use Apache2::Const -compile => qw( DECLINED LOG_INFO);
use Apache2::RequestUtil ();
use Apache2::Log ();
use RHP::Timer ();

my $TIMER = RHP::Timer->new();
use SL::Config;
our $CONFIG = SL::Config->new;
our $THRESHOLD = $CONFIG->sl_proxy_apache_request_threshold;

sub handler {
    my $r = shift;

    my $proxy_req_time;
	if (defined $r->pnotes('proxy_req_timer')) {
		$proxy_req_time = sprintf("sl_request_remote|%f",
			$r->pnotes('proxy_req_timer')->last_interval);
	}

	my $total = @{ $r->pnotes('request_timer')->checkpoint }[4];
    my $request_time = sprintf( "sl_request_total|%f", $total); 
	
	my $url = $r->pnotes('url');
	if (($total > $THRESHOLD) or ( $r->server->loglevel() == Apache2::Const::LOG_INFO)) {
		if ($url !~ m/sl_secret/) {
			$r->log->error("***** SL_REQUEST_TIME $total for url $url");
		}
	}
	if ($proxy_req_time) {
		$request_time = join(' ', $request_time, $proxy_req_time);
	}
	$r->subprocess_env("SL_TIMER" => $request_time);

	if ($url) {
	    $r->subprocess_env("SL_URL" => sprintf('sl_url|%s', $url));
	}
    # for subrequests we don't have any log_data since no ad was inserted
    return Apache2::Const::DECLINED unless 
        (defined $r->pnotes('log_data') && $r->pnotes('log_data')->[0] && $r->pnotes('log_data')->[1]);

    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $TIMER->start('log_view');
    }
    my $logged = SL::Model::Ad->log_view( 
        $r->pnotes('log_data')->[0], $r->pnotes('log_data')->[1] );

    $r->log->debug(sprintf("$$ logging view for ip %s, ad_id %d",
        @{$r->pnotes('log_data')}));

    $r->log->error(sprintf("Error logging view %s, ad_id %d",
		@{$r->pnotes('log_data')})) unless $logged;

    # checkpoint
    if ($r->server->loglevel() == Apache2::Const::LOG_INFO) {
        $r->log->info(sprintf("timer $$ %s %d %s %f",
            @{$TIMER->checkpoint}[0,2..4]));
    }

    return Apache2::Const::DECLINED;
}

1;

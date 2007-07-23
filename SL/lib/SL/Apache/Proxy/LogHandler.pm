package SL::Apache::Proxy::LogHandler;

use strict;
use warnings;

use SL::Model::Ad ();
use Apache2::Const -compile => qw( DECLINED LOG_INFO);
use Apache2::RequestUtil ();
use Apache2::Log ();
use RHP::Timer ();

my $TIMER = RHP::Timer->new();

sub handler {
    my $r = shift;

    my $request_time = sprintf( "sl_request_timer|%f", 
		@{ $r->pnotes('request_timer')->checkpoint }[4] );
    $r->subprocess_env("SL_TIMER" => $request_time); 
    $r->subprocess_env("SL_URL" => sprintf('sl_url|%s', $r->pnotes('url')));    
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

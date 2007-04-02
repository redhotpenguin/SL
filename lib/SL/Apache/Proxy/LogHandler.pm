package SL::Apache::Proxy::LogHandler;

use strict;
use warnings;

use SL::Model::Ad ();
use Apache2::Const -compile => qw( DECLINED );
use Apache2::RequestUtil ();
use Apache2::Log ();

sub handler {
    my $r = shift;
    my $log_data = $r->pnotes('log_data');

	$r->subprocess_env("SL_URL" => sprintf('sl_url|%s', $r->pnotes('url')));	
	# for subrequests we don't have any log_data since no ad was inserted
	return Apache2::Const::DECLINED unless ($log_data->[0] and $log_data->[1]);
	my $logged = SL::Model::Ad->log_view( $log_data->[0], $log_data->[1] );

    my $msg = sprintf("$$ logging view for ip %s, ad_id %d", @{$log_data});
    $r->log->debug($msg);
    unless ($logged) {
        $r->log->error("Error " . $msg);
    }

    return Apache2::Const::DECLINED;
}

1;
package SL::Apache::Proxy::BlacklistHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( REDIRECT );
use Apache2::Connection ();
use SL::Model ();

sub handler {
	my $r = shift;
	my $dbh = SL::Model->connect();
	my $user_id = join("|", $r->connection->remote_ip, 
		$r->pnotes('ua'), $r->construct_server());

	my $sth = 
		$dbh->prepare("INSERT INTO user_blacklist (user_id) values ( ? )");
	$sth->bind_param(1,$user_id);
	my $rv = $sth->execute;
	unless ($rv) {
		$r->log->error("Problem blacklisting $user_id ");
	}
	$r->headers_out->set(Location => $r->pnotes('referer'));
	return Apache2::Const::REDIRECT;
}

1;
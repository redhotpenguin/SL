package SL::Apache::Proxy::BlacklistHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( REDIRECT );
use Apache2::Connection ();
use SL::Model ();

sub handler {
	my $r = shift;

    my $user_id;
    if (my $sl_header = $r->headers_in->{'x-sl'}) {
	  # we want to know what location they blacklisted it at
      $user_id = join('|', $sl_header, $r->construct_server());
    } else {
      $user_id = join("|", $r->connection->remote_ip, 
		$r->pnotes('ua'), $r->construct_server());
   }
	$r->log->info("===> user blacklist handler, user_id $user_id");
	my $dbh = eval { SL::Model->connect(); };
	unless ($dbh) {
		$r->log->error(sprintf("package %s db connect failed err: %s", 
				__PACKAGE__, $@));
		return _redirect($r, $user_id);
	}

	my $select_sth = $dbh->prepare("SELECT user_id, ts FROM user_blacklist WHERE user_id = ?");
	$select_sth->bind_param(1, $user_id);
	my $rv = eval { $select_sth->execute };
	if (!$rv or $@) {
		$r->log->error(
			sprintf("user_blacklist select err, uid %s, err %s, url %s, referer %s", 
				$user_id, $@, $r->pnotes('url'), $r->pnotes('referer')));
		return _redirect($r, $user_id);
	}

	# no error, see if it has been blacklisted already
	my $ary_ref = $select_sth->fetchrow_arrayref;
	if (defined $ary_ref->[0]) {
		# ok an entry exists, someone is trying to blacklist it again?
		$r->log->error(
			sprintf("re-blacklist attempt, user_id %s, url %s, ts %s, referer %s",
			   $user_id, $r->pnotes('url'), $ary_ref->[1], $r->pnotes('referer')));
		return _redirect($r, $user_id);
	}

	# not blacklisted yet, add it
	my $sth = 
		$dbh->prepare("INSERT INTO user_blacklist (user_id) values ( ? )");
	$sth->bind_param(1,$user_id);
	$rv = eval { $sth->execute };
	if (!$rv or $@) {
		# something is busted!
		$r->log->error(
			sprintf("blacklist attempt failed, uid %s, url %s, referer %s, err %s",
				$user_id, $r->pnotes('url'), $r->pnotes('referer'), $@ ));
		return _redirect($r, $user_id);
	}

	# blacklist happened ok
	$r->log->debug(sprintf("%s blacklist successful for uid %s, referer %s",
			$r->pnotes('url'), $user_id, $r->pnotes('referer')));
	return _redirect($r, $user_id);
}

sub _redirect {
	my ($r, $user_id) = @_;
	if (($r->pnotes('referer') eq 'no_referer') or ( !$r->pnotes('referer'))) {
		# if no referer redirect to the root url
		$r->log->error(sprintf("no referer, uid %s sending to base domain %s",
				$user_id, $r->construct_url('/')));
		$r->headers_out->set(Location => $r->construct_url('/'));
	} else {
		# redirect back to the referring page
		$r->headers_out->set(Location => $r->pnotes('referer'));
	}
    $r->no_cache(1);
	return Apache2::Const::REDIRECT;
}

1;

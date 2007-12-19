package SL::Apache::App::Click;

use strict;
use warnings;

use Apache2::Const -compile => qw( NOT_FOUND SERVER_ERROR REDIRECT );
use Apache2::Log;
use Apache2::RequestIO;
use Apache2::RequestRec ();
use APR::Table ();
use DBD::Pg qw(:pg_types);
use SL::Model;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

if (DEBUG) {
  require Data::Dumper;
}

use constant GET_AD => q{
SELECT ad_id
FROM ad
WHERE ad.md5 = ?
};

use constant INSERT_CLICK => q{
INSERT INTO click
( ad_id, location_id, router_id, usr_id, referer )
values
( ?,     (select location_id from location where ip = ?),
                      (select router_id from router where macaddr = ?),
                                 (select usr_id from usr where hash_mac = ?),
                                          ? )
};

use constant REDIRECT_URL => q{
SELECT uri from ad_sl
WHERE ad_id = ?
};

use constant LINKSHARE_URL => q{
SELECT linkurl FROM ad_linkshare
WHERE ad_id = ?
};

sub handler {
    my $r = shift;

    return Apache2::Const::NOT_FOUND unless $r->method eq 'GET';
    $r->log->debug("$$ URI is ", $r->uri) if DEBUG;
    my ($md5) = $r->uri =~ m/([^\/]+)$/;

    unless (defined $md5 && length($md5) == 32) {
        return Apache2::Const::NOT_FOUND;
    }
    $r->log->debug("$$ MD5 is $md5") if DEBUG;

    my $dbh = SL::Model->db_Main();

    my $get_sth = $dbh->prepare( GET_AD );
    $get_sth->bind_param( 1, $md5, );
    my $rv = $get_sth->execute;
    unless ( $rv ) {
        $r->log->error("$$ failed to grab ad for md5 $md5");
        $dbh->rollback;
        return Apache2::Const::SERVER_ERROR;
    }

    my $ary_ref = $get_sth->fetchrow_arrayref;
    $get_sth->finish;
    unless (defined $ary_ref->[0]) {
      $r->log->error("$$ could not find ad for md5 $md5");
      $dbh->rollback;
      return Apache2::Const::NOT_FOUND;
    }

    $r->log->debug("$$ Clicking link: " . Data::Dumper::Dumper($ary_ref)) if DEBUG;

    my $click_sth = $dbh->prepare( INSERT_CLICK );
    $click_sth->bind_param( 1, $ary_ref->[0]);
    $click_sth->bind_param( 2, $r->connection->remote_ip);
    $click_sth->bind_param( 3, $r->pnotes('router_mac'));
    $click_sth->bind_param( 4, $r->pnotes('hash_mac'));
    $click_sth->bind_param( 5, $r->headers_in->{'Referer'} || 'no referer');

    $rv = $click_sth->execute;
    $click_sth->finish;

    unless ( $rv ) {
        $r->log->error("$$ Could log find link for md5 $md5");
        $dbh->rollback;
        return Apache2::Const::SERVER_ERROR;
    } else {
        $r->log->debug("$$ Logged click through for link ", $ary_ref->[0]) if DEBUG;
        $dbh->commit;
    }

	# find the ad to grab the url and redirect
	my $redir_sth = $dbh->prepare(REDIRECT_URL);
	$redir_sth->bind_param(1, $ary_ref->[0]);
	$rv = $redir_sth->execute;
	my $url_ary_ref = $redir_sth->fetchrow_arrayref;
    $redir_sth->finish;
	unless ($url_ary_ref) { # hmm must be a feed ad
		my $linkshare_sth = $dbh->prepare(LINKSHARE_URL);
		$linkshare_sth->bind_param(1, $ary_ref->[0]);
		$rv = $linkshare_sth->execute;
		$url_ary_ref = $linkshare_sth->fetchrow_arrayref;
        $linkshare_sth->finish;

		unless ($url_ary_ref) { # oh this is bad, no ad, i'm sad
			$r->log->error("$$ couldn't find an ad id " . $url_ary_ref->[0]);
			$r->headers_out->set( Location => 'http://www.silverliningnetworks.com');
            return Apache2::Const::REDIRECT;
		}
	}

    # Now redirect
    $r->log->debug("$$ Redirecting to ", $url_ary_ref->[0] ) if DEBUG;
    $r->headers_out->set( Location => $url_ary_ref->[0] );
    return Apache2::Const::REDIRECT;
}

1;

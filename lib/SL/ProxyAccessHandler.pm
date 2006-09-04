package SL::Apache::ProxyAccessHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR DONE );
use Apache2::RequestRec     ();
use Apache2::Log            ();
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Cache::FastMmap;

use SL::DB;

our $cache;
our $login_url = 'http://www.redhotpenguin.com/sl/logon';

BEGIN {
	require SL::Config;
	my $cfg = SL::Config->new;
	
	# destroy the old cache file
	my $share_file = $cfg->sl_ip_cache_file;
	
	unlink $share_file if -e $share_file;
    $cache =
      Cache::FastMmap->new( raw_values => 1, share_file => $share_file );
    my $sql         = qq{select ip from reg where active > 0};
	require SL::DB;
	my $dbh         = SL::DB->connect;
	my $ips_ary_ref = $dbh->selectall_arrayref($sql);
    die unless $ips_ary_ref;    # No ips in the database yet??
	$dbh->commit;

    # load up the cache from the database
    foreach my $ip ( @{$ips_ary_ref} ) {
        print STDERR "Caching ip " . $ip->[0] . "...\n";
        $cache->set( $ip->[0] => 1 );
    }

}

sub handler {
    my $r = shift;

    my $c         = $r->connection;
    my $remote_ip = $c->remote_ip;
    $r->log->debug("$$ AccessHandler for ip $remote_ip");

    if ( registered( $r, $remote_ip ) ) {
		# let the request through
		return Apache2::Const::OK;
    }
    else { # not registered serve the reg form
        # stash the destination
        my $c = $r->connection();
        unless ($c->pnotes('dest')) {
			$c->pnotes( dest => $r->construct_url( $r->unparsed_uri ));
			$r->log->debug("Stashing destination " . $r->construct_url( $r->unparsed_uri));
		}
		$r->log->debug("connection dest stash is " . $c->pnotes('dest'));
		
		# send to the registration form
		$r->set_handlers(PerlTransHandler => 'Apache2::Const::DECLINED');
		if ($r->uri =~ m{\.(?:ico|gif)$}) {
			$r->handler('default-handler');
			$r->set_handlers(PerlMapToStorageHandler => 'Apache2::Const::DECLINED');
			$r->set_handlers(PerlResponseHandler => 'Apache2::Const::DECLINED');
			return Apache2::Const::OK;
		} else {
			$r->set_handlers(PerlResponseHandler => 'SL::Apache::Reg::handler');
			return Apache2::Const::OK;
		}
	}
}

sub registered {
    my ( $r, $ip ) = @_;

    # try the cache first
    if ( $cache->get($ip) ) {
        $r->log->debug("$$ Cache hit for ip $ip");
        return 1;
    }
    else {

        # try the database, maybe they just registered
        my $sql = "select ip from reg where ip = ? and active > 0";
        my $dbh = SL::DB->connect;
		die unless $dbh;
        my $sth = $dbh->prepare($sql);
        $sth->bind_param( 1, $ip );
		my $ok = $sth->execute;
		die unless $ok;
        my $ips_ary_ref = $sth->fetchall_arrayref;
		$dbh->commit;
        
		if ( scalar( @{$ips_ary_ref} ) == 0 ) {
            $r->log->debug("ip $ip is unregistered");
            # Unregistered IP
            return;
        }
        # This ip is registered
        elsif ( scalar( @{$ips_ary_ref} ) == 1 ) {
			$r->log->debug("ip $ip found in db, updating cache");
		}            
		elsif ( scalar( @{$ips_ary_ref} ) > 1 ) {
            $r->log->error("$$ More than one ip $ip found in database");
        }
		
		# Update the cache
        $cache->set( $ip => 1 );
        return 1;
   }
}

1;

package SL::Apache::Proxy::AccessHandler;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR REDIRECT );
use Apache2::RequestRec     ();
use Apache2::Log            ();
use Apache2::Connection     ();
use Cache::FastMmap;
use SL::Model ();

use constant REGISTRATION_URL => 'https://www.redhotpenguin.com/sl/reg/?dest=';
use constant LOGIN_URL  => 'http://www.redhotpenguin.com/sl/logon';

our $cache;
our $APP_DOMAIN = 'redhotpenguin';

#BEGIN {
#	require SL::Config;
#	my $cfg = SL::Config->new;
	
	# destroy the old cache file
#	my $share_file = $cfg->sl_ip_cache_file;
	
#	unlink $share_file if -e $share_file;
#    $cache =
#      Cache::FastMmap->new( raw_values => 1, share_file => $share_file );
#    my $sql         = qq{select ip from reg where active > 0};
#	require SL::Model;
##	my $dbh         = SL::Model->connect;
#	my $ips_ary_ref = $dbh->selectall_arrayref($sql);
#    die unless $ips_ary_ref;    # No ips in the database yet??
#	$dbh->commit;

    # load up the cache from the database
#    foreach my $ip ( @{$ips_ary_ref} ) {
#        print STDERR "Caching ip " . $ip->[0] . "...\n";
#        $cache->set( $ip->[0] => 1 );
#    }

#}

sub handler {
    my $r = shift;

    if ( registered( $r ) || app_domain($r)) {
		# let the request through
		return Apache2::Const::OK;
    }
    else { # not registered serve the reg form
		$r->log->info("$$ Unregistered ip " . $r->connection->remote_ip
			. ", redirecting to " . $r->construct_url($r->unparsed_uri));
		$r->headers_out->set('Location' => REGISTRATION_URL . 
			$r->construct_url($r->unparsed_uri));
		return Apache2::Const::REDIRECT;
	}
}

sub app_domain {
	my $r = shift;
	my $domain = $r->construct_url($r->unparsed_uri);
	return 1 if ($domain =~ m/$APP_DOMAIN/);
	return;
}

sub registered {
    my $r = shift;
	my $c  = $r->connection;
    my $ip = $c->remote_ip;

    $r->log->debug("$$ SL::ProxyAccessHandler for ip $ip");
    # try the cache first
    if ( $cache->get($ip) ) {
        $r->log->debug("$$ Cache hit for ip $ip");
        return 1;
    }
    else {

        # try the database, maybe they just registered
        my $sql = "select ip from reg where ip = ? and active > 0";
        my $dbh = SL::Model->connect;
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

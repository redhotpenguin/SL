package SL::CP;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::Connection ();
use Apache2::ConnectionUtil ();
use Apache2::Const -compile => qw( NOT_FOUND OK REDIRECT SERVER_ERROR HTTP_SERVICE_UNAVAILABLE M_GET HTTP_METHOD_NOT_ALLOWED );
use Apache2::Log         ();
use Apache2::RequestUtil ();
use Apache2::Request     ();
use Apache2::URI         ();
use APR::Table           ();

use URI::Escape ();

use SL::Config       ();
use SL::CP::IPTables ();
use SL::BrowserUtil  ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;
use constant MAX_RATE  => 0.5;
use constant MIN_COUNT => 5;

our $VERSION = 0.03;

our ( $Config, $Lease_file, $Auth_url );

BEGIN {
    $Config     = SL::Config->new;
    $Auth_url   = $Config->sl_cp_auth_url || die 'oops';
    $Lease_file = $Config->sl_dhcp_lease_file || die 'oops';
}

sub handler {
    my $r = shift;

    $r->log->debug( "handling new request for " . $r->connection->remote_ip )
      if DEBUG;

    my ( $mac, $ip ) = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    if ($r->header_only or 
	    ($r->method_number != Apache2::Const::M_GET) or 
	    (!defined $r->headers_in->{'user-agent'}) or
	    (!SL::BrowserUtil->is_a_browser($r->headers_in->{'user-agent'}) )) {

 	    return Apache2::Const::HTTP_METHOD_NOT_ALLOWED;
    }

    my $c = $r->connection;
    if (my $attempts = $c->pnotes($c->remote_ip)) {
	my $count = $attempts->{count};
	my @times = @{$attempts->{times}};
	my $idx;
	if ($#times > 9) {
		$count = 10;
		$idx=$#times-$count;
	} else {
		$idx=0;
	}
	my $total_time = $times[$#times] - $times[$idx];

	push @{$attempts->{times}}, time();
	$attempts->{count}++;
	$c->pnotes($c->remote_ip => $attempts);
	if ($total_time != 0) {

		my $rate = ($count / $total_time);
		$r->log->debug("throttle check mac $mac, ip $ip, count $count, time $total_time, rate $rate") if DEBUG;
		if (($count > MIN_COUNT) && ($rate > MAX_RATE)) {
			$r->log->error("rate violation ip $ip, mac $mac, total time $total_time, count $count, rate $rate");
			# make 'em wait
			sleep 5;
			return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
		}
	}
    } else {
	  my %attempts = ( 'count' => 1, 'times' => [ time() ]);
	  $r->log->debug("setting new limit check for ip $ip, count 1, time " . time()) if DEBUG;
  	  $c->pnotes($c->remote_ip => \%attempts);
   }

    my $dest_url = $r->construct_url( $r->unparsed_uri );

    # check to see if this mac has been paid for
    my $paid_code = eval { SL::CP::IPTables->check_for_paid_mac( $mac, $ip ); };
    if ($@) {
        $r->log->error("$$ Error checking paid mac $mac, $@");
        return Apache2::Const::SERVER_ERROR;
    }

    if ( $paid_code == 1 ) {

        $r->log->info("$$ valid mac $mac found, redirecting to $dest_url");
        $r->headers_out->set( Location => $dest_url );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    # existing ads plan for this mac?
    my $ads_code = eval { SL::CP::IPTables->check_for_ads_mac( $mac, $ip ); };

    if ($@) {
        $r->log->error("$$ Error checking ads mac $mac, $@");
        return Apache2::Const::SERVER_ERROR;
    }

    if ( $ads_code == 1 ) {

        $r->log->info("$$ valid mac $mac found, redirecting to $dest_url");
        $r->headers_out->set( Location => $dest_url );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    # at this point the mac obviously has not been put into a rule chain
    # so redirect to the auth server
    $dest_url = URI::Escape::uri_escape($dest_url);
    my $esc_mac  = URI::Escape::uri_escape($mac);
    my $location = "$Auth_url?mac=$esc_mac&url=$dest_url";
    $location .= "&expired=1" if ( $paid_code == 401 );

    $r->log->info("$$ unknown $mac found, redirecting to $location");
    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub ads {
    my ( $class, $r ) = @_;

    my ( $mac, $ip ) = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $req     = Apache2::Request->new($r);
    my $url     = $req->param('url');
    my $req_mac = $req->param('mac');
    my $token   = $req->param('token');

    unless ($req_mac) {
	   $r->log->error("no mac passed in url for dhcp mac $mac");
	   return Apache2::Const::NOT_FOUND;
    }

    # urls had better match up
    unless ( $req_mac eq $mac ) {
        $r->log->error(
            "auth macs didn't match up, mac $mac, req mac $req_mac");
        return Apache2::Const::SERVER_ERROR;
    }

    my $added =
      eval { SL::CP::IPTables->add_to_ads_chain( $mac, $ip, $token ); };

    if ($@) {

        $r->log->error("$$ error adding mac $mac to ads chain: $@");
        return Apache2::Const::SERVER_ERROR;
    }

    if ( ( $added == 401 ) or ( $added == 404 ) ) {

        # must be a 404
        my $dest_url = URI::Escape::uri_escape($url);
        my $esc_mac  = URI::Escape::uri_escape($mac);
        my $location = "$Auth_url?mac=$esc_mac&url=$dest_url";

        $location .= "&expired=1" if ( $added == 401 );
        $r->log->info(
"expired mac address $mac found, code $added, redirecting to $location"
        );
        $r->headers_out->set( Location => $location );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    $r->log->info("$$ added mac $mac to ad supported chain, redir to url $url");

    $mac = URI::Escape::uri_escape($mac);
    $url = URI::Escape::uri_escape($url);
    my $location = $Auth_url . "/post?mac=$mac&url=$url";
    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub paid {
    my ( $class, $r ) = @_;

    my ( $mac, $ip ) = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $req     = Apache2::Request->new($r);
    my $url     = $req->param('url');
    my $req_mac = $req->param('mac');
    my $token   = $req->param('token');

    # urls had better match up
    unless ( $req_mac eq $mac ) {
        $r->log->error(
            "$$ auth macs didn't match up, mac $mac, req mac $req_mac");
        return Apache2::Const::SERVER_ERROR;
    }

    my $added =
      eval { SL::CP::IPTables->add_to_paid_chain( $mac, $ip, $token ); };

    if ($@) {

        $r->log->error("$$ error adding mac $mac to paid chain: $@");
        return Apache2::Const::SERVER_ERROR;
    }

    if ( ( $added == 401 ) or ( $added == 404 ) ) {

        # must be a 404
        my $dest_url = URI::Escape::uri_escape($url);
        my $esc_mac  = URI::Escape::uri_escape($mac);
        my $location = "$Auth_url?mac=$esc_mac&url=$dest_url";
        $location .= "&expired=1" if ( $added == 401 );

        $r->log->info( "expired mac address $mac found, code "
              . $added
              . ", redirecting to $location" );
        $r->headers_out->set( Location => $location );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    $r->log->info("$$ added mac $mac to paid chain");

    $mac = URI::Escape::uri_escape($mac);
    $url = URI::Escape::uri_escape($url);

    my $location = "$Auth_url/post?mac=$mac&url=$url";
    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub upgrade {
    my ($class, $r) = @_;

    my ( $mac, $ip ) = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    # make sure they don't already have a paid account
    # check to see if this mac has been paid for
    my $paid_code = eval { SL::CP::IPTables->check_for_paid_mac( $mac, $ip ); };
    if ($@) {
        $r->log->error("$$ Error checking paid mac $mac, $@");
        return Apache2::Const::SERVER_ERROR;
    }

    if ( $paid_code == 1 ) {

        $r->log->error("$$ mac $mac trying to upgrade, but already has paid plan");
        $r->headers_out->set( Location => 'http://www.silverliningnetworks.com/aircloud/splash.html' );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    # this person wants to upgrade, they should have an ads plan
    my $iptables_ip = SL::CP::IPTables->check_ads_chain_for_mac( $mac );

    if (!$iptables_ip or ( $iptables_ip && ( $iptables_ip ne $ip ) )) {
      # something bad happened

      $r->log->error("mac $mac, ip $ip invalid or missing iptables rule upgrading");
      return Apache2::Const::SERVER_ERROR;
    }

    # yay, they have a valid firewall rule for the ad chain.  so delete it
    SL::CP::IPTables->delete_from_ads_chain( $mac, $ip );

    # and then redirect them to the auth page
    my $esc_mac  = URI::Escape::uri_escape($mac);
    my $location = "$Auth_url?mac=$esc_mac&upgrade=1";

    $r->log->info("$$ mac $mac redirecting upgrade request to $location");
    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}


sub _mac_from_ip {
    my $r = shift;

    # get the ip
    my $ip = $r->connection->remote_ip;

    my $lease = `grep $ip $Lease_file`;

    unless ($lease) {
        $r->log->error("$$ oops no lease found for ip $ip");
        return;
    }

    chomp($lease);

    my ($mac) = $lease =~ m/^\d+\s(\S+)\s/;
    unless ($mac) {
        $r->log->error("$$ woah error extracting mac from lease $lease");
        return;
    }

    $r->log->info("$$ found mac address $mac for ip $ip");

    return ( $mac, $ip );
}

1;

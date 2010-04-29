package SL::CP;

use strict;
use warnings;
use Apache2::Const -compile => qw( NOT_FOUND OK REDIRECT SERVER_ERROR DECLINED
                                   AUTH_REQUIRED HTTP_SERVICE_UNAVAILABLE
                                   M_GET HTTP_METHOD_NOT_ALLOWED );

use Data::Dumper qw(Dumper);

use Apache2::Request    ();
use Apache2::RequestRec ();
use Apache2::Connection ();
use Apache2::ConnectionUtil ();
use Apache2::Log         ();
use Apache2::Response    ();
use Apache2::RequestUtil ();
use Apache2::URI         ();
use APR::Table           ();


use SL::Config       ();
use SL::CP::IPTables ();
use SL::BrowserUtil  ();
use HTML::Template   ();
use URI::Escape ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our $VERSION = 0.04;

our ( $Config, $Lease_file, $Auth_url, $Max_rate,
      $Min_count, $Wan_if, $Lan_if, $Lan_ip, $Wan_mac );

BEGIN {
    $Config     = SL::Config->new;
    $Auth_url   = $Config->sl_cp_auth_url        || die 'oops';
    $Lease_file = $Config->sl_dhcp_lease_file    || die 'oops';
    $Max_rate   = $Config->sl_ratelimit_max_rate   || die 'oops';
    $Min_count  = $Config->sl_ratelimit_min_count || die 'oops';
    $Wan_if     = $Config->sl_wan_if              || die 'oops';
    $Lan_if     = $Config->sl_lan_if              || die 'oops';
    ($Lan_ip)   = `/sbin/ifconfig $Lan_if` =~ m/inet addr:(\S+)/;
    ($Wan_mac)  = `/sbin/ifconfig $Wan_if` =~ m/HWaddr\s(\S+)/;
}
    
our $Template = HTML::Template->new(
        filename          => $Config->sl_httpd_root . '/htdocs/sl/splash.tmpl',
        die_on_bad_params => 0 );

our $Search_hosts = SL::CP::IPTables->load_allows('search_hosts.txt');

sub handler {
    my ($class, $r) = @_;

    # handle search hosts
    if (($Config->sl_search eq 'On') &&
        (grep { $r->hostname eq $_ } @{$Search_hosts} )) {

        $r->log->debug("$$ found search host " . $r->hostname) if DEBUG;
        $r->push_handlers(PerlResponseHandler => 'SL::Proxy::Search::TransHandler');
        return Apache2::Const::DECLINED;
    }

    my $ip = $r->connection->remote_ip;
    $r->log->debug("$$ new request ip $ip") if DEBUG;

    my $mac = $class->mac_from_ip($ip);
    return Apache2::Const::NOT_FOUND unless $mac;

    return Apache2::Const::HTTP_METHOD_NOT_ALLOWED
    	if ($r->header_only or ($r->method_number != Apache2::Const::M_GET));

    return Apache2::Const::AUTH_REQUIRED
	if ((!defined $r->headers_in->{'user-agent'}) or
	    (!SL::BrowserUtil->is_a_browser($r->headers_in->{'user-agent'})));

    my $dest_url = $r->construct_url( $r->unparsed_uri );

    # check to see if this mac has been authenticated already
    my $auth_type = eval { SL::CP::IPTables->check_for_mac( $mac, $ip ); };
    if ($@) {
        $r->log->error("$$ Error checking mac $mac, payload " . Dumper($@));
        return Apache2::Const::SERVER_ERROR;
    }

    $r->log->debug("$$ auth type $auth_type for $mac") if DEBUG;

    if ( ($auth_type eq 'paid') or ($auth_type eq 'ads') ) {

        # this is a known mac, go on to the web
        $r->log->debug("$$ valid mac $mac, redirect to $dest_url") if DEBUG;
        $r->headers_out->set( Location => $dest_url );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;

    }

    if (DEBUG) {
        $Template = HTML::Template->new(
            filename => $Config->sl_httpd_root . '/htdocs/sl/splash.tmpl',
            die_on_bad_params => 0 );
    }

    $Template->param(PERLBAL  => "http://$Lan_ip:" . $Config->sl_perlbal_port);
    $Template->param(CDN_HOST => $Config->sl_cdn_host);
    $Template->param(AUTH_URL => $Auth_url);
    $Template->param(MAC      => URI::Escape::uri_escape($mac));
    $Template->param(URL      => URI::Escape::uri_escape($dest_url));
    $Template->param(CP_MAC   => URI::Escape::uri_escape($Wan_mac));
    $Template->param(EXPIRED  => 1) if ($auth_type == 401);
    $Template->param(PROVIDER_HREF => $Config->sl_account_website);
    $Template->param(PROVIDER_LOGO => $Config->sl_account_logo);

    $r->content_type('text/html; charset=UTF-8');
    $r->no_cache(1);
    $r->rflush;

    my $output = $Template->output;
    $r->print($output);

    return Apache2::Const::OK;
}

sub free {
    my ( $class, $r ) = @_;

    my $ip = $r->connection->remote_ip;
    my $mac = $class->mac_from_ip($ip);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $req     = Apache2::Request->new($r);
    my $url     = $req->param('url');
    my $req_mac = $req->param('mac');

    unless ($req_mac) {
	   $r->log->error("no mac passed in url for dhcp mac $mac");
	   return Apache2::Const::NOT_FOUND;
    }

    # macs had better match up
    unless ( $req_mac eq $mac ) {
        $r->log->error(
            "auth macs didn't match up, mac $mac, req mac $req_mac");
        return Apache2::Const::SERVER_ERROR;
    }

    my $added =
      eval { SL::CP::IPTables->add_to_ads_chain( $mac, $ip ); };

    if ($@) {

        $r->log->error("$$ error adding mac $mac to ads chain: $@");
        return Apache2::Const::SERVER_ERROR;
    }

    my $location = $class->make_post_url($Config->sl_splash_href,
        URI::Escape::uri_escape($url));

    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}


sub paid {
    my ( $class, $r ) = @_;

    my $ip = $r->connection->remote_ip;
    my $mac = $class->mac_from_ip($ip);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $req     = Apache2::Request->new($r);
    my $url     = $req->param('url');
    my $req_mac = $req->param('mac');

    # macs had better match up
    unless ( $req_mac eq $mac ) {
        $r->log->error(
            "$$ auth macs didn't match up, mac $mac, req mac $req_mac");
        return Apache2::Const::SERVER_ERROR;
    }

    my $added =
      eval { SL::CP::IPTables->add_to_paid_chain( $mac, $ip ); };

    if ($@) {

        $r->log->error("$$ error adding mac $mac to paid chain: $@");
        return Apache2::Const::SERVER_ERROR;
    }

    $mac = URI::Escape::uri_escape($mac);
    $url = URI::Escape::uri_escape($url);

    if ( ( $added == 401 ) or ( $added == 404 ) ) {

        # must be a 404
        my $location = "$Auth_url?mac=$mac&url=$url";
        $location .= "&expired=1" if ( $added == 401 );

        $r->log->debug( "expired mac address $mac found, code "
              . $added
              . ", redirecting to $location" ) if DEBUG;
        $r->headers_out->set( Location => $location );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    # else we have an authenticated user
    my $location = $class->make_post_url($Config->sl_splash_href, $url);
    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub make_post_url {
    my ( $class, $splash_url, $dest_url ) = @_;

    $dest_url = URI::Escape::uri_escape($dest_url);
    my $separator = ($splash_url =~ m/\?/) ? '&' : '?';

    my $location = $splash_url . $separator . "url=$dest_url";

    return $location;
}


sub upgrade {
    my ($class, $r) = @_;

    my $ip = $r->connection->remote_ip;
    my $mac = $class->mac_from_ip($ip);
    return Apache2::Const::NOT_FOUND unless $mac;

    # make sure they don't already have a paid account
    # check to see if this mac has been paid for
    my $paid_code = eval { SL::CP::IPTables->check_for_paid_mac( $mac, $ip ); };
    if ($@) {
        $r->log->error("$$ Error checking paid mac $mac, $@");
        return Apache2::Const::SERVER_ERROR;
    }

    if ( $paid_code == 1 ) {

        $r->log->error("$$ $mac trying to upgrade, but already has paid plan");
        $r->headers_out->set(Location => $Config->sl_splash_href);
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }

    SL::CP::IPTables->delete_from_ads_chain($mac, $ip);

    # and then redirect them to the auth page
    my $esc_mac  = URI::Escape::uri_escape($mac);
    my $location = "$Auth_url?mac=$esc_mac&upgrade=1";

    $r->log->debug("$$ mac $mac redirecting upgrade to $location") if DEBUG;
    $r->headers_out->set(Location => $location);
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}


sub mac_from_ip {
    my ($class, $ip) = @_;

    my $fh;
    open($fh, '<', $Lease_file) or die "couldn't open lease $Lease_file";
    my $client_mac;
    while (my $line = <$fh>) {

        my ($time, $mac, $hostip, $hostname, $othermac) = split(/\s/, $line);
        if ($ip eq $hostip) {

            $client_mac = $mac;
            last;
        }
    }
    close($fh) or die $!;

    return unless $client_mac;

    warn("$$ found mac $client_mac for ip $ip") if DEBUG;

    return $client_mac;
}


sub ip_from_mac {
    my ($class, $client_mac) = @_;

    my $fh;
    open($fh, '<', $Lease_file) or die "couldn't open lease $Lease_file";
    my $client_ip;
    while (my $line = <$fh>) {

        my ($time, $mac, $hostip, $hostname, $othermac) = split(/\s/, $line);
        if ($client_mac eq $mac) {

            $client_ip = $hostip;
            last;
        }
    }
    close($fh) or die $!;

    return unless $client_ip;

    warn("$$ found ip $client_ip for mac $client_mac") if DEBUG;

    return $client_ip;
}



1;

__END__


=cut

    # throttling code

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

	# keep a three deep history of previous urls, first_url is the first one seen
	if (exists $attempts->{middle_url}) {
		$attempts->{bottom_url} = $attempts->{middle_url};
	}
	$attempts->{middle_url} = $attempts->{top_url};
	$attempts->{top_url} = $dest_url;

	$c->pnotes($c->remote_ip => $attempts);
	if ($total_time != 0) {

		# three of the same urls in a row is a violation

		if (exists $attempts->{bottom_url}) {

			if (($attempts->{bottom_url} eq $attempts->{middle_url}) &&
		   	    ($attempts->{middle_url} eq $attempts->{top_url})) {

			    	# three requests the same in less than 5 seconds means 503
				if (($times[$#times] - $times[$#times-2]) < 5) {

					$r->log->error("triple rate violation ip $ip, mac $mac, url $dest_url");
					return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
				}
			}
		}

		my $rate = ($count / $total_time);
		$r->log->debug("throttle check mac $mac, ip $ip, count $count, time $total_time, rate $rate") if DEBUG;

		if (($count > $Min_count) && ($rate > $Max_rate)) {

			$r->log->error("rate violation ip $ip, mac $mac, time $total_time, count $count, rate $rate, url $dest_url");
			return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
		}
	}
    } else {
	  my %attempts = ( 'count' => 1, 'times' => [ time() ], 'top_url' => $dest_url );
	  $r->log->debug("setting new limit check for ip $ip, count 1, time " . time()) if DEBUG;
  	  $c->pnotes($c->remote_ip => \%attempts);
   }

=cut



package SL::CP;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::Connection ();
use Apache2::Const -compile => qw( NOT_FOUND OK REDIRECT SERVER_ERROR );
use Apache2::Log ();

use SL::Config       ();
use SL::CP::IPTables ();

our $VERSION = 0.01;

our ( $Config, $Ad_post_auth_url, $Ad_auth_url, $Paid_post_auth_url,
    $Lease_file, $Auth_url, $Auth_token_url );

BEGIN {
    $Config             = SL::Config->new;
    $Auth_url           = $Config->sl_cp_auth_url || die 'oops';
    $Ad_post_auth_url   = $Config->sl_cp_ad_post_url || die 'oops';
    $Paid_post_auth_url = $Config->sl_cp_paid_post_url || die 'oops';
    $Lease_file         = $Config->sl_dhcp_lease_file || die 'oops';
}

sub handler {
    my $r = shift;

    my $mac = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    # at this point the mac obviously has not been put into a rule chain
    # so redirect to the auth server

    $r->headers_out->set( Location => $Auth_url . '/' . $mac );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub ads {
    my ( $class, $r ) = @_;

    my ($mac, $ip) = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    eval { SL::CP::IPTables->add_to_ads_chain($mac); };

    if ($@) {

        $r->log->error("$$ error adding mac $mac to ads chain: $@");
        return Apache2::Const::SERVER_ERROR;
    }

    $r->log->info("$$ added mac $mac to ad supported chain");

    $r->headers_out->set( Location => $Ad_post_auth_url );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub paid {
    my ( $class, $r ) = @_;

    my ($mac, $ip) = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $token = $r->args();

    eval { SL::CP::IPTables->add_to_paid_chain($mac, $ip, $token); };

    if ($@) {

        $r->log->error("$$ error adding mac $mac to paid chain: $@");
        return Apache2::Const::SERVER_ERROR;
    }

    $r->log->info("$$ added mac $mac to paid chain");

    $r->headers_out->set( Location => $Paid_post_auth_url );
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

    return ($mac, $ip);
}

1;

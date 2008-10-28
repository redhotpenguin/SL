package SL::CP;

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::Connection ();
use Apache2::Const -compile => qw( NOT_FOUND OK REDIRECT );
use Apache2::Log ();

use SL::Config       ();
use SL::CP::IPTables ();

our $Config;

BEGIN {
    $Config = SL::Config->new;
}

sub handler {
    my $r = shift;

    my $mac = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    # at this point the mac obviously has not been put into a rule chain
    # so redirect to the auth server

    $r->headers_out->set( Location => $Config->sl_cp_auth_url . '/' . $mac );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub ads {
    my ( $class, $r ) = @_;

    my $mac = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $added =
      SL::CP::IPTables->add_to_ad_chain($mac)
      $r->log->info("$$ added mac $mac to ad supported chain");

    $r->headers_out->set( Location => $Config->sl_cp_ad_post_auth_url );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub paid {
    my ( $class, $r ) = @_;

    my $mac = _mac_from_ip($r);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $added =
      SL::CP::IPTables->add_to_paid_chain($mac)
      $r->log->info("$$ added mac $mac to paid chain");

    $r->headers_out->set( Location => $Config->sl_cp_paid_post_auth_url );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub _mac_from_ip {
    my $r = shift;

    # get the ip
    my $ip = $r->connection->remote_ip;

    my $lease_file = $Config->sl_dhcp_lease_file;
    my $lease      = `grep $ip $lease_file`;

    unless ($lease) {
        $r->log->error("$$ oops no lease found for ip $ip");
        return;
    }

    my ($mac) = $lease =~ m/^\d+\s(\S+)\s/;
    unless ($mac) {
        $r->log->error("$$ woah error extracting mac from lease $lease");
        return;
    }

    $r->log->info("$$ found mac address $mac for ip $ip");

    return $mac;
}

1;

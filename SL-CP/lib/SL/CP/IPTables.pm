package SL::CP::IPTables;

use strict;
use warnings;

use SL::Config     ();
use LWP::UserAgent ();
use Crypt::SSLeay  ();
use URI::Escape    ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our (
    $Config,                  $Iptables,   $Ext_if,
    %tables_chains,           $Int_if,     $Auth_ip,
    $Cp_server_port,          $Gateway_ip, $Ad_proxy,
    $Mark_op,                 $Auth_url,   $Lease_file,
    $Verify_authorize_net_ip, $Aircloud_ip,
);

BEGIN {
    $Config                  = SL::Config->new;
    $Iptables                = $Config->sl_iptables || die 'oops';
    $Ext_if                  = $Config->sl_ext_if || die 'oops';
    $Int_if                  = $Config->sl_int_if || die 'oops';
    $Auth_ip                 = $Config->sl_auth_server_ip || die 'oops';
    $Verify_authorize_net_ip = $Config->sl_verify_authorize_net_ip
      || die 'oops';
    $Aircloud_ip    = $Config->sl_aircloud_ip     || die 'oops';
    $Auth_url       = $Config->sl_cp_auth_url     || die 'oops';
    $Cp_server_port = $Config->sl_apache_listen   || die 'oops';
    $Gateway_ip     = $Config->sl_gateway_ip      || die 'oops';
    $Ad_proxy       = $Config->sl_proxy           || die 'oops';
    $Mark_op        = $Config->sl_mark_op         || die 'oops';
    $Lease_file     = $Config->sl_dhcp_lease_file || die 'oops';

    %tables_chains = (
        filter => [qw( slAUT slAUTads slNET slRTR )],
        mangle => [qw( slBLK slINC slOUT slTRU )],
        nat    => [qw( slOUT slADS )],
    );

}

our $UA = LWP::UserAgent->new;
$UA->timeout(60);

our $Paid_mark = '0x400';
our $Ads_mark  = '0x500';

our $Zendesk_ip = '65.74.185.41';
our $Googleajax_ip = '74.125.19.95';

sub init_firewall {
    my $class = shift;

    $class->clear_firewall();

    # create the chains
    foreach my $table ( sort keys %tables_chains ) {
        foreach my $chain ( @{ $tables_chains{$table} } ) {

            iptables("-t $table -N $chain");
        }
    }

    ##############################
    # add the filter default chains
    my $filters = <<"FILTERS";
INPUT -i $Int_if -j slRTR
FORWARD -i $Int_if -j slNET
slAUT --protocol tcp --source-port ! 25 -j ACCEPT
slAUTads -m state --state RELATED,ESTABLISHED -j ACCEPT
slAUTads -p tcp -m tcp --dport 53 -j ACCEPT 
slAUTads -p udp -m udp --dport 53 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 80 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 443 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 465 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 587 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 8136 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 587 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 22 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 110 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 143 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 1723 -j ACCEPT 
slAUTads -p udp -m udp --dport 1701 -j ACCEPT 
slAUTads -p udp -m udp --dport 500 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 3389 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 993 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 995 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5050 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5190 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5222 -j ACCEPT 
slAUTads -p tcp -m tcp --dport 5223 -j ACCEPT 
slAUTads  -j REJECT --reject-with icmp-port-unreachable
slNET -m mark --mark 0x100/0x700 -j DROP
slNET -m state --state INVALID -j DROP
slNET -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
slNET -m mark --mark 0x200/0x700 -j ACCEPT
slNET -m mark --mark 0x400/0x700 -j slAUT
slNET -m mark --mark 0x500/0x700 -j slAUTads
slNET -p tcp -m tcp --dport 53 -j ACCEPT
slNET -p udp -m udp --dport 53 -j ACCEPT
slNET -d $Auth_ip -p tcp -m tcp --dport 443 -j ACCEPT
slNET -d $Verify_authorize_net_ip -p tcp -m tcp --dport 443 -j ACCEPT
slNET -d 69.36.240.30 -p tcp -m tcp --dport 443 -j ACCEPT
slNET -d 69.36.240.30 -p tcp -m tcp --dport 80 -j ACCEPT
slNET -d 69.36.240.28 -p tcp -m tcp --dport 80 -j ACCEPT
slNET -d 69.36.240.29 -p tcp -m tcp --dport 80 -j ACCEPT
slNET -d 69.36.240.29 -p tcp -m tcp --dport 443 -j ACCEPT
slNET -d $Zendesk_ip -p tcp -m tcp --dport 443 -j ACCEPT
slNET -d $Googleajax_ip -p tcp -m tcp --dport 80 -j ACCEPT
slNET -d $Googleajax_ip -p tcp -m tcp --dport 443 -j ACCEPT
slNET -d 69.42.24.27 -p tcp -m tcp --dport 80 -j ACCEPT
slNET -d 69.42.25.1 -p tcp -m tcp --dport 80 -j ACCEPT
slNET -d 69.42.24.3 -p tcp -m tcp --dport 80 -j ACCEPT
slNET -j REJECT --reject-with icmp-port-unreachable
slRTR -m mark --mark 0x100/0x700 -j DROP
slRTR -m state --state INVALID -j DROP
slRTR -m state --state RELATED,ESTABLISHED -j ACCEPT
slRTR -p tcp -m tcp ! --tcp-option 2 --tcp-flags SYN SYN -j DROP
slRTR -m mark --mark 0x200/0x700 -j ACCEPT
slRTR -p tcp -m tcp --dport 22 -j ACCEPT
slRTR -p tcp -m tcp --dport 20022 -j ACCEPT
slRTR -p tcp -m tcp --dport 8135 -j ACCEPT
slRTR -p tcp -m tcp --dport $Cp_server_port -j ACCEPT
slRTR -p udp -m udp --dport 67 -j ACCEPT
slRTR -j REJECT --reject-with icmp-port-unreachable
FILTERS

    add_rules( 'filter', $filters );

    #############################
    # default mangle chains
    my $mangles = <<"MANGLES";
PREROUTING -i $Int_if -j slOUT
PREROUTING -i $Int_if -j slBLK
PREROUTING -i $Int_if -j slTRU
POSTROUTING -o $Ext_if -j slINC
MANGLES

    add_rules( 'mangle', $mangles );

    #############################
    # default nat chains
    my $nats = <<"NATS";
PREROUTING -i $Int_if -j slOUT
POSTROUTING -o $Ext_if -j MASQUERADE
slOUT -m mark --mark 0x200/0x700 -j ACCEPT
slOUT -m mark --mark $Paid_mark/0x700 -j ACCEPT
slOUT -m mark --mark $Ads_mark/0x700 -j slADS
slOUT -p tcp -m tcp --dport 53 -j ACCEPT
slOUT -p udp -m udp --dport 53 -j ACCEPT
slOUT -d $Auth_ip -p tcp -m tcp --dport 443 -j ACCEPT
slOUT -p tcp -m tcp --dport 80 -j DNAT --to-destination $Gateway_ip:$Cp_server_port
slOUT -j ACCEPT
slADS -p tcp -m tcp --dport 80 -j DNAT --to-destination $Ad_proxy
slADS -p tcp -m tcp --dport 8135 -j DNAT --to-destination :80
slADS -j ACCEPT
NATS

    add_rules( 'nat', $nats );

}

sub add_rules {
    my ( $table, $rules ) = @_;

    foreach my $rule ( split( /\n/, $rules ) ) {
        chomp($rule);
        warn("$$ Adding rule $rule to table $table") if DEBUG;
        iptables("-t $table -A $rule");
    }
}

sub clear_firewall {
    my $class = shift;

    # clear all tables
    iptables("-t $_ -F") for keys %tables_chains;

    # clear all chains
    iptables("-t $_ -X") for keys %tables_chains;

    # reset the postrouting rule
    iptables("-t nat -A POSTROUTING -o $Ext_if -j MASQUERADE");
}

sub iptables {
    my $cmd = shift;

    system("sudo $Iptables $cmd") == 0
      or require Carp
      && Carp::confess "could not iptables '$cmd', err: $!, ret: $?\n";

    return 1;
}

sub check_for_ads_mac {
    my ( $class, $mac, $ip ) = @_;

    warn("check for ads mac $mac, ip $ip ") if DEBUG;
    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/check?mac=$esc_mac&plan=ads";

    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {

        # no mac authenticated
        return $res->code;

    }
    elsif ( !$res->is_success ) {

        # huh something broke
        require Data::Dumper;
        die "$$ Error checking ads mac $mac, response: "
          . Data::Dumper::Dumper($res);
    }

    warn( "mac check response code " . $res->code ) if DEBUG;

    # successful request, make sure the rules are ok
    my $uc_mac        = uc($mac);
    my $iptables_rule = `sudo $Iptables -t mangle -L -v`;

    # see if the mac address is in a rule
    my ($iptables_ip) =
      $iptables_rule =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s+$uc_mac/i;

    if ( !$iptables_ip ) {

        warn("no iptables rules, creating one") if DEBUG;

        # probably a server restart, re-add the rules
        $class->_ads_chain( 'A', $mac, $ip );

    }
    elsif ( $ip ne $iptables_ip ) {
        warn("iptables rules don't match, updating") if DEBUG;

        # dhcp lease probably expired, delete old rule, create new rule
        $class->delete_from_ads_chain( $mac, $iptables_ip );
        $class->_ads_chain( 'A', $mac, $ip );

    }

    return 1;
}

sub _mac_check {
    my ( $class, $mac ) = @_;

    die "no mac passed to _mac_check" unless $mac;

    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/check?mac=$esc_mac";

    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {

        # no mac authenticated
        return $res->code;

    }
    elsif ( !$res->is_success ) {

        # huh something broke
        require Data::Dumper;
        die "$$ Error checking mac $mac, response: "
          . Data::Dumper::Dumper($res);
    }

    return 1;
}

sub check_for_paid_mac {
    my ( $class, $mac, $ip ) = @_;

    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/check?mac=$esc_mac";

    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {

        # no mac authenticated
        return $res->code;

    }
    elsif ( !$res->is_success ) {

        # huh something broke
        require Data::Dumper;
        die "$$ Error checking mac $mac, response: "
          . Data::Dumper::Dumper($res);
    }

    warn( "mac check response code " . $res->code ) if DEBUG;

    # successful request, make sure the rules are ok
    my $uc_mac        = uc($mac);
    my $iptables_rule = `sudo $Iptables -t mangle -L -v`;

    # see if the mac address is in a rule
    my ($iptables_ip) =
      $iptables_rule =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s+$uc_mac/i;

    if ( !$iptables_ip ) {

        warn("no iptables rules, creating one") if DEBUG;

        # probably a server restart, re-add the rules
        $class->_paid_chain( 'A', $mac, $ip );

    }
    elsif ( $ip ne $iptables_ip ) {
        warn("iptables rules don't match, updating") if DEBUG;

        # dhcp lease probably expired, delete old rule, create new rule
        $class->delete_from_paid_chain( $mac, $iptables_ip );
        $class->_paid_chain( 'A', $mac, $ip );

    }

    return 1;
}

sub paid_users {
    my ($class) = @_;

    return $class->users('0x400');
}

sub ads_users {
    my ($class) = @_;

    return $class->users('0x500');
}

sub users {
    my ( $class, $mark ) = @_;

    my @users =
      map { [ $_ =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s(\S+)\s/ ] }
      grep { $_ =~ m/(?:$mark)/ }
      split( '\n', `sudo $Iptables -t mangle --list` );

    return @users;
}

sub _paid_chain {
    my ( $class, $op, $mac, $ip ) = @_;
    iptables(
"-t mangle -$op slOUT -s $ip -m mac --mac-source $mac -j MARK $Mark_op 0x400"
    );
    iptables("-t mangle -$op slINC -d $ip -j ACCEPT");
}

sub add_to_paid_chain {
    my ( $class, $mac, $ip, $token ) = @_;

    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/token?mac=$esc_mac&token=$token";
    warn("token url is $url") if DEBUG;

    # fetch the token and validate
    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {
        return $res->code;
    }

    die "error validating mac $mac with token $token:  " . $res->status_line
      unless $res->is_success;

    # see if this mac is already in the ads chain
    my $ads_ip = $class->check_ads_chain_for_mac( $mac );
    if ($ads_ip) {
      warn("deleting mac $mac, ip $ip from ads chain, paid upgrade");
      $class->delete_from_ads_chain( $mac, $ads_ip );
    }

    # add the mac to the paid chain
    $class->_paid_chain( 'A', $mac, $ip );

    return 1;
}

sub delete_from_paid_chain {
    my ( $class, $mac, $ip ) = @_;

    $class->_paid_chain( 'D', $mac, $ip );
}

sub check_paid_chain_for_mac {
    my ($class, $mac ) = @_;

    my $ip = $class->_check_chain_for_mac( $Paid_mark, $mac );

    return unless $ip;

    return $ip
}

sub _check_chain_for_mac {
    my ($class, $mark, $mac) = @_;

    $mac = uc($mac);

    my @lines = split( '\n', `sudo $Iptables -t mangle --list` );
    
    my $ip;
    foreach my $line (@lines) {
	next unless $line =~ m/^MARK/;
	last if ($ip) =
		$line =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*?MAC\s+$mac/i;
    }

    return unless $ip;

   unless ($ip) {
      warn("no ip could be found in iptables for mac $mac");
      return;
    }

    return unless $ip;

    return $ip;
}


sub check_ads_chain_for_mac {
    my ( $class, $mac ) = @_;

    my $ip = $class->_check_chain_for_mac( $Ads_mark, $mac );

    return unless $ip;

    return $ip;
}

sub add_to_ads_chain {
    my ( $class, $mac, $ip, $token ) = @_;

    my $esc_mac = URI::Escape::uri_escape($mac);
    my $url     = "$Auth_url/token?mac=$esc_mac&token=$token";
    warn("token url is $url") if DEBUG;

    # fetch the token and validate
    my $res = $UA->get($url);

    if ( ( $res->code == 404 ) or ( $res->code == 401 ) ) {
        return $res->code;
    }

    die "error validating mac $mac with token $token:  " . $res->status_line
      unless $res->is_success;

    $class->_ads_chain( 'A', $mac, $ip );
}

sub delete_from_ads_chain {
    my ( $class, $mac, $ip ) = @_;
    $class->_ads_chain( 'D', $mac, $ip );
}

sub _ads_chain {
    my ( $class, $op, $mac, $ip ) = @_;

    iptables(
"-t mangle -$op slOUT -s $ip -m mac --mac-source $mac -j MARK $Mark_op 0x500"
    );
    iptables("-t mangle -$op slINC -d $ip -j ACCEPT");
}

1;

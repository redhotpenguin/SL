package SL::CP::IPTables;

use strict;
use warnings;

use SL::Config     ();
use LWP::UserAgent ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our (
    $Config,   $Iptables, $Ext_if,         %tables_chains,
    $Int_if,   $Auth_ip,  $Cp_server_port, $Gateway_ip,
    $Ad_proxy, $Mark_op,  $Auth_token_url,
);

BEGIN {
    $Config         = SL::Config->new;
    $Iptables       = $Config->sl_iptables || die 'oops';
    $Ext_if         = $Config->sl_ext_if || die 'oops';
    $Int_if         = $Config->sl_int_if || die 'oops';
    $Auth_ip        = $Config->sl_auth_server_ip || die 'oops';
    $Auth_token_url = $Config->sl_cp_auth_token_url || die 'oops';
    $Cp_server_port = $Config->sl_apache_listen || die 'oops';
    $Gateway_ip     = $Config->sl_gateway_ip || die 'oops';
    $Ad_proxy       = $Config->sl_proxy || die 'oops';
    $Mark_op        = $Config->sl_mark_op || die 'oops';

    %tables_chains = (
        filter => [qw( slAUT slNET slRTR )],
        mangle => [qw( slBLK slINC slOUT slTRU )],
        nat    => [qw( slOUT slADS )],
    );

}

our $UA = LWP::UserAgent->new;
$UA->timeout(60);

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
slAUT -m state --state RELATED,ESTABLISHED -j ACCEPT
slAUT -p tcp -m tcp --dport 53 -j ACCEPT 
slAUT -p udp -m udp --dport 53 -j ACCEPT 
slAUT -p tcp -m tcp --dport 80 -j ACCEPT 
slAUT -p tcp -m tcp --dport 443 -j ACCEPT 
slAUT -p tcp -m tcp --dport 22 -j ACCEPT 
slAUT -p tcp -m tcp --dport 143 -j ACCEPT 
slAUT -p tcp -m tcp --dport 993 -j ACCEPT 
slAUT -p tcp -m tcp --dport 587 -j ACCEPT 
slAUT -p tcp -m tcp --dport 25 -j ACCEPT 
slAUT -j REJECT --reject-with icmp-port-unreachable
slNET -m mark --mark 0x100/0x700 -j DROP
slNET -m state --state INVALID -j DROP
slNET -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
slNET -m mark --mark 0x200/0x700 -j ACCEPT
slNET -m mark --mark 0x400/0x700 -j slAUT
slNET -m mark --mark 0x500/0x700 -j slAUT
slNET -p tcp -m tcp --dport 53 -j ACCEPT
slNET -p udp -m udp --dport 53 -j ACCEPT
slNET -d $Auth_ip -p tcp -m tcp --dport 443 -j ACCEPT
slNET -j REJECT --reject-with icmp-port-unreachable
slRTR -m mark --mark 0x100/0x700 -j DROP
slRTR -m state --state INVALID -j DROP
slRTR -m state --state RELATED,ESTABLISHED -j ACCEPT
slRTR -p tcp -m tcp ! --tcp-option 2 --tcp-flags SYN SYN -j DROP
slRTR -m mark --mark 0x200/0x700 -j ACCEPT
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
slOUT -m mark --mark 0x400/0x700 -j ACCEPT
slOUT -m mark --mark 0x500/0x700 -j slADS
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

    foreach my $rule (split(/\n/, $rules)) {
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
      or require Carp && Carp::confess "could not iptables '$cmd', err: $!, ret: $?\n";

    return 1;
}

sub add_to_paid_chain {
    my ( $class, $mac, $ip, $token ) = @_;

    # fetch the token and validate
    my $res = $UA->get( $Auth_token_url . '?mac=' . $mac . '&token=' . $token );

    die "error validating mac $mac with token $token:  " . $res->status_line
      unless $res->is_success;

    iptables("-t mangle -A slOUT -s $ip -m mac --mac-source $mac -j MARK $Mark_op 0x400");
    iptables("-t mangle -A slINC -d $ip -j ACCEPT");
}

sub add_to_ads_chain {
    my ( $class, $mac, $ip ) = @_;
#iptables -t mangle -A ndsOUT -s 10.0.0.146 -m mac --mac-source 00:15:58:83:0C:FF -j MARK --or-mark 0x500
    iptables("-t mangle -A slOUT -s $ip -m mac --mac-source $mac -j MARK $Mark_op 0x500");
    iptables("-t mangle -A slINC -d $ip -j ACCEPT");
}

1;
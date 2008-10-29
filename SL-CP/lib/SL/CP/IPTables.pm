package SL::CP::IPTables;

use strict;
use warnings;

use SL::Config ();

use constant DEBUG => $ENV{SL_DEBUG} || 0;

our (
    $Config,   $Iptables, $Ext_if,         %tables_chains,
    $Int_if,   $Auth_ip,  $Cp_server_port, $Gateway_ip,
    $Ad_proxy, $Mark_op
);

BEGIN {
    $Config         = SL::Config->new;
    $Iptables       = $Config->sl_iptables || 'oops';
    $Ext_if         = $Config->sl_ext_if || die 'oops';
    $Int_if         = $Config->sl_int_if || die 'oops';
    $Auth_ip        = $Config->sl_auth_server_ip || die 'oops';
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

sub init_firewall {

    clear_firewall();

    # create the chains
    foreach my $table ( sort keys %tables_chains ) {
        foreach my $chain ( @{ $tables_chains{$table} } ) {

            do_iptables("-t $table -N $chain");
        }
    }

    ##############################
    # add the filter default chains
    my $filters = <<"FILTERS";
INPUT -i $Int_if -j slRTR
FORWARD -i $Int_if -j slNET
slAUT -m state --state RELATED,ESTABLISHED -j ACCEPT
slAUT -j REJECT --reject-with icmp-port-unreachable
slAUT -m mark --mark 0x100/0x700 -j DROP
slNET -m state --state INVALID -j DROP
slNET -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
slNET -m mark --mark 0x200/0x700 -j ACCEPT
slNET -m mark --mark 0x400/0x700 -j slAUT
slNET -m mark --mark 0x500/0x700 -j slAUT
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

    foreach my $rule (<$rules>) {
        chomp($rule);
        warn("$$ Adding rule $rule to table $table") if DEBUG;
        do_iptables("-t $table -A $rule");
    }
}

sub iptables {
    my $cmd = shift;

    system("$Iptables $cmd") == 0
      or die "could not iptables '$cmd', err: $!, ret: $?\n";

    return 1;
}

sub clear_firewall {

    # clear all tables
    iptables("-t $_ -F") for keys %tables_chains;

    # clear all chains
    iptables("-X");

    # reset the postrouting rule
    iptables("-t nat -A POSTROUTING -o $Ext_if -j MASQUERADE");
}

sub add_to_paid_chain {
    my ( $mac, $ip ) = @_;

    do_iptables(
"-t mangle -A slNET -s $ip -m mac --mac-source $mac -j MARK $Mark_op 0x500"
    );
    do_iptables("-t mangle -A slINC -d $ip -j ACCEPT");

}

sub add_to_ads_chain {
    my ( $mac, $ip ) = @_;

    do_iptables(
"-t mangle -D slNET -s $ip -m mac --mac-source $mac -j MARK $Mark_op 0x500"
    );
    do_iptables("-t mangle -D slINC -d $ip -j ACCEPT");

}

1;

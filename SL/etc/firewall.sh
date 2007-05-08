#!/bin/bash

BLOCK_LIST=""
TCP_IN="20 21 25 53 80 110 143 443 993 995 7777 10000 19638"
TCP_OUT="21 25 37 43 53 80 443 55000"
UDP_IN="53 123"
UDP_OUT="53 123"
ETH_WAN="$ETH_WAN"
ETH_LAN="$ETH_LAN"
TCP_IN_TRUSTED="22"
TRUSTED_IPS="0.0.0.0/0"
SERVER_IPS="0.0.0.0/0"
EXTN="ko"
IPTABLES="/sbin/iptables"
MODPROBE="/sbin/modprobe"
LOOPBACK="127.0.0.0/8"
CLASS_A="10.0.0.0/8"
CLASS_B="172.16.0.0/12"
CLASS_C="192.168.0.0/16"
CLASS_D_MULTICAST="224.0.0.0/4"
CLASS_E_RESERVED_NET="240.0.0.0/4"
BROADCAST_SRC="0.0.0.0"
BROADCAST_DEST="255.255.255.255"
PRIVPORTS="0:1023"
UNPRIVPORTS="1024:65535"

##############################################################################
# Determine if iptables and modprobe exist
#
if [ ! -e "$IPTABLES" ]; then
    echo "$IPTABLES does not exist. Firewall script aborted!"
    exit 1
fi
if [ ! -e "$MODPROBE" ]; then
    echo "$MODPROBE does not exist. Firewall script aborted!"
    exit 1
fi

##############################################################################
# Determine MAIN_IP & SERVER_IPS if needed
#
MAIN_IP=`ifconfig $ETH_WAN | grep "inet addr" | cut -d: -f2 | awk '{print $1}'`
if [ "$MAIN_IP" == "" ]; then
    echo "Could not determine MAIN_IP. Firewall script aborted!"
    exit 1
fi
if [ "$SERVER_IPS" == "" ]; then
    SERVER_IPS=$MAIN_IP
fi
if [ "$SERVER_IPS" == "" ]; then
    echo "Could not determine SERVER_IPS. Firewall script aborted!"
    exit 1
fi

##############################################################################
# Arguments:
if [ "$1" == "stop" ] || [ "$1" == "-stop" ] || [ "$1" == "--stop" ]; then
    $IPTABLES -P INPUT ACCEPT
    $IPTABLES -P OUTPUT ACCEPT
    $IPTABLES -F
    $IPTABLES -L -n
    echo ""
    echo ""
    echo -e "\033[31mKISS My Firewall - Stopped!"
    echo -e -n "\033[0m "
    echo ""
    exit 0
fi
if [ "$1" == "status" ] || [ "$1" == "-status" ] || [ "$1" == "--status" ]; then
    NUM_LINES=`$IPTABLES -L -n | wc -l | awk '{print $1}'`
    $IPTABLES -L -n
    echo ""
    echo ""
    if [ "$NUM_LINES" -le "15" ]; then
        echo -e "\033[31mKISS My Firewall - Stopped!"
    else
        echo -e "\033[32mKISS My Firewall - Running!"
    fi
    echo -e -n "\033[0m "
    echo ""
    exit 0
fi

##############################################################################
# We don't want ipchains loaded:
IPCHAINS=`/sbin/lsmod | grep ipchains`
if [ ! "$IPCHAINS" == "" ]; then
    /sbin/rmmod ipchains
fi

##############################################################################
if [ ! -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ip_tables.$EXTN" ] || [ ! -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_state.$EXTN" ] || [ ! -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_multiport.$EXTN" ]; then
    echo "missing modules, aborting"
  exit 1
fi

# All is well, load modules:
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ip_tables.$EXTN" ]; then
    $MODPROBE ip_tables
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_state.$EXTN" ]; then
    $MODPROBE ipt_state
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_multiport.$EXTN" ]; then
    $MODPROBE ipt_multiport
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ip_tables.$EXTN" ]; then
    $MODPROBE ip_tables
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_state.$EXTN" ]; then
    $MODPROBE ipt_state
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_multiport.$EXTN" ]; then
    $MODPROBE ipt_multiport
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/iptable_filter.$EXTN" ]; then
    $MODPROBE iptable_filter
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_unclean.$EXTN" ]; then
    $MODPROBE ipt_unclean
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_limit.$EXTN" ]; then
    $MODPROBE ipt_limit
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_LOG.$EXTN" ]; then
    $MODPROBE ipt_LOG
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ipt_REJECT.$EXTN" ]; then
    $MODPROBE ipt_REJECT
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ip_conntrack.$EXTN" ]; then
    $MODPROBE ip_conntrack
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ip_conntrack_irc.$EXTN" ]; then
    $MODPROBE ip_conntrack_irc
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/ip_conntrack_ftp.$EXTN" ]; then
    $MODPROBE ip_conntrack_ftp
fi
if [ -e "/lib/modules/$(uname -r)/kernel/net/ipv4/netfilter/iptable_mangle.$EXTN" ]; then
    $MODPROBE iptable_mangle
fi

##############################################################################
# Remove any existing rules from all chains
$IPTABLES --flush
$IPTABLES -t nat --flush
$IPTABLES -t mangle --flush

# Allow unlimited traffic on the loopback interface
$IPTABLES -A INPUT  -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Set the default policy to DROP
$IPTABLES --policy INPUT   DROP
$IPTABLES --policy OUTPUT  DROP
$IPTABLES --policy FORWARD DROP

# DO NOT MODIFY THESE!
#
# If you set these to DROP, you will be locked out of your server.
#
$IPTABLES -t nat --policy PREROUTING ACCEPT
$IPTABLES -t nat --policy OUTPUT ACCEPT
$IPTABLES -t nat --policy POSTROUTING ACCEPT
$IPTABLES -t mangle --policy PREROUTING ACCEPT
$IPTABLES -t mangle --policy OUTPUT ACCEPT

# Remove any pre-existing user-defined chains
$IPTABLES --delete-chain
$IPTABLES -t nat --delete-chain
$IPTABLES -t mangle --delete-chain

##############################################################################
# Enable broadcast echo Protection
if [ -e /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts ]; then
    echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
fi

# Disable Source Routed Packets
if [ -e /proc/sys/net/ipv4/conf/all/accept_source_route ]; then
    echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route
fi

# Enable TCP SYN Cookie Protection
if [ -e /proc/sys/net/ipv4/tcp_syncookies ]; then
    echo "1" > /proc/sys/net/ipv4/tcp_syncookies
fi

# Disable ICMP Redirect Acceptance
if [ -e /proc/sys/net/ipv4/conf/all/accept_redirects ]; then
    echo "0" > /proc/sys/net/ipv4/conf/all/accept_redirects
fi

# Don't send Redirect Messages
if [ -e /proc/sys/net/ipv4/conf/all/send_redirects ]; then
  echo "0" > /proc/sys/net/ipv4/conf/all/send_redirects
fi


# Drop Spoofed Packets coming in on an interface, which if replied to, would
# result in the reply going out a different interface.
if [ -e /proc/sys/net/ipv4/conf/all/rp_filter ]; then
    echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter
fi

# Log packets with impossible addresses
if [ -e /proc/sys/net/ipv4/conf/all/log_martians ]; then
    echo "1" > /proc/sys/net/ipv4/conf/all/log_martians
fi


# Reduce DoS'ing ability by reducing timeouts
if [ -e /proc/sys/net/ipv4/tcp_fin_timeout ]; then
  echo "1800" > /proc/sys/net/ipv4/tcp_fin_timeout
fi
if [ -e /proc/sys/net/ipv4/tcp_keepalive_time ]; then
  echo "1800" > /proc/sys/net/ipv4/tcp_keepalive_time
fi
if [ -e /proc/sys/net/ipv4/tcp_window_scaling ]; then
  echo "0" > /proc/sys/net/ipv4/tcp_window_scaling
fi
if [ -e /proc/sys/net/ipv4/tcp_sack ]; then
  echo "0" > /proc/sys/net/ipv4/tcp_sack
fi

##############################################################################
# Silently Drop Stealth Scans

# All of the bits are cleared
$IPTABLES -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# SYN and FIN are both set
$IPTABLES -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

# SYN and RST are both set
$IPTABLES -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# FIN and RST are both set
$IPTABLES -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

# FIN is the only bit set, without the expected accompanying ACK
$IPTABLES -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP

# PSH is the only bit set, without the expected accompanying ACK
$IPTABLES -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP

# URG is the only bit set, without the expected accompanying ACK
$IPTABLES -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP

##############################################################################
# Provide some syn-flood protection
#
# THIS CODE SLOWS DOWN WEB PAGE LOADS DRAMATICALLY!!!
#
# Only enable this code if you find that you are the victim of a syn-flood
# attack!
#
#$IPTABLES -N syn-flood
#$IPTABLES -A INPUT -p tcp --syn -j syn-flood
#$IPTABLES -A syn-flood -m limit --limit 1/s --limit-burst 4 -j RETURN
#$IPTABLES -A syn-flood -j DROP

##############################################################################
# BLOCK_LIST
#
# To add someone to this block list, use the BLOCK_LIST configuration variable
# above.
#
# We block here, before our stateful packet inspection below, because if the 
# offender is already logged in, he won't be kicked out. Note also that we
# include the offender's IP in the OUTPUT chain. This should help to reduce
# the threat a little bit more.
#
for blocked_ip in $BLOCK_LIST; do
    # Lock him out:
    $IPTABLES -A INPUT  -s $blocked_ip -j DROP
    # Make sure that he never hears from us again:
    $IPTABLES -A OUTPUT -d $blocked_ip -j DROP
done


##############################################################################
# Use Connection State to Bypass Rule Checking
#
# By accepting established and related connections, we don't need to
# explicitly set various input and output rules. For example, by accepting an
# established and related output connection, we don't need to specify that
# the firewall needs to open a hole back out to client when the client
# requests SSH access.
#
$IPTABLES -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPTABLES -A INPUT  -m state --state INVALID -j DROP
$IPTABLES -A OUTPUT -m state --state INVALID -j DROP


##############################################################################
# Source Address Spoofing and Other Bad Addresses
# Refuse Spoofed packets pretending to be from the external interface's IP
for server_ips in $SERVER_IPS; do
    $IPTABLES -A INPUT -i $ETH_WAN -s $server_ips -j DROP
done
for server_ips in $SERVER_IPS; do
    for subnet_broadcast in $SUBNET_BROADCAST; do 
        $IPTABLES -A INPUT -i $ETH_WAN -s $server_ips -d !$subnet_broadcast -j DROP
    done
done

# Refuse packets claiming to be from a Class A private network
$IPTABLES -A INPUT -i $ETH_WAN -s $CLASS_A -j DROP

# Refuse packets claiming to be from a Class B private network
$IPTABLES -A INPUT -i $ETH_WAN -s $CLASS_B -j DROP

# Refuse packets claiming to be from a Class C private network
#$IPTABLES -A INPUT -i $ETH_WAN -s $CLASS_C -j DROP

# Refuse packets claiming to be from the loopback interface
$IPTABLES -A INPUT -i $ETH_WAN -s $LOOPBACK -j DROP

# Refuse malformed broadcast packets
$IPTABLES -A INPUT -i $ETH_WAN -s $BROADCAST_DEST -j DROP
$IPTABLES -A INPUT -i $ETH_WAN -d $BROADCAST_SRC -j DROP

# Refuse directed broadcasts
# Used to map networks and in Denial of Service attacks
#for subnet_base in $SUBNET_BASE; do
#    $IPTABLES -A INPUT -i $ETH_WAN -d $subnet_base -j DROP
#done
#for subnet_broadcast in $SUBNET_BROADCAST; do
#    $IPTABLES -A INPUT -i $ETH_WAN -d $subnet_broadcast -j DROP
#done

# Refuse limited broadcasts
$IPTABLES -A INPUT -i $ETH_WAN -d $BROADCAST_DEST -j DROP

# Refuse Class D multicast addresses - illegal as a source address
$IPTABLES -A INPUT -i $ETH_WAN -s $CLASS_D_MULTICAST -j DROP
$IPTABLES -A INPUT -i $ETH_WAN -p udp -d $CLASS_D_MULTICAST -j ACCEPT
$IPTABLES -A INPUT -i $ETH_WAN -p 2 -d $CLASS_D_MULTICAST -j ACCEPT
$IPTABLES -A INPUT -i $ETH_WAN -p all  -d $CLASS_D_MULTICAST -j DROP
$IPTABLES -A INPUT -i $ETH_WAN -p ! udp -d $CLASS_D_MULTICAST -j DROP

# Refuse Class E reserved IP addresses
$IPTABLES -A INPUT -i $ETH_WAN -s $CLASS_E_RESERVED_NET -j DROP

# Refuse addresses defined as reserved by the IANA
# 0.*.*.*         - Can't be blocked unilaterally with DHCP
# 169.254.0.0/16  - Link Local Networks
# 192.0.2.0/24    - TEST-NET
$IPTABLES -A INPUT -i $ETH_WAN -s 0.0.0.0/8 -j DROP
$IPTABLES -A INPUT -i $ETH_WAN -s 169.254.0.0/16 -j DROP
$IPTABLES -A INPUT -i $ETH_WAN -s 192.0.2.0/24 -j DROP

##############################################################################
# If we are not accepting 113 (ident), then we explicitly reject it!
if [ "$(echo $IN_PORTS | tr ',' '\n' | grep -w 113)" == "" ]; then
    $IPTABLES -A INPUT -p tcp -s 0/0 -d 0/0 --dport 113 -j REJECT
    $IPTABLES -A INPUT -p udp -s 0/0 -d 0/0 --dport 113 -j REJECT
fi

##############################################################################
# TCP IN
for tcp_in in $TCP_IN; do
    for server_ips in $SERVER_IPS; do
        $IPTABLES -A INPUT -i $ETH_WAN -s 0/0 -d $server_ips -p tcp -m state --state NEW --sport $UNPRIVPORTS --dport $tcp_in -j ACCEPT
    done
done

##############################################################################
# TCP OUT
for tcp_out in $TCP_OUT; do
    $IPTABLES -A OUTPUT -o $ETH_WAN -p tcp -m state --state NEW --sport $UNPRIVPORTS --dport $tcp_out -j ACCEPT
done

##############################################################################
# UDP IN
for udp_in in $UDP_IN; do
    for server_ips in $SERVER_IPS; do
        $IPTABLES -A INPUT -i $ETH_WAN -s 0/0 -d $server_ips -p udp -m state --state NEW --sport $UNPRIVPORTS --dport $udp_in -j ACCEPT
    done
done

##############################################################################
# UDP OUT
for udp_out in $UDP_OUT; do
    $IPTABLES -A OUTPUT -o $ETH_WAN -p udp -m state --state NEW --sport $UNPRIVPORTS --dport $udp_out -j ACCEPT
done

##############################################################################
# TCP IN TRUSTED
#
for tcp_in_trusted in $TCP_IN_TRUSTED; do
    for server_ips in $SERVER_IPS; do
        for trusted_ips in $TRUSTED_IPS; do
            $IPTABLES -A INPUT -i $ETH_WAN -s $trusted_ips -d $server_ips -p tcp -m state --state NEW --sport $UNPRIVPORTS --dport $tcp_in_trusted -j ACCEPT
        done
    done
done

###############################################################################
# Allow pinging of this server's MAIN_IP by trusted IPs only.
for trusted_ips in $TRUSTED_IPS; do
    $IPTABLES -A INPUT -s $trusted_ips -d $MAIN_IP -i $ETH_WAN -m state --state NEW -p icmp --icmp-type ping -j ACCEPT
done

##############################################################################
# OUTPUT - PORT 113 - IDENTD
#
#for server_ips in $SERVER_IPS; do
#	$IPTABLES -A OUTPUT -o $ETH_WAN -s $server_ips -p tcp --syn --sport $UNPRIVPORTS --dport 113 -m state --state NEW -j REJECT --reject-with tcp-reset
#done

###############################################################################
# Allow DNS zone transfers
$IPTABLES -A INPUT -i $ETH_WAN -p udp --sport 53 --dport 53 -m state --state NEW -j ACCEPT
$IPTABLES -A INPUT -i $ETH_WAN -p tcp --sport 53 --dport 53 -m state --state NEW -j ACCEPT
$IPTABLES -A OUTPUT -o $ETH_WAN -p udp --sport 53 --dport 53 -m state --state NEW -j ACCEPT
$IPTABLES -A OUTPUT -o $ETH_WAN -p tcp --sport 53 --dport 53 -m state --state NEW -j ACCEPT

###############################################################################
# Uncomment to allow for outgoing ping
$IPTABLES -A OUTPUT -s $MAIN_IP -m state --state NEW -p icmp --icmp-type ping -j ACCEPT

###############################################################################
# Uncomment to allow outgoing traceroutes
$IPTABLES -A OUTPUT -o $ETH_WAN -p udp -s $MAIN_IP --sport 32769:65535 --dport 33434:33523 -m state --state NEW -j ACCEPT

###############################################################################
# Forward packets on port 8069 to 10.0.0.2
$IPTABLES -A PREROUTING -i $ETH_WAN -p tcp -m tcp --dport 8069 -j DNAT --to-destination 10.0.0.2:8069
$IPTABLES -A POSTROUTING -o $ETH_WAN -j MASQUERADE 

###############################################################################
# Allow ssh access to 10.0.0.2
$IPTABLES -A OUTPUT -o $ETH_LAN -p tcp -m state --state NEW --sport 22 --dport 22 -j ACCEPT

$IPTABLES -L -n
echo ""
echo ""
echo -e "trusted ips are $TRUSTED_IPS"
echo -e "main ip is $MAIN_IP"
echo -e "server ips are $SERVER_IPS"
echo -e -n "\033[0m "
echo ""

exit 0

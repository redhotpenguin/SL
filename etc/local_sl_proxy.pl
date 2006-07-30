#!/usr/bin/perl

# route packets from the local box through a remote SL server
# to turn it off, clear your rules:
#   iptables -F; iptables -t nat -F

# your local network setup
$LOCAL_IF  = "eth0";
$LOCAL_IP  = "192.168.2.5";
$LOCAL_NET = "127.0.0.1";

# the SL machine
$SL_IP     = "64.127.99.51";
$SL_PORT   = "8069";

system("iptables -t nat -F");  # clear tables
system("iptables -F");

system("iptables -t nat -A PREROUTING -i $LOCAL_IF -s ! $SL_IP -p tcp --dport 80 -j DNAT --to $SL_IP:$SL_PORT");
system("iptables -t nat -A OUTPUT -s ! $SL_IP -p tcp --dport 80 -j DNAT --to $SL_IP:$SL_PORT");
system("iptables -t nat -A POSTROUTING -o $LOCAL_IF -s $LOCAL_NET -d $SL_IP -j SNAT --to $LOCAL_IP");
system("iptables -A FORWARD -s $LOCAL_NET -d $SL_IP -i $LOCAL_IF -o $LOCAL_IF -p tcp --dport $SL_PORT -j ACCEPT");

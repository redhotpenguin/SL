#!/bin/sh
# remove old modules
sudo /sbin/rmmod nf_nat_sl
sudo /sbin/rmmod nf_conntrack_sl


make modules
sudo make modules_install

# load new modules
sudo /sbin/modprobe nf_nat_sl
sudo /sbin/modprobe nf_conntrack_sl




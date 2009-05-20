#!/bin/sh

VERSION=0.01
LICENSE="Copyright 2009 Silver Lining Networks, Inc."
DESCRIPTION="This program removes the Silver Lining ipkg onto open-mesh.com ROBIN enabled devices"

IPKG=/usr/bin/ipkg
echo "removing sln"
$($IPKG remove sln)

echo "removing kmod-sln"
$($IPKG remove kmod-sln)

echo "removing microperl"
$($IPKG remove microperl)

echo "rebooting"
/sbin/reboot

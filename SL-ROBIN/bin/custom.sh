#!/bin/sh

VERSION=0.01
LICENSE="Copyright 2009 Silver Lining Networks, Inc."
DESCRIPTION="This program installs the Silver Lining ipkg onto open-mesh.com ROBIN enabled devices"

MICROPERL_FILE=microperl_5.10.0-1_mips.ipk
KMODSLN_FILE=kmod-sln_2.6.23.17+0.20-atheros-5_mips.ipk
SLN_FILE=sln_0.20-5_mips.ipk

URL_MICROPERL=http://fw.slwifi.com/SL-ROBIN/perl/$MICROPERL_FILE
URL_KMODSLN=http://fw.slwifi.com/SL-ROBIN/sln/0.20-5_mips/$KMODSLN_FILE
URL_SLN=http://fw.slwifi.com/SL-ROBIN/sln/0.20-5_mips/$SLN_FILE

# shut down cron
echo "Starting SLN ipkg install, stopping cron"
/etc/init.d/cron stop

################################
# install microperl first
IPKG=microperl

# remove existing files
echo "removing old $IPKG files"
[ -e $MICROPERL_FILE ] && rm -f $MICROPERL_FILE
[ -e $MICROPERL_FILE.md5 ] && rm -f $MICROPERL_FILE.md5

# is $IPKG installed?  remove it
echo "checking for old $IPKG install"
[ "$(/usr/bin/ipkg list_installed $IPKG)" != 'Done.' ] && `/usr/bin/ipkg -V3 remove -force-depends $IPKG`

# grab the new package
echo "grabbing new $IPKG files"
wget "$URL_MICROPERL"
wget "$URL_MICROPERL.md5"

# check the md5
echo "checking md5s"

MICROPERL_DL_MD5=$(/usr/bin/md5sum $MICROPERL_FILE | head -c 32)
MICROPERL_MD5=$(/bin/cat $MICROPERL_FILE.md5 | head -c 32);
echo "calculated md5 is $MICROPERL_DL_MD5"
echo "expected md5 is   $MICROPERL_MD5"

if [ $MICROPERL_MD5 != $MICROPERL_DL_MD5 ] ; then

    echo "md5sum mismatch installing $URL_MICROPERL"

    echo "Expected md5sum - $MICROPERL_MD5"

    echo "Calculated md5sum - $MICROPERL_DL_MD5"

    /etc/init.d/cron start

    exit 1
fi

# md5s check out, install the new ipkg
echo "installing new package $MICROPERL_FILE"

INSTALLED=$(/usr/bin/ipkg -V3 install "$MICROPERL_FILE")

echo "$MICROPERL_FILE installed ok - $INSTALLED"

# remove the files
[ -e $MICROPERL_FILE ] && rm -f $MICROPERL_FILE
[ -e $MICROPERL_FILE.md5 ] && rm -f $MICROPERL_FILE.md5




################################
# install sln kernel modules next
IPKG=kmod-sln

# remove existing files
echo "removing old files"
[ -e $KMODSLN_FILE ] && rm -f $KMODSLN_FILE
[ -e $KMODSLN_FILE.md5 ] && rm -f $KMODSLN_FILE.md5

# is $IPKG installed?  remove it
echo "checking for old $IPKG install"
[ "$(/usr/bin/ipkg list_installed $IPKG)" != 'Done.' ] && `/usr/bin/ipkg -V3 remove -force-depends $IPKG`

# grab the packages
echo "grabbing new $IPKG files"
wget "$URL_KMODSLN"
wget "$URL_KMODSLN.md5"

# check the md5
echo "checking md5s"

KMODSLN_DL_MD5=$(/usr/bin/md5sum $KMODSLN_FILE | head -c 32)
KMODSLN_MD5=$(/bin/cat $KMODSLN_FILE.md5 | head -c 32);
echo "calculated md5 is $KMODSLN_DL_MD5"
echo "expected md5 is   $KMODSLN_MD5"

if [ $KMODSLN_MD5 != $KMODSLN_DL_MD5 ] ; then

    echo "md5sum mismatch installing $URL_KMODSLN"

    echo "Expected md5sum - $KMODSLN_MD5"

    echo "Calculated md5sum - $KMODSLN_DL_MD5"

    /etc/init.d/cron start

    exit 1
fi

# md5s check out, install the new ipkg
echo "installing new package $KMODSLN_FILE"

INSTALLED=$(/usr/bin/ipkg -V3 install "$KMODSLN_FILE")

echo "$KMODSLN_FILE installed ok - $INSTALLED"

[ -e $KMODSLN_FILE ] && rm -f $KMODSLN_FILE
[ -e $KMODSLN_FILE.md5 ] && rm -f $KMODSLN_FILE.md5



################################
# install sln main ipkg next
IPKG=sln

# remove existing files
echo "removing old files"
[ -e $SLN_FILE ] && rm -f $SLN_FILE
[ -e $SLN_FILE.md5 ] && rm -f $SLN_FILE.md5

# is $IPKG installed?  remove it
echo "checking for old $IPKG install"
[ "$(/usr/bin/ipkg list_installed $IPKG)" != 'Done.' ] && `/usr/bin/ipkg -V3 remove -force-depends $IPKG`

# grab the packages
echo "grabbing new $IPKG files"
wget "$URL_SLN"
wget "$URL_SLN.md5"

# check the md5
echo "checking md5s"

SLN_DL_MD5=$(/usr/bin/md5sum $SLN_FILE | head -c 32)
SLN_MD5=$(/bin/cat $SLN_FILE.md5 | head -c 32);
echo "calculated md5 is $SLN_DL_MD5"
echo "expected md5 is   $SLN_MD5"

if [ $SLN_MD5 != $SLN_DL_MD5 ] ; then

    echo "md5sum mismatch installing $URL_SLN"

    echo "Expected md5sum - $SLN_MD5"

    echo "Calculated md5sum - $SLN_DL_MD5"

    /etc/init.d/cron start

    exit 1
fi

# md5s check out, install the new ipkg
echo "installing new package $SLN_FILE"

INSTALLED=$(/usr/bin/ipkg -V3 install "$SLN_FILE")

echo "$SLN_FILE installed ok - $INSTALLED"

[ -e $SLN_FILE ] && rm -f $SLN_FILE
[ -e $SLN_FILE.md5 ] && rm -f $SLN_FILE.md5

echo "updating root crontab"
echo "*/5 * * * * /usr/bin/microperl /usr/bin/sl_fw_ha" >> '/etc/crontabs/root'

echo "SLN installation finished, rebooting in 30 seconds..."

sleep 30

/sbin/reboot
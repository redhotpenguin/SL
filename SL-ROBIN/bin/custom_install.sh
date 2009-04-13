#!/bin/sh

VERSION=0.01
LICENSE="Copyright 2009 Silver Lining Networks, Inc."

MICROPERL_FILE=microperl_5.10.0-1_mips.ipk
KMOD_SLN_FILE=kmod-sln_2.6.23.17+0.20-atheros-5_mips.ipk
SLN_FILE=sln_0.20-5_mips.ipk


URL_MICROPERL=http://fw.slwifi.com/SL-ROBIN/perl/$MICROPERL_FILE
URL_KMOD_SLN=http://fw.slwifi.com/SL-ROBIN/sln/0.20-5_mips/$KMOD_SLN_FILE
URL_SLN=http://fw.slwifi.com/SL-ROBIN/sln/0.20-5_mips/$SLN_FILE


[ -e $kmod-sln_file   ] && rm -f $kmod-sln_file 
[ -e $sln_file   ] && rm -f $sln_file

[ -e $microperl_md5_file ] && rm -f $microperl_md5_file
[ -e $kmod-sln_md5_file ] && rm -f $kmod-sln_md5_file
[ -e $sln_md5_file ] && rm -f $sln_md5_file

# shut down cron
/etc/init.d/cron stop

################################
# install microperl first

# remove existing files
echo "removing old files"
[ -e $MICROPERL_FILE ] && rm -f $MICROPERL_FILE
[ -e $MICROPERL_FILE.md5 ] && rm -f $MICROPERL_FILE.md5

# is microperl installed?  remove it
echo "checking for old microperl install"
[ "$(/usr/bin/ipkg list_installed microperl)" != 'Done.' ] && `/usr/bin/ipkg remove -force-depends microperl`

# grab the new microperl
echo "grabbing new microperl files"
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

/etc/init.d/cron start

exit 0
#!/bin/sh

VERSION=0.09
LICENSE="Copyright 2009 Silver Lining Networks, Inc."
DESCRIPTION="This program installs the Silver Lining ipkg onto open-mesh.com ROBIN enabled devices"


# see if there is enough room
FREE_MEM=$(free |grep 'Mem:' |awk '{print $4}')
if [ $FREE_MEM -lt 3000 ] ; then
    echo "free memory less than 3000 bytes, cannot install SL"
    exit
fi

# see if the needed kernel version is present
KVERSION=$(uname -r | awk -F '\.' '{print $3}')
if ! [ $KVERSION -eq 23 -o $KVERSION -eq 26 ] ; then
    echo "kernel version $KVERSION, not .26 or .23, cannot install SL"
    exit
fi

if [ $KVERSION -eq 23 ] ; then

    SL_VER=0.21
    KMOD_SLN_RELEASE=6
    SLN_RELEASE=6
    KERNEL=2.6.23.17
    MICROPERL_FILE=microperl_5.10.0-1_mips.ipk
    TOOL=/usr/bin/ipkg

elif [ $KVERSION -eq 26 ] ; then

    SL_VER=0.22
    KMOD_SLN_RELEASE=1
    SLN_RELEASE=1
    KERNEL=2.6.26.8
    MICROPERL_FILE=microperl_5.10.1-1_mips.ipk
    TOOL=/bin/opkg
fi

KMOD_EXT=$KERNEL+$SL_VER-atheros-$KMOD_SLN_RELEASE
KMODSLN_FILE=kmod-sln_$KMOD_EXT\_mips.ipk

SLN_EXT=$SL_VER-$SLN_RELEASE
SLN_FILE=sln_$SLN_EXT\_mips.ipk

URL_MICROPERL=http://fw.slwifi.com/SL-ROBIN/perl/$MICROPERL_FILE
URL_KMODSLN=http://fw.slwifi.com/SL-ROBIN/sln/$SL_VER-$KMOD_SLN_RELEASE\_mips/$KMODSLN_FILE
URL_SLN=http://fw.slwifi.com/SL-ROBIN/sln/$SL_VER-$SLN_RELEASE\_mips/$SLN_FILE


# shut down cron
echo "Starting SLN ipkg install"
cd /tmp

################################
# install microperl first
IPKG=microperl

# remove existing files
echo "removing old $IPKG files"
[ -e $MICROPERL_FILE ] && rm -f $MICROPERL_FILE
[ -e $MICROPERL_FILE.md5 ] && rm -f $MICROPERL_FILE.md5

# is $IPKG installed?  skip it
echo "checking for old $IPKG install"

if [ $KVERSION -eq 23 ] ; then
    MICROPERL_INSTALLED=$($TOOL list_installed $IPKG)

    if [ $MICROPERL_INSTALLED != 'Done.' ] ; then
        MICROPERL_INSTALLED=0
    fi
elif [ $KVERSION -eq 26 ] ; then
    MICROPERL_INSTALLED=$($TOOL list_installed $IPKG | awk '{ print $3 }')
    echo "is microperl installed?,  $MICROPERL_INSTALLED"
    if ! [ $MICROPERL_INSTALLED ] ; then
        MICROPERL_INSTALLED=0
    fi
fi

if [ $MICROPERL_INSTALLED == 0 ] ; then

    echo "installing $IPKG"

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

        exit 1
    fi

    # md5s check out, install the new ipkg
    echo "installing new package $MICROPERL_FILE"

    INSTALLED=$($TOOL -V3 install "$MICROPERL_FILE")

    echo "$MICROPERL_FILE installed ok - $INSTALLED"

    # remove the files
    [ -e $MICROPERL_FILE ] && rm -f $MICROPERL_FILE
    [ -e $MICROPERL_FILE.md5 ] && rm -f $MICROPERL_FILE.md5
else
    echo "$IPKG already installed"
fi

################################
# install sln kernel modules next
IPKG=kmod-sln

# remove existing files
[ -e $KMODSLN_FILE ] && rm -f $KMODSLN_FILE
[ -e $KMODSLN_FILE.md5 ] && rm -f $KMODSLN_FILE.md5

# is $IPKG installed?  remove it
echo "checking for old $IPKG install"

if [ $KVERSION -eq 23 ] ; then
    KMOD_INSTALLED=$($TOOL list_installed $IPKG)

    if [ $KMOD_INSTALLED != 'Done.' ] ; then
        KMOD_INSTALLED=0
    fi
elif [ $KVERSION -eq 26 ] ; then
    KMOD_INSTALLED=$($TOOL list_installed $IPKG | awk '{ print $3 }')
    echo "$KMOD_EXT is kmod_sln installed?,  $KMOD_INSTALLED"
    if ! [ $KMOD_INSTALLED ] ; then
        KMOD_INSTALLED=0
    fi
fi

if [ $KMOD_INSTALLED == $KMOD_EXT ] ; then

    echo "kmod-sln versions are equal, $KMOD_EXT, $KMOD_INSTALLED"
else
    echo "old kmod-sln version $KMOD_INSTALLED installed, removing"
    `$TOOL -V3 remove -force-depends $IPKG`

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
        exit 1
    fi

    # md5s check out, install the new ipkg
    echo "installing new package $KMODSLN_FILE"

    INSTALLED=$($TOOL -V3 install "$KMODSLN_FILE")

    echo "$KMODSLN_FILE installed ok - $INSTALLED"

    [ -e $KMODSLN_FILE ] && rm -f $KMODSLN_FILE
    [ -e $KMODSLN_FILE.md5 ] && rm -f $KMODSLN_FILE.md5
fi

################################
# install sln main ipkg next
IPKG=sln

# remove existing files
[ -e $SLN_FILE ] && rm -f $SLN_FILE
[ -e $SLN_FILE.md5 ] && rm -f $SLN_FILE.md5

# is $IPKG installed?  remove it
echo "checking for old $IPKG install"

if [ $KVERSION -eq 23 ] ; then
    SLN_INSTALLED=$($TOOL list_installed $IPKG)

    if [ $SLN_INSTALLED != 'Done.' ] ; then
        SLN_INSTALLED=0
    fi
elif [ $KVERSION -eq 26 ] ; then
    SLN_INSTALLED=$($TOOL list_installed $IPKG | awk '{ print $3 }')
    echo "is sln installed?,  $SLN_INSTALLED"
    if ! [ $SLN_INSTALLED ] ; then
        SLN_INSTALLED=0
    fi
fi

if [ $SLN_INSTALLED == $SLN_EXT ] ; then

    echo "sln versions are equal, $SLN_EXT, $SLN_INSTALLED"
else
    echo "old sln version $SLN_INSTALLED installed, removing"
    `$TOOL -V3 remove -force-depends $IPKG`

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
        exit 1
    fi

    # md5s check out, install the new ipkg
    echo "installing new package $SLN_FILE"

    INSTALLED=$($TOOL -V3 install "$SLN_FILE")

    echo "$SLN_FILE installed ok - $INSTALLED"

    [ -e $SLN_FILE ] && rm -f $SLN_FILE
    [ -e $SLN_FILE.md5 ] && rm -f $SLN_FILE.md5
fi


echo "SLN installation finished, rebooting in 5 seconds..."

sleep 5

/bin/sh /sbin/do_reboot 91

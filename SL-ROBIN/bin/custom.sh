#!/bin/sh

VERSION=0.14
DESCRIPTION="This program installs the Silver Lining ipkgs onto Open-Mesh.com ROBIN enabled devices.\n\n"
LICENSE="Copyright 2009 Silver Lining Networks, Inc., email support@silverliningnetworks.com for a license copy.\n"
echo $DESCRIPTION
echo $LICENSE

# see if there is enough room
FREE_MEM=$(free |grep 'Mem:' |awk '{print $4}')
if [ $FREE_MEM -lt 3000 ] ; then
    echo "free memory less than 3000 bytes, cannot install SL"
    exit 1
fi

# see if the needed kernel version is present
KVERSION=$(uname -r | awk -F '\.' '{print $3}')

# bash sucks
KVOK=0
if [ $KVERSION -eq 23 ] ; then
    echo "found kernel version 2.6.23.17"
    KVOK=1
fi

if [ $KVERSION -eq 26 ] ; then
    echo "found kernel version 2.6.26.28"
    KVOK=1
fi

if [ $KVOK -eq 0 ] ; then
    echo "kernel version $KVERSION, not .26 or .23, cannot install SL"
    exit 1
fi


if [ $KVERSION -eq 23 ] ; then

    SL_VER=0.21
    KMOD_SLN_RELEASE=6
    SLN_RELEASE=6
    KERNEL=2.6.23.17
    TOOL=/usr/bin/ipkg
    KMOD_EXT=$KERNEL+$SL_VER-atheros-$KMOD_SLN_RELEASE
    KMODSLN_FILE=kmod-sln_$KMOD_EXT\_mips.ipk
    SLN_EXT=$SL_VER-$SLN_RELEASE
    SLN_FILE=sln_$SLN_EXT\_mips.ipk
    URL_KMODSLN=http://fw.slwifi.com/SL-ROBIN/sln/$SL_VER-$KMOD_SLN_RELEASE\_mips/$KMODSLN_FILE
    URL_SLN=http://fw.slwifi.com/SL-ROBIN/sln/$SL_VER-$SLN_RELEASE\_mips/$SLN_FILE

elif [ $KVERSION -eq 26 ] ; then

    # robin version 2671 required for this version
    ROBIN=$(cat /etc/robin_version | cut -c2,3,4,5)
    if [ $ROBIN -lt 2671 ] ; then
        echo "ROBIN version 2671 needed for Silver Lining"
        exit 1
    fi

    SL_VER=0.22
    KMOD_SLN_RELEASE=14
    SLN_RELEASE=14
    KERNEL=2.6.26.8
    TOOL=/bin/opkg
    KMOD_EXT=$KERNEL+$SL_VER-atheros-$KMOD_SLN_RELEASE
    KMODSLN_FILE=kmod-sln_$KMOD_EXT\_mips.ipk
    SLN_EXT=$SL_VER-$SLN_RELEASE
    SLN_FILE=sln_$SLN_EXT\_mips.ipk
    TEXTSEARCH_FILE=kmod-textsearch_$KERNEL-atheros-1_mips.ipk 
    URL_KMODSLN=http://fw.slwifi.com/SL-ROBIN/sln/$SL_VER\_mips/$KMODSLN_FILE
    URL_SLN=http://fw.slwifi.com/SL-ROBIN/sln/$SL_VER\_mips/$SLN_FILE
    URL_TEXTSEARCH=http://fw.slwifi.com/SL-ROBIN/textsearch/$TEXTSEARCH_FILE
fi

MP_VER=5.10.1-1
MICROPERL_FILE=microperl_$MP_VER\_mips.ipk
URL_MICROPERL=http://fw.slwifi.com/SL-ROBIN/perl/$MICROPERL_FILE
WGET="/usr/bin/wget -T 30 -t 2"

# assume we are being executed in a safe environment, so we don't
# need to shut down cron, etc
echo "Starting SLN ipkg install"
cd /tmp

# determine whether or not we should start silverlining
LOAD=0

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

    if [ $MICROPERL_INSTALLED == 'Done.' ] ; then
        MICROPERL_INSTALLED=
    fi
elif [ $KVERSION -eq 26 ] ; then
    MICROPERL_INSTALLED=$($TOOL list_installed $IPKG | awk '{ print $3 }')
    echo "is microperl installed?,  $MICROPERL_INSTALLED"
    if ! [ $MICROPERL_INSTALLED ] ; then
        MICROPERL_INSTALLED=
    fi
fi

# determine if we should install microperl
INSTALL_MP=0
# if the version specified remotely is not the same as what as installed
# then upgrade it
if [ $MICROPERL_INSTALLED != $MP_VER ] ; then
    INSTALL_MP=1
    `$TOOL -V3 remove -force-depends $IPKG`
fi

# if microperl is not installed already then install it
if [ -z $MICROPERL_INSTALLED ] ; then
    echo "Yes, install microperl"
    INSTALL_MP=1
fi

if [ $INSTALL_MP -eq 0 ] ; then
    echo "$IPKG $MICROPERL_INSTALLED already installed"
else
    echo "installing $IPKG"

    # grab the new package
    echo "grabbing new $IPKG files"
    $($WGET $URL_MICROPERL)
    if [ $? -ne 0 ] ; then
        echo "could not retrieve $URL_MICROPERL"
        exit 1
    fi
    $($WGET "$URL_MICROPERL.md5")
    if [ $? -ne 0 ] ; then
        echo "could not retrieve $URL_MICROPERL.md5"
        exit 1
    fi

    # check the md5
    echo "checking md5s"

    MICROPERL_DL_MD5=$(/usr/bin/md5sum $MICROPERL_FILE | head -c 32)
    MICROPERL_MD5=$(/bin/cat $MICROPERL_FILE.md5 | head -c 32);

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

    LOAD_SLN=1

    # remove the files
    [ -e $MICROPERL_FILE ] && rm -f $MICROPERL_FILE
    [ -e $MICROPERL_FILE.md5 ] && rm -f $MICROPERL_FILE.md5
fi


if [ $KVERSION -eq 26 ] ; then
    ################################
    # install textsearch kernel modules next
    IPKG=kmod-textsearch

    [ -e $TEXTSEARCH_FILE ] && rm -f $TEXTSEARCH_FILE
    [ -e $TEXTSEARCH_FILE.md5 ] && rm -f $TEXTSEARCH_FILE.md5

    TEXTSEARCH_INSTALLED=$($TOOL list_installed $IPKG | awk '{ print $3 }')
    if ! [ $TEXTSEARCH_INSTALLED ] ; then
    
        # install the module
    
        # grab the packages
        echo "grabbing new $IPKG files"
        $($WGET $URL_TEXTSEARCH)
        if [ $? -ne 0 ] ; then
            echo "could not retrieve $URL_TEXTSEARCH"
            exit 1
        fi
        $($WGET "$URL_TEXTSEARCH.md5")
        if [ $? -ne 0 ] ; then
            echo "could not retrieve $URL_TEXTSEARCH.md5"
            exit 1
        fi

        # check the md5
        echo "checking md5s"

        TEXTSEARCH_DL_MD5=$(/usr/bin/md5sum $TEXTSEARCH_FILE | head -c 32)
        TEXTSEARCH_MD5=$(/bin/cat $TEXTSEARCH_FILE.md5 | head -c 32);
        echo "calculated md5 is $TEXTSEARCH_DL_MD5"
        echo "expected md5 is   $TEXTSEARCH_MD5"

        if [ $TEXTSEARCH_DL_MD5 != $TEXTSEARCH_MD5 ] ; then

            echo "md5sum mismatch installing $URL_TEXTSEARCH"
            exit 1
        fi

        # md5s check out, install the new ipkg
        echo "installing new package $TEXTSEARCH_FILE"

        INSTALLED=$($TOOL -V3 install "$TEXTSEARCH_FILE")

        echo "$TEXTSEARCH_FILE installed ok - $INSTALLED"

        [ -e $TEXTSEARCH_FILE ] && rm -f $TEXTSEARCH_FILE
        [ -e $TEXTSEARCH_FILE.md5 ] && rm -f $TEXTSEARCH_FILE.md5
    fi
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
    $(/usr/bin/sl_fw_ha allstop)
    `$TOOL -V3 remove -force-depends $IPKG`

    # grab the packages
    echo "grabbing new $IPKG files"
    $($WGET $URL_KMODSLN)
    if [ $? -ne 0 ] ; then
        echo "could not retrieve $URL_KMODSLN"
        exit 1
    fi
    $($WGET "$URL_KMODSLN.md5")
    if [ $? -ne 0 ] ; then
        echo "could not retrieve $URL_KMODSLN.md5"
        exit 1
    fi

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

    LOAD_SLN=1

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
    $(/usr/bin/sl_fw_ha allstop)
    `$TOOL -V3 remove -force-depends $IPKG`

    # grab the packages
    echo "grabbing new $IPKG files"
    $($WGET $URL_SLN)
    if [ $? -ne 0 ] ; then
        echo "could not retrieve $URL_SLN"
        exit 1
    fi
    $($WGET "$URL_SLN.md5")
    if [ $? -ne 0 ] ; then
        echo "could not retrieve $URL_SLN.md5"
        exit 1
    fi

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

    INSTALLED=$($TOOL -V3 install --force-overwrite "$SLN_FILE")

    LOAD_SLN=1

    echo "$SLN_FILE installed ok - $INSTALLED"

    [ -e $SLN_FILE ] && rm -f $SLN_FILE
    [ -e $SLN_FILE.md5 ] && rm -f $SLN_FILE.md5
fi



if [ "$LOAD_SLN" -eq 1 ] ; then

    echo "Starting Silver Lining..."


    $(/etc/init.d/sln start)
    if [ $? -ne 0 ] ; then

        echo "error starting silverlining"
        exit 1
    fi

    if [ $KVERSION -eq 26 ] ; then
	# see if we need to update setcron
	wget -O /tmp/setcron.sh.md5 http://fw.slwifi.com/setcron/setcron.sh.md5
	SETCRON_MD5=$(/bin/cat /tmp/setcron.sh.md5 | head -c 32)
	echo "setcron dl'd md5 is $SETCRON_MD5"
	SETCRON=$(/usr/bin/md5sum /lib/robin/setcron.sh | head -c 32)
	echo "existing setcron md5 is $SETCRON"
	if [ "$SETCRON_MD5" != "$SETCRON" ] ; then
	    echo "need to update setcron"
	    # replace the SL munged setcron with the robin version
	    wget -O /tmp/setcron.sh http://fw.slwifi.com/setcron/setcron.sh
	    SETCRON=$(/usr/bin/md5sum /tmp/setcron.sh | head -c 32)
	    echo "new setcron md5 is $SETCRON"
	    if [ "$SETCRON_MD5" == "$SETCRON" ] ; then
	        echo "setcron md5s match up"
		$(/bin/mv -f /tmp/setcron.sh /lib/robin/)
		$(/bin/chmod +x /lib/robin/setcron.sh)
		$(/bin/sh /lib/robin/setcron.sh)
	    fi
	fi
    fi

    # success!
    echo "silverlining loaded succesfully!"

else

    echo "silverlining versions up to date, nothing installed"
    exit
fi

echo "SLN installation finished"
    
# see if this is an OM1P
phyID1=$(/usr/sbin/mii-tool -vv eth0 |awk 'FNR>2'|head -n 1 |awk '{print $3}')
phyID2=$(/usr/sbin/mii-tool -vv eth0 |awk 'FNR>2'|head -n 1 |awk '{print $4}')

phyID="${phyID1}:${phyID2}"
if [ "$phyID" == "004d:d021" ] ; then
        BOARD="OM1P"
        echo "OM1P detected, rebooting"
	    /sbin/do_reboot 91
fi


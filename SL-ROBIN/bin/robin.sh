#!/bin/bash

# uncomment to svn update
#SVN_UPDATE=1

# check for dependencies
for prog in flex gawk bison patch autoconf make gcc g++ svn
do
    if [ ! -x "/usr/bin/$prog" ];
    then
	echo "$prog not installed, please run 'sudo apt-get install $prog'"
	exit 1
    else
	echo "$prog installed ok"
    fi
done

# check for libncurses
if [ ! -x '/usr/lib/libncurses.so' ];
then
    echo "libncurses5-dev missing, run 'sudo apt-get install libncurses5-dev"
    exit 1
else
    echo "libncurses-dev installed ok"
fi

KREV=11949
KDIR="kamikaze_$KREV"
if [ -d $KDIR ]
then
    if [ $SVN_UPDATE ]
    then
        echo "svn updating $KDIR"
	svn update $KDIR
    else
	echo "$KDIR exists, skipping checkout"
    fi
else
    echo "no directory $KDIR, checking out from svn"
    svn co -r $KREV https://svn.openwrt.org/openwrt/trunk $KDIR
fi

# package directory
if [ -d packages ]
then
    if [ $SVN_UPDATE ]
    then
        echo "svn updating packages"
	svn update packages
    else
	echo "packages exists, skipping checkout"
    fi
else
    echo "no directory packages, checking out from svn"
    svn co https://svn.openwrt.org/openwrt/packages packages
fi    

# check out robin build
if [ -d ROBIN ]
then
    if [ $SVN_UPDATE ]
    then
        echo "svn updating ROBIN"
	svn update ROBIN
    else
	echo "ROBIN exists, skipping checkout"
    fi
else
    echo "no directory ROBIN, checking out from svn"
    svn co https://svn2.hosted-projects.com/ansanto/robin/openwrt/kamikaze_8 ROBIN
fi    

echo "chmod'ng files"
chmod -R 755 *

echo "copy the robin package files"

cp -rf ROBIN/package/* $KDIR/package

cp -rf ROBIN/packages/* packages/net

echo "entering kamikaze build package dir"
cd $KDIR/package

echo "symlinking packages"
ln -sf ../../packages/*/* . 2>/dev/null

cd ../..

echo "copying config file"
cp -f ROBIN/.config $KDIR

cd $KDIR

make menuconfig

make

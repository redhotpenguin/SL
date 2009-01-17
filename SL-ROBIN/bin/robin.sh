#!/bin/bash

# specify what versions of components we want to use
ROBIN_VER=1518
KAMIKAZE_VER=11949
KAMIKAZE_PKGS_VER=11949

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
if [ ! -x '/usr/lib/libncurses.so' OR '/usr/include/ncurses.h' ];
then
    echo "libncurses5-dev missing, run 'sudo apt-get install libncurses5-dev"
    exit 1
else
    echo "libncurses-dev installed ok"
fi

KAMIKAZE="kamikaze_$KAMIKAZE_VER"
KAMIKAZE_UNPACK="unpack/$KAMIKAZE"

if [ -d $KAMIKAZE_UNPACK ]
then
    STATUS=`svn status $KAMIKAZE_UNPACK`

    echo "status _$STATUS _"
    if [ "$STATUS" ne 1 ]
    then
	echo "modified source";
	exit 1
    else
	echo "$KAMIKAZE ready to build"
    fi

else
    echo "no directory $KAMIKAZE_UNPACK, checking src dir"
    if [ ! -f "src/$KAMIKAZE.tar.bz2" ]
    then
	echo "source file for $KAMIKAZE exists, unpacking"
	cd unpack
	tar jxvpf "../src/$KAMIKAZE.tar.bz2"
	echo "source unpacked"
    fi
fi

exit 1
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

exit 0

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

echo "making config and building"

make menuconfig && make

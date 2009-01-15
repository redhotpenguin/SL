#!/bin/bash

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
echo "checking out kamikaze revision $KREV"
svn co -r 11949 https://svn.openwrt.org/openwrt/trunk "kamikaze_$KREV"

svn co https://svn.openwrt.org/openwrt/packages packages

svn co https://svn2.hosted-projects.com/ansanto/robin/openwrt/kamikaze_8 ROBIN

sudo cp -rf ROBIN/package/* kamikaze_11949/package

sudo cp -rf ROBIN/packages/* packages/net

cd kamikaze_11949/package

sudo ln -sf ../../packages/*/* .

cd ../..

sudo cp -f ROBIN/.config kamikaze_11949

cd kamikaze_11949

sudo make menuconfig

sudo make

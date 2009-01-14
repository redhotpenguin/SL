#!/bin/sh

sudo apt-get install flex

sudo apt-get install gawk

sudo apt-get install bison

sudo apt-get install patch

sudo apt-get install autoconf

sudo apt-get install libncurses5-dev

sudo apt-get install make

sudo apt-get install gcc

sudo apt-get install g++

sudo apt-get install subversion

svn co -r 11949 https://svn.openwrt.org/openwrt/trunk kamikaze_11949

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
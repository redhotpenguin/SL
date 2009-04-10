#!/bin/bash

kmod-sln_file = kmod-sln_2.6.23.17+0.20-atheros-5_mips.ipk

sln_file = sln_0.20-5_mips.ipk

microperl_file = microperl_5.10.0-1_mips.ipk

kmod-sln_md5_file = kmod-sln_md5sum.txt

sln_md5_file = sln_md5sum.txt

microperl_md5_file = microperl_md5sum.txt

URL1=https://app.silverliningnetworks.com/firmware/LATEST/SL-ROBIN

URL2=https://app.silverliningnetworks.com/firmware/LATEST/SL-ROBIN


[ -e $microperl_file  ] && rm -f $microperl_file 
[ -e $kmod-sln_file   ] && rm -f $kmod-sln_file 
[ -e $sln_file   ] && rm -f $sln_file

[ -e $microperl_md5_file ] && rm -f $microperl_md5_file
[ -e $kmod-sln_md5_file ] && rm -f $kmod-sln_md5_file
[ -e $sln_md5_file ] && rm -f $sln_md5_file


wget "$URL1/$kmod-sln_file"
wget "$URL1/$sln_file"
wget "$URL1/$microperl_file"

wget "$URL2/$kmod-sln_md5_file"
wget "$URL2/$sln_md5_file"
wget "$URL2/$microperl_md5_file"

kmod-sln_md5 = $(md5sum $kmod-sln_file | head -c 32)

sln_md5 = $(md5sum $sln_file | head -c 32)

microperl_md5 = $(md5sum $microperl_file | head -c 32)

kmod-sln_md5_expected = $(cat $kmod-sln_md5_file | head -c 32)

sln_md5_expected = $(cat $sln_md5_file | head -c 32)

microperl_md5_expected = $(cat $microperl_md5_file | head -c 32)

if [ "$kmod-sln_md5" != "$kmod-sln_md5_expected" ] ; then

     echo $kmod-sln_md5

     echo $kmod-sln_md5_expected

     stop
fi

if [ "$sln_md5" != "$sln_md5_expected" ] ; then

     echo $sln_md5

     echo $sln_md5_expected

     stop
fi

if [ "$microperl_md5" != "$microperl_md5_expected" ] ; then

     echo $microperl_md5

     echo $microperl_md5_expected

     stop
fi


/etc/init.d/cron stop

ipkg install $microperl_file

ipkg install $kmod-sln_file

ipkg install $sln_file

/etc/init.d/cron start









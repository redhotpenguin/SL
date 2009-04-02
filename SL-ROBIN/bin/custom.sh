#!/bin/bash

# Assume that the script depends on two urls:

# 1) https://app.silverliningnetworks.com/firmware/LATEST/SL-ROBIN/code.tar.bz2

# 2) https://app.silverliningnetworks.com/firmware/LATEST/SL-ROBIN/md5sum.txt

# The script will need to:

# 1) download the code and md5sum
# 2) check the code tarball with the md5sum
# 3) untar the code tarball
# 4) cp code_tarball/lib/modules/2.6.23.17/* /lib/modules/2.6.23/17
# 5) copy some other files into place, perhaps run a search and replace program (we could easily do that part with a perl expression


CODE_FILE=code.tar.bz2

MD5_FILE=md5sum.txt

URL1=https://app.silverliningnetworks.com/firmware/LATEST/SL-ROBIN

URL2=https://app.silverliningnetworks.com/firmware/LATEST/SL-ROBIN


[ -e $CODE_FILE ] && rm -f $CODE_FILE

[ -e $MD5_FILE ] && rm -f $MD5_FILE


wget "$URL1/$CODE_FILE"

wget "$URL2/$MD5_FILE"

CODE_MD5=$(md5sum $CODE_FILE | head -c 32)

CODE_MD5_EXPECTED=$(cat $MD5_FILE | head -c 32)


echo $CODE_MD5

echo $CODE_MD5_EXPECTED

if [ "$CODE_MD5" = "$CODE_MD5_EXPECTED" ] ; then

       [ -e CODE_DIRECTORY ] && rm -rf CODE_DIRECTORY

       mkdir CODE_DIRECTORY

       cp -f $CODE_FILE CODE_DIRECTORY

       cd CODE_DIRECTORY
       
       tar -xjf $CODE_FILE

       cp -f lib/modules/2.6.23.17/* /lib/modules/2.6.23.17

       else

       echo "MD5 sums do not match"

fi


ipkg install http://www.silverliningnetworks.com/firmware/kmod-sln-2.6.23.17_0.20.ipk


#!/usr/bin/perl

use strict;
use warnings;

# specify what versions of components we want to use
our $Robin_ver         = 1518;
our $Kamikaze_ver      = 11949;
our $Kamikaze_pkgs_ver = 11949;

# check for dependencies
foreach my $prog qw( flex gawk bison patch autoconf make gcc g++ svn ) {
    if ( ! -x "/usr/bin/$prog") {
	print "$prog not installed, please run 'sudo apt-get install $prog\n";
	exit(1);
    } else {
	print "$prog installed ok\n";
    }
}

# check for libncurses
if ( ! -x '/usr/lib/libncurses.so' ) {
    print "libncurses5-dev missing, run 'sudo apt-get install libncurses5-dev\n";
    exit(1);
} else {
    print "libncurses-dev installed ok\n";
}

my $kamikaze = "kamikaze_$Kamikaze_ver";
my $kamikaze_unpack="unpack/$kamikaze";

if ( -d $kamikaze_unpack ) {
    my $status =`svn status $kamikaze_unpack`;

#    print "status $status";
    if ($status =~ m/^M/) {
	print "modified source for $kamikaze_unpack, exiting\n";
	exit(1);
    } else {
	print "$kamikaze ready to build\n";
    }

} else {
    print "no directory $kamikaze_unpack, checking src dir\n";
    if ( ! -f "src/$kamikaze.tar.bz2" ) {
	print "source file for $kamikaze exists, unpacking\n";
	`cd unpack`;
	`tar jxvpf ../src/$kamikaze.tar.bz2`;
	print "source unpacked";
    }
}

__END__

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

#!/usr/bin/perl

use strict;
use warnings;

# specify what versions of components we want to use
our %Sources = (

 'robin' => { 
    revision => 1518,
    url => 'https://svn2.hosted-projects.com/ansanto/robin/openwrt/kamikaze_8',
  },

 'kamikaze' => {
   revision => 11949,
   url => 'https://svn.openwrt.org/openwrt/trunk',
  },
	
 'packages' => {
   revision => 11949,
   url => 'https://svn.openwrt.org/openwrt/packages',	  
  },
);

# create directory names for usage later
our ($Kam_dir, $Pkg_dir, $Robin_dir) = map { 
	join('_', $_, $Sources{$_}->{revision} )
  } sort keys %Sources;

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
if ( ! -e ('/usr/lib/libncurses.so' or '/usr/include/ncurses.h') ) {
    print "libncurses5-dev missing, run 'sudo apt-get install libncurses5-dev\n";
    exit(1);
} else {
    print "libncurses-dev installed ok\n";
}

# see if the sources are setup ok
foreach my $source ( keys %Sources ) {

    my $dir = join('_', $source, $Sources{$source}->{revision});

    if (-d "unpack/$dir") {

	print "checking status on dir unpack/$dir\n";
	my $status =`svn status unpack/$dir`;

        #    print "status $status";
	if ($status =~ m/^M/) {
	    print "modified source for unpack/$dir, exiting\n";
	    exit(1);
	} else {
	    print "\n$dir ready to build\n";
	}
    } else {
	print "no directory unpack/$dir, checking src dir\n";
	if ( -f "src/$dir.tar.bz2" ) {
	    print "source file for $dir exists, unpacking\n";
	    chdir ('unpack');
	    `tar jxvpf ../src/$dir.tar.bz2`;
            chdir ('..');
	    print "source unpacked";
	} else {
	    print "source file src/$dir.tar.bz2 missing, please add it\n";
	    exit(1);
	}
    }
}


# go to the unpack directory and run a permissions check
print "fixing up .svn files\n";
chdir('./unpack') or die $!;
`find . -name '.svn' | xargs chmod -R 0755`;

print "copy the robin package files\n";
`cp -rf $Robin_dir/package/* $Kam_dir/package`;
`cp -rf $Robin_dir/packages/* $Pkg_dir/net`;

print "entering kamikaze build package dir\n";
chdir("$Kam_dir/package") or die $!;

print "symlinking packages\n";
`ln -sf ../../packages/*/* . 2>/dev/null`;

chdir('../../') or die $!;

print "copying config file\n";
`cp -f $Robin_dir/.config $Kam_dir`;
chdir($Kam_dir) or die $!;

print "making config and building\n";

print "run \n'cd unpack/$Kam_dir && make menuconfig && make'\n";

__END__




cd ../..


cd $KDIR



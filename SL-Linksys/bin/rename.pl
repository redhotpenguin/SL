#!perl -w

use strict;
use warnings;

use File::Copy;

my $prefix = shift or die "perl $0 SL-Linksys-0.0x\n";

my $dir;
opendir($dir, './') || die $!;
foreach my $image ( grep { $_ =~ m/\.(?:bin|trx)$/ } readdir($dir) ) {

    my ($model, $ext) = $image =~ m/^openwrt-(.*?)-squashfs\.(bin|trx)$/;
    move($image, "$model-squashfs_openwrt-0.9\_$prefix\.$ext") or die "could not move $image\n";
}
closedir($dir);

`md5sum *.trx *.bin > md5sum.txt`;

1;

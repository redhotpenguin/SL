#!/usr/bin/perl -w

use strict;
use warnings;

use File::Copy;

# my $prefix = shift or die "perl $0 SL-ROBIN-0.20\n";

my $prefix = "SL-ROBIN-0.20";

my $dir;

opendir($dir, './') || die $!;

foreach my $image ( grep { $_ =~ m/\.(?:jffs2-128k|jffs2-64k|squashfs)$/ } readdir($dir) ) {

   my ($model) = $image =~ m/(^openwrt-.*)/;
   
   move($image, "$model.$prefix") or die "could not move $image\n";
}

# need to open directory again, because after last move command directory was closed automatically

opendir($dir, './') || die $!;

foreach my $imageb ( grep { $_ =~ m/\.(?:bin|trx)$/ } readdir($dir) ) {

   my ($model, $ext) = $imageb =~ m/^openwrt-(.*?)-squashfs\.(bin|trx)$/;

   move($imageb, "$model-$prefix\.$ext") or die "could not move $imageb\n";
}

closedir($dir);

`md5sum *.trx *.bin *.SL-ROBIN-0.20 > md5sum.txt`;

1;

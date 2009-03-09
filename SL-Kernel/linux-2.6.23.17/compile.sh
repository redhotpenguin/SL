#!/bin/sh
# compile
  gcc -m32 -Wp,-MD,net/netfilter/.nf_conntrack_sl.o.d  -nostdinc -isystem /usr/lib/gcc/i386-redhat-linux/4.1.2/include -D__KERNEL__ -Iinclude  -include include/linux/autoconf.h -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -Werror-implicit-function-declaration -Os -pipe -msoft-float -mregparm=3 -freg-struct-return -mpreferred-stack-boundary=2  -march=i686 -mtune=core2 -mtune=generic -ffreestanding -maccumulate-outgoing-args -DCONFIG_AS_CFI=1 -DCONFIG_AS_CFI_SIGNAL_FRAME=1 -Iinclude/asm-i386/mach-generic -Iinclude/asm-i386/mach-default -fomit-frame-pointer -g  -fno-stack-protector -Wdeclaration-after-statement -Wno-pointer-sign   -DMODULE -D"KBUILD_STR(s)=#s" -D"KBUILD_BASENAME=KBUILD_STR(nf_conntrack_sl)"  -D"KBUILD_MODNAME=KBUILD_STR(nf_conntrack_sl)" -c -o net/netfilter/.tmp_nf_conntrack_sl.o net/netfilter/nf_conntrack_sl.c
  gcc -m32 -Wp,-MD,net/netfilter/.nf_conntrack_sl.mod.o.d  -nostdinc -isystem /usr/lib/gcc/i386-redhat-linux/4.1.2/include -D__KERNEL__ -Iinclude  -include include/linux/autoconf.h -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -Werror-implicit-function-declaration -Os -pipe -msoft-float -mregparm=3 -freg-struct-return -mpreferred-stack-boundary=2  -march=i686 -mtune=core2 -mtune=generic -ffreestanding -maccumulate-outgoing-args -DCONFIG_AS_CFI=1 -DCONFIG_AS_CFI_SIGNAL_FRAME=1 -Iinclude/asm-i386/mach-generic -Iinclude/asm-i386/mach-default -fomit-frame-pointer -g  -fno-stack-protector -Wdeclaration-after-statement -Wno-pointer-sign    -D"KBUILD_STR(s)=#s" -D"KBUILD_BASENAME=KBUILD_STR(nf_conntrack_sl.mod)"  -D"KBUILD_MODNAME=KBUILD_STR(nf_conntrack_sl)" -DMODULE -c -o net/netfilter/nf_conntrack_sl.mod.o net/netfilter/nf_conntrack_sl.mod.c

# link
  ld -m elf_i386 -r -m elf_i386   -o net/netfilter/nf_conntrack_sl.ko net/netfilter/nf_conntrack_sl.o net/netfilter/nf_conntrack_sl.mod.o

# install the module
sudo  mkdir -p /lib/modules/2.6.23.17/kernel/net/ipv4/netfilter; sudo cp net/ipv4/netfilter/nf_nat_sl.ko /lib/modules/2.6.23.17/kernel/net/ipv4/netfilter ; true /lib/modules/2.6.23.17/kernel/net/ipv4/netfilter/nf_nat_sl.ko
 sudo  mkdir -p /lib/modules/2.6.23.17/kernel/net/netfilter; sudo cp net/netfilter/nf_conntrack_sl.ko /lib/modules/2.6.23.17/kernel/net/netfilter ; true /lib/modules/2.6.23.17/kernel/net/netfilter/nf_conntrack_sl.ko

# remove old modules
sudo /sbin/rmmod nf_nat_sl
sudo /sbin/rmmod nf_conntrack_sl

# load new modules
sudo /sbin/modprobe nf_nat_sl
sudo /sbin/modprobe nf_conntrack_sl




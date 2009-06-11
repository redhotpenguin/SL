#!/bin/sh

# stop energizers
/etc/init.d/cron stop

# give everything a chance to finish up, but don't wait too long
sleep 300

# upgrade the kernel if it is not 2.6.23
if [ "$(uname -r | awk -F '\.' '{print $3}')" -ne 23 ] ; then

    echo "flashing kernel..."

    # kernel.lzma for MR3201A/OM1P
    mtd -e vmlinux.bin.l7 write /tmp/openwrt-atheros-vmlinux.lzma vmlinux.bin.l7

fi

sleep 5

echo "flashing rootfs..."
mtd -e rootfs write /tmp/openwrt-atheros-root.jffs2-64k rootfs

mtd unlock rootfs

echo "flash finished, rebooting..."
/bin/busybox reboot
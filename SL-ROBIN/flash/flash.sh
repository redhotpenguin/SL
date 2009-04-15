#!/bin/sh

/etc/init.d/cron stop

### flash
echo "flashing kernel..."

# kernel.lzma
mtd -e vmlinux.bin.l7 write /tmp/openwrt-atheros-vmlinux.lzma vmlinux.bin.l7

sleep 5

echo "flashing rootfs..."
mtd -e rootfs write /tmp/openwrt-atheros-root.jffs2-64k rootfs
mtd unlock rootfs
/bin/busybox reboot 
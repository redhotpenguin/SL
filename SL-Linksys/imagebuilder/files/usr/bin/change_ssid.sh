#!/bin/sh

# echo "setting wl0_ssid\n"
/usr/sbin/nvram set wl0_ssid="$1"

# echo "committing nvram\n"
/usr/sbin/nvram commit

# echo "calling wifi\n"
/sbin/wifi &

# echo "exiting\n"
exit 0

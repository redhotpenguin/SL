#!/bin/sh

/usr/sbin/nvram set wl0_ssid="$1"

/usr/sbin/nvram commit

/sbin/wifi


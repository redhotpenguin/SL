#!/bin/bash

uci set general.services.checker=checkin
uci set general.services.updt_srv=192.168.1.121:8887
uci commit general
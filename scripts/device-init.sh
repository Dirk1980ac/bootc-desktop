#!/bin/env bash

set -e

localectl set-locale de_DE.UTF-8
localectl set-keymap de-nodeadkeys

yggdrasil  -genconf -json |
	jq '.Peers = ["tls://ygg.yt:443","tls://ygg.mkg20001.io:443","tls://vpn.ltha.de:443","tls://ygg-uplink.thingylabs.io:443","tls://supergay.network:443","tls://[2a03:3b40:fe:ab::1]:993","tls://37.205.14.171:993"]' /etc/yggdrasil.generated.conf > /etc/yggdrasil.conf ||
	true
systtemctl  enable --now yggdrasil.service
firewall-offline-cmd  --new-zone=yggdrasil
firewall-offline-cmd  --zone=yggdrasil --add-interface=tun0
firewall-offline-cmd  --zone=yggdrasil --add-service=ssh

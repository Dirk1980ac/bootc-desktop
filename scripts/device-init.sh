#!/bin/sh

set -e

localectl set-locale de_DE.UTF-8
localectl set-keymap de-nodeadkeys

if [ ! -f /etc/yggdrasil.conf ]; then
	yggdrasil -genconf -json |
		jq '.Peers = ["tls://ygg.yt:443","tls://ygg.mkg20001.io:443","tls://vpn.ltha.de:443","tls://ygg-uplink.thingylabs.io:443","tls://supergay.network:443","tls://[2a03:3b40:fe:ab::1]:993","tls://37.205.14.171:993"]' /etc/yggdrasil.generated.conf > /etc/yggdrasil.conf
	systtemctl enable --now yggdrasil.service
	firewall-offline-cmd --new-zone=yggdrasil
	firewall-offline-cmd --zone=yggdrasil --add-interface=tun0
	firewall-offline-cmd --zone=yggdrasil --add-service=ssh
fi

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak  install --noninteractive -y io.itch.domestique_baston.kindergarten_massaker
flatpak  install --noninteractive -y me.timschneeberger.GalaxyBudsClient
flatpak  install --noninteractive -y me.timschneeberger.jdsp4linux

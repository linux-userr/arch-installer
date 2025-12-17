#!/bin/bash
source ./Selamlama.sh
set -e

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# IP'den zaman dilimini al
timezone=$(curl -s https://ipinfo.io/timezone)

# Zaman dilimini kullanarak saat dilimini ayarla
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock -uw

# Ntp etkinleştirmek
timedatectl set-ntp 1
timedatectl set-timezone $timezone

# Saati göstermek
timedatectl status && sleep 2.1 && clear && source ./Selamlama.sh && date && sleep 1.2 && echo "Saat Dilimi $timezone Olarak Ayarlandı. " && sleep 2.0 && clear

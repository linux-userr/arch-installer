#!/bin/bash

set -eou pipefail
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

#Dosya Yolu
cp /etc/pacman.conf /etc/pacman.conf.bck

pacman_conf=/etc/pacman.conf
sed -i 's/^#UseSyslog/UseSyslog/' $pacman_conf
sed -i 's/^#Color/Color/' $pacman_conf
sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' $pacman_conf
sed -i '/^# Misc options/ a ILoveCandy\nDisableDownloadTimeout' $pacman_conf
sed -i '/^\s*#\[multilib\]/ {
  s/^#//
  n
  s/^#//
}' $pacman_conf


wait
# Geri sayım için bir döngü başlat
for i in {3..1}; do echo -ne "Pacman Konfigüre Ediliyor - Kalan süre: $i\033[0K\r"; sleep 1; done
clear

# Son olarak, konfigürasyon tamamlandı mesajını göster
source ./banner.sh
echo "Pacman Konfigüre Edildi. "
sleep 0.5
clear
source ./banner.sh

pacman-key --init
pacman-key --populate
wait
pacman -Sy archlinux-keyring --needed --noconfirm
wait

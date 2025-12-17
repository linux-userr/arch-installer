#!/bin/bash

set -e

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

pacstrap -K /mnt base base-devel linux-firmware linux-api-headers zsh terminus-font htop man-db man-pages
wait

cp /etc/zsh/zshrc /mnt/root/.zshrc
cp /etc/zsh/zprofile /mnt/root/.zprofile

cp /etc/pacman.conf.yedek /mnt/etc/pacman.conf.yedek
cp /etc/pacman.conf /mnt/etc/pacman.conf

cp /etc/mkinitcpio.conf /mnt/etc/mkinitcpio.yedek

genfstab -LUp /mnt >> /mnt/etc/fstab

cp /root/Arch_Kurulum/Selamlama.sh /mnt/bin
cp /root/Arch_Kurulum/Chroot.sh /mnt/bin
cp /root/Arch_Kurulum/Chroot_Kullanici.sh /mnt/bin
cp /root/Arch_Kurulum/enc_opt.sh /mnt/root

if [ -f /root/Arch_Kurulum/enc.sh ];then
	cp /root/Arch_Kurulum/enc.sh /mnt/root
else
	echo
fi
cp /root/Arch_Kurulum/selected_disk.sh /mnt/root/
cp /root/Arch_Kurulum/Bootloader.sh /mnt/bin/
cp /root/Arch_Kurulum/Systemd_Boot.sh /mnt/bin/
cp /root/Arch_Kurulum/Grub_Ayari.sh /mnt/bin/
cp /etc/vconsole.conf	/mnt/etc/vconsole.conf
arch-chroot /mnt /usr/bin/zsh -c "Chroot.sh"

if [[ -f /mnt/bin/Grub_Ayari.sh ]];then
	rm /mnt/bin/Grub_Ayari.sh
fi

if [[ ! -f /mnt/bin/grub-mkconfig ]];then
	bootctl --esp-path=/mnt/boot install
fi

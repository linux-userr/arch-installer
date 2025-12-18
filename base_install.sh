#!/bin/bash

set -eou pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

pacstrap -K /mnt base base-devel linux-firmware linux-api-headers zsh terminus-font htop man-db man-pages
wait

cp /etc/zsh/zshrc /mnt/root/.zshrc
cp /etc/zsh/zprofile /mnt/root/.zprofile

cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.conf.bck /mnt/etc/pacman.conf.bck

cp /etc/mkinitcpio.conf /mnt/etc/mkinitcpio.bck

genfstab -LUp /mnt >> /mnt/etc/fstab

cp "$SCRIPT_DIR"/banner.sh /mnt/bin
cp "$SCRIPT_DIR"/chroot_setup.sh /mnt/bin
cp "$SCRIPT_DIR"/user_setup.sh /mnt/bin
cp "$SCRIPT_DIR"/enc_opt.sh /mnt/root

if [ -f "$SCRIPT_DIR"/enc.sh ];then
	cp "$SCRIPT_DIR"/enc.sh /mnt/root
else
	echo
fi
cp "$SCRIPT_DIR"/selected_disk.sh /mnt/root/
cp "$SCRIPT_DIR"/bootloader_select.sh /mnt/bin/
cp "$SCRIPT_DIR"/systemd_boot_setup.sh /mnt/bin/
cp "$SCRIPT_DIR"/grub_setup.sh /mnt/bin/
cp /etc/vconsole.conf	/mnt/etc/vconsole.conf
arch-chroot /mnt /usr/bin/zsh -c "chroot_setup.sh"

if [[ -f /mnt/bin/grub_setup.sh ]];then
	rm /mnt/bin/grub_setup.sh
fi

if [[ ! -f /mnt/bin/grub-mkconfig ]];then
	bootctl --esp-path=/mnt/boot install
fi

umount -R /mnt 

#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

pacstrap -K /mnt base base-devel linux-firmware linux-api-headers zsh terminus-font htop man-db man-pages

cp /etc/zsh/zshrc /mnt/root/.zshrc
cp /etc/zsh/zprofile /mnt/root/.zprofile

cp /etc/pacman.conf /mnt/etc/pacman.conf
cp /etc/pacman.conf.bck /mnt/etc/pacman.conf.bck

cp /etc/mkinitcpio.conf /mnt/etc/mkinitcpio.bck

genfstab -LUp /mnt >> /mnt/etc/fstab


cp "${LIB_DIR}/banner.sh" /mnt/bin/
cp "${SYSTEM_DIR}/chroot_setup.sh" /mnt/bin/
cp "${SYSTEM_DIR}/user_setup.sh" /mnt/bin/
cp "${BOOT_DIR}/bootloader_select.sh" /mnt/bin/
cp "${BOOT_DIR}/systemd_boot_setup.sh" /mnt/bin/
cp "${BOOT_DIR}/grub_setup.sh" /mnt/bin/
cp /run/enc_opt.sh /mnt/run/
cp /run/selected_disk.sh /mnt/run/
cp /etc/vconsole.conf /mnt/etc/vconsole.conf

if [[ -d /root/secrets ]]; then
    mkdir -p /mnt/root/secrets
    cp -r /root/secrets/* /mnt/root/secrets/
    chmod 700 /mnt/root/secrets
fi

arch-chroot /mnt /usr/bin/zsh -c "chroot_setup.sh"

if [[ -f /mnt/usr/bin/grub_setup.sh ]]; then
    rm /mnt/usr/bin/grub_setup.sh
fi

if [[ ! -f /mnt/usr/bin/grub-mkconfig ]]; then
    bootctl --esp-path=/mnt/boot install
fi

if [[ -f /root/secrets/crypto_keyfile.bin ]]; then
    shred -u -n 3 /root/secrets/crypto_keyfile.bin
fi

rm -rf /root/secrets

umount -R /mnt

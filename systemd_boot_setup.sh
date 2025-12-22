#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz
source /run/enc_opt.sh

ucode_package=""

sd_boot_mount_option(){
	umount -R /boot 2>/dev/null || true
	rm -rf /boot/*
	mount --mkdir -t vfat -o nodev,nosuid,noexec,fmask=0077,dmask=0077 LABEL=EFI /boot
	systemctl daemon-reload
	truncate -s 0 /etc/fstab
	pacman -S arch-install-scripts --noconfirm && wait
	genfstab -LUp / > /etc/fstab
	pacman -Rns arch-install-scripts --noconfirm && wait
}

install_packages(){
	cpu_vendor=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ "$cpu_vendor" == "GenuineIntel" ]; then
    		ucode_package="intel-ucode"
	elif [ "$cpu_vendor" == "AuthenticAMD" ]; then
    		ucode_package="amd-ucode"
	fi
	pacman -Syyu linux linux-headers linux-cachyos linux-cachyos-headers $ucode_package arch-install-scripts btrfs-progs  efibootmgr dosfstools mtools efitools mkinitcpio --noconfirm --needed && wait
}

c_mkinitcpio(){
	cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bck
	sed -i "s|^MODULES=.*|MODULES=(btrfs)|g" /etc/mkinitcpio.conf
	sed -i "s|^BINARIES=.*|BINARIES=(\"/usr/bin/btrfs\")|g" /etc/mkinitcpio.conf
	sed -i '/#COMPRESSION="lz4"/s/^#//g' /etc/mkinitcpio.conf
	sed -i "s|^#COMPRESSION_OPTIONS=.*|#COMPRESSION_OPTIONS=(-9)|g" /etc/mkinitcpio.conf
	sed -i '/#COMPRESSION_OPTIONS=(-9)/s/^#//g' /etc/mkinitcpio.conf
}

c_luks_mkinitcpio(){
	sed -i "s|^HOOKS=.*|HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems btrfs fsck)|g" /etc/mkinitcpio.conf
}

sd_boot_entries(){
    mkdir -p /boot/loader/entries
    {
        echo "title   Arch Linux"
        echo "linux   /vmlinuz-linux-cachyos"
        [[ -n "$ucode_package" ]] && echo "initrd  /$ucode_package.img"
        echo "initrd  /initramfs-linux-cachyos.img"
    } > /boot/loader/entries/arch.conf

    {
        echo "default  arch.conf"
        echo "timeout  5"
        echo "console-mode max"
        echo "editor   no"
    } > /boot/loader/loader.conf
}


sd_boot_non_luks(){
	sd_boot_mount_option
	echo "systemd-boot kuruluyor..."
	sleep 2
	clear
	install_packages
	c_mkinitcpio
	mkinitcpio -P
	sd_boot_entries
	BLKID=$(blkid -s UUID -o value -t LABEL="ArchLinux")	
	echo "options nowatchdog nvme_load=YES zswap.enabled=0 loglevel=3 root=UUID=$BLKID rootflags=subvol=@ rw" >> /boot/loader/entries/arch.conf
	bootctl --esp-path=/boot install 
	bootctl --esp-path=/boot update
}


sd_boot_luks(){
	sd_boot_mount_option
	echo "systemd-boot kuruluyor..."
	sleep 2
	clear
	install_packages
	c_mkinitcpio
	c_luks_mkinitcpio
	mkinitcpio -P
	sd_boot_entries
	BLKID=$(blkid -s UUID -o value -t TYPE="crypto_LUKS")	
	echo "options nowatchdog nvme_load=YES zswap.enabled=0 loglevel=3 rd.luks.name=$BLKID=ArchLinux rd.luks.options=discard rootflags=subvol=@ root=/dev/mapper/ArchLinux rw" >> /boot/loader/entries/arch.conf
	bootctl --esp-path=/boot install
	bootctl --esp-path=/boot update
}

if [ "$encrypt_option" == "h" ]; then
	sd_boot_non_luks
elif [ "$encrypt_option" == "e" ]; then
	sd_boot_luks
fi

clear
banner.sh
echo "Sistemler Etkinleştiriliyor..."
sleep 2
clear
banner.sh
systemctl enable NetworkManager fstrim.timer sshd
echo "Sistemler Etkinleştirildi."

sleep 2.0
clear 
banner.sh

unset selected_disk encrypt_option

shred -u -n 3 /run/selected_disk.sh /run/enc_opt.sh

DISK_PATH=$(blkid -t TYPE="crypto_LUKS" -o device | head -n 1)
KEY_FILE="/root/secrets/crypto_keyfile.bin"

if [[ -n "$DISK_PATH" ]] && [[ -f "$KEY_FILE" ]]; then
    echo "Geçici kurulum anahtarı disk yetkisi iptal ediliyor..."
    cryptsetup luksRemoveKey "$DISK_PATH" "$KEY_FILE"
fi

rm -rf /bin/systemd_boot_setup.sh /bin/bootloader_select.sh /bin/banner.sh /bin/user_setup.sh

GREEN='\033[1;32m'
RESET='\033[0m'
echo "Tüm işlemler tamamlandı."
sleep 1
echo -e "${GREEN}Arch Linux kurulumu başarıyla tamamlandı!${RESET}"
fastfetch

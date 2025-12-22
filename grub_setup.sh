#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz
source /run/selected_disk.sh
source /run/enc_opt.sh

[[ -f "/run/enc.sh" ]] && source /run/enc.sh

install_packages(){
	cpu_vendor=$(grep vendor_id /proc/cpuinfo | awk 'NR==1{print $3}')
	if [ "$cpu_vendor" == "GenuineIntel" ]; then
		ucode_package="intel-ucode"
	elif [ "$cpu_vendor" == "AuthenticAMD" ]; then
		ucode_package="amd-ucode"
	else
		echo "Desteklenmeyen işlemci modeli."
		exit 1
	fi
	pacman -Syyu linux linux-headers linux-cachyos linux-cachyos-headers $ucode_package arch-install-scripts btrfs-progs grub efibootmgr dosfstools mtools os-prober efitools mkinitcpio --noconfirm --needed && wait
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
	sed -i "s|^HOOKS=.*|HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems btrfs fsck)|g" /etc/mkinitcpio.conf
	sed -i "s|^FILES=.*|FILES=(/root/secrets/crypto_keyfile.bin)|g" /etc/mkinitcpio.conf
}

crypto_key(){
	mkdir /root/secrets && chmod 700 /root/secrets
	head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
	DISK=$(blkid | grep 'TYPE="crypto_LUKS"' | awk -F: '{print $1}')
	echo "$PASSWORD" | cryptsetup --force-password -v luksAddKey -i 1 "$DISK" /root/secrets/crypto_keyfile.bin
	sleep 0.5
	clear
	banner.sh
}
c_grub_prms(){
	cp /etc/default/grub /etc/default/grub.bck
	new_params="nowatchdog nvme_load=YES zswap.enabled=0 loglevel=3"
	sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$new_params\"/" /etc/default/grub
	sed -i 's/^GRUB_PRELOAD_MODULES="[^"]*"/GRUB_PRELOAD_MODULES="part_gpt part_msdos btrfs"/' /etc/default/grub
}

c_grub_prms_luks(){
	sed -i '/GRUB_ENABLE_CRYPTODISK/s/^#//g' /etc/default/grub
	BLKID=$(blkid | grep 'TYPE="crypto_LUKS"' | head -n 1 | cut -d '"' -f 2)
	GRUBCMD="\"rd.luks.name=$BLKID=ArchLinux rd.luks.options=allow-discards root=/dev/mapper/ArchLinux rootflags=subvol=@ rd.luks.key=$BLKID=/root/secrets/crypto_keyfile.bin\""
	sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=${GRUBCMD}|g" /etc/default/grub
	GRUB_MODULES="all_video boot btrfs cat chain configfile echo efifwsetup efinet ext2 fat font gettext gfxmenu gfxterm gfxterm_background gzio halt help hfsplus iso9660 jpeg keystatus loadenv loopback linux ls lsefi lsefimmap lsefisystab lssal memdisk minicmd normal ntfs part_apple part_msdos part_gpt password_pbkdf2 png probe reboot regexp search search_fs_uuid search_fs_file search_label sleep smbios squash4 test true video xfs zfs zfscrypt zfsinfo cpuid play tpm cryptodisk gcry_arcfour gcry_blowfish gcry_camellia gcry_cast5 gcry_crc gcry_des gcry_dsa gcry_idea gcry_md4 gcry_md5 gcry_rfc2268 gcry_rijndael gcry_rmd160 gcry_rsa gcry_seed gcry_serpent gcry_sha1 gcry_sha256 gcry_sha512 gcry_tiger gcry_twofish gcry_whirlpool luks lvm mdraid09 mdraid1x raid5rec raid6rec"
	sed -i 's/^GRUB_PRELOAD_MODULES="[^"]*"/GRUB_PRELOAD_MODULES="part_gpt part_msdos btrfs cryptodisk"/' /etc/default/grub
	chmod 700 /boot
	sleep 0.5
	clear
	banner.sh
}

c_grub(){
	echo "Grub kuruluyor ..."
	install_packages
	c_mkinitcpio
	mkinitcpio -P
	c_grub_prms
	sleep 1.5
	clear
	banner.sh
	if [[ -d /sys/firmware/efi ]];then
		mount --mkdir -t vfat -o nodev,nosuid,noexec,dmask=0077,fmask=0077 LABEL=EFI /boot/efi
		systemctl daemon-reload
		rm -rf /etc/fstab
		genfstab -LUp / >> /etc/fstab
		pacman -Rns arch-install-scripts --noconfirm && wait
		grub-install --target x86_64-efi --efi-directory /boot/efi --boot-directory /boot
		grub-mkconfig -o /boot/grub/grub.cfg
	else
		grub-install --target i386-pc "$selected_disk"
		grub-mkconfig -o /boot/grub/grub.cfg
	fi
	echo "Grub kurulumu tamamlandı. "
	sleep 2
	clear
}

c_grub_luks(){
	echo "Grub kuruluyor... "
	install_packages
	c_mkinitcpio
	crypto_key
	c_luks_mkinitcpio
	mkinitcpio -P
	c_grub_prms
	c_grub_prms_luks
	if [[ -d /sys/firmware/efi ]];then
		mount --mkdir -t vfat -o nodev,nosuid,noexec,dmask=0077,fmask=0077 LABEL=EFI /boot/efi
		systemctl daemon-reload
		rm -rf /etc/fstab
		genfstab -LUp / >> /etc/fstab
		pacman -Rns arch-install-scripts --noconfirm && wait
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot --modules="${GRUB_MODULES}" --disable-shim-lock
		grub-mkconfig -o /boot/grub/grub.cfg
	else
		grub-install --target=i386-pc "$selected_disk" --disable-shim-lock
		grub-mkconfig -o /boot/grub/grub.cfg
	fi
	echo "Grub kurulumu tamanlandı. "
	sleep 2
	clear
}


if [ "$encrypt_option" == "h" ]; then
	c_grub

elif [ "$encrypt_option" == "e" ]; then
	c_grub_luks
fi

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

unset PASSWORD encrypt_option selected_disk
shred -u -n 3 /run/selected_disk.sh /run/enc_opt.sh

[[ -f /run/enc.sh ]] && shred -u -n 3 /run/enc.sh

rm -rf /bin/banner.sh /bin/grub_setup.sh /bin/bootloader_select.sh /bin/user_setup.sh

GREEN='\033[1;32m'
RESET='\033[0m'
echo "Tüm işlemler tamamlandı."
sleep 1
echo -e "${GREEN}Arch Linux kurulumu başarıyla tamamlandı!${RESET}"
fastfetch

#!/bin/bash

set -eou pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

while :; do
    read -s -p "Lütfen şifreyi girin: " password1
    echo
    read -s -p "Şifreyi doğrulamak için tekrar girin: " password2
    echo

    if [[ -z "$password1" ]]; then
	sleep 0.5
	clear
	source ./banner.sh
        echo "Şifre boş olamaz! Lütfen geçerli bir şifre girin."
    elif [[ "$password1" != "$password2" ]]; then
	sleep 0.5
	clear
	source ./banner.sh
        echo "Şifreler eşleşmiyor! Lütfen tekrar deneyin."
    else
        echo "Şifre başarıyla doğrulandı."
        PASSWORD="$password1"
	echo "export PASSWORD=$PASSWORD" > "$SCRIPT_DIR"/enc.sh
        break
    fi
done

disc_efi(){
  sgdisk --zap-all --clear -n 1:0:+1GiB -c 1:EFI -t 1:ef00 -n 2:0:0 -c 2:ArchLinux -t 2:8309 "$selected_disk"
  efi_part=$(blkid | grep 'LABEL="EFI"' | awk -F: '{print $1}')
  mkfs.vfat -F32 -n EFI "$efi_part"
  root_part=$(blkid | grep 'LABEL="ArchLinux"' | awk -F: '{print $1}')
  echo -n "$PASSWORD" | cryptsetup luksFormat --perf-no_read_workqueue --perf-no_write_workqueue --type luks2 --use-random --verify-passphrase --cipher aes-xts-plain64 -S 1 -s 512 -h sha512 -i 2000 --pbkdf pbkdf2 --force-password "$root_part"
  echo -n "$PASSWORD" | cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent --force-password open "$root_part" ArchLinux
}

create_disk_no() {
  echo "$selected_disk$([[ "$selected_disk" == *"nvme"* ]] && echo p)$1"
}

disc_mbr(){
  echo -e "o\nn\np\n1\n\n\nw" | fdisk "$selected_disk"
  root_no=1
  echo -n "$PASSWORD" | cryptsetup luksFormat --perf-no_read_workqueue --perf-no_write_workqueue --type luks2 --use-random --verify-passphrase --cipher aes-xts-plain64 -S 1 -s 512 -h sha512 -i 2000 --pbkdf pbkdf2 --force-password "$(create_disk_no "$root_no")"
  echo -n "$PASSWORD" | cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --force-password open "$(create_disk_no "$root_no")" ArchLinux
}

if [[ -d /sys/firmware/efi ]]; then
  disc_efi
else
  disc_mbr
fi

mkfs.btrfs -f -L ArchLinux /dev/mapper/ArchLinux

partprobe "$selected_disk"

# Biçimlendirilmiş Btfs partitionunu subvolleri oluşturmak için mount etmek
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120 LABEL=ArchLinux /mnt

# /mnt dizinine girmek
cd /mnt
# @ btrfs subvolume oluşturmak
btrfs su cr @

# @/var btrfs subvolume oluşturmak
btrfs su cr @/var

# @/usr klasörünü oluşturmak
mkdir @/usr

# @/usr/local subvolume oluşturmak
btrfs su cr @/usr/local

# @/srv subvolume oluşturmak
btrfs su cr @/srv

# @/root subvolume oluşturmak
btrfs su cr @/root

# @/opt subvolume oluşturmak
btrfs su cr @/opt

# @/tmp subvolume oluşturmak
btrfs su cr @/tmp

# @/home subvolume oluşturmak
btrfs su cr @/home

# Ana dizine Dönmek
cd

# /mnt dizinini btrfs subvolumeleri ve subvolidler ile mount etmek için umount etmek
umount /mnt

# /mnt dizinini Pacstrap kısmına hazırlamak için subvollerin ve subvolidlerin mount edilmesi
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@,subvolid=256 LABEL=ArchLinux /mnt
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/var,subvolid=257 LABEL=ArchLinux /mnt/var
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/usr/local,subvolid=258 LABEL=ArchLinux /mnt/usr/local
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/srv,subvolid=259 LABEL=ArchLinux /mnt/srv
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/root,subvolid=260 LABEL=ArchLinux /mnt/root
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/opt,subvolid=261 LABEL=ArchLinux /mnt/opt
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/tmp,subvolid=262 LABEL=ArchLinux /mnt/tmp
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/home,subvolid=263 LABEL=ArchLinux /mnt/home

clear 
sh "$SCRIPT_DIR"/banner.sh

# subvolumeleri listelemek
btrfs su l /mnt

# disk durumunu detaylı bir şekilde göstermek
lsblk -f
sleep 1.5
clear
sh "$SCRIPT_DIR"/banner.sh

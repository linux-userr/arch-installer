#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# Tüm disk bölümlerini temizle ve BIOS/EFI ve Arch Linux bölümlerini oluştur

disc_efi(){
    sgdisk --zap-all --clear \
        -n 1:0:+1GiB -c 1:EFI -t 1:ef00 \
        -n 2:0:0 -c 2:ArchLinux -t 2:8300 "$selected_disk"

    partprobe "$selected_disk"
    udevadm settle

    root_part=$(blkid -t PARTLABEL="ArchLinux" -o device "$selected_disk"*)
    efi_part=$(blkid -t PARTLABEL="EFI" -o device "$selected_disk"*)

    if [[ -z "$root_part" ]]; then echo "Hata: Root partition bulunamadı!"; exit 1; fi

    mkfs.vfat -F32 -n EFI "$efi_part"

    mkfs.btrfs -f -L ArchLinux "$root_part"

}

create_disk_no() {
  echo "$selected_disk$([[ "$selected_disk" == *"nvme"* ]] && echo p)$1"
}

disc_mbr(){
  echo -e "o\nn\np\n1\n\n\nw" | fdisk "$selected_disk"
  root_no=1
  mkfs.btrfs -f -L ArchLinux "$(create_disk_no "$root_no")"
}

if [[ -d /sys/firmware/efi ]]; then
  disc_efi
else
  disc_mbr
fi

	
# EFI ve Arch Linux bölümlerini oluştur
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
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@ LABEL=ArchLinux /mnt
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/var LABEL=ArchLinux /mnt/var
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/usr/local LABEL=ArchLinux /mnt/usr/local
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/srv LABEL=ArchLinux /mnt/srv
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/root LABEL=ArchLinux /mnt/root
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/opt LABEL=ArchLinux /mnt/opt
mount -t btrfs -o defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120,subvol=@/home LABEL=ArchLinux /mnt/home

clear
show_banner
# subvolumeleri listelemek
btrfs su l /mnt

# disk durumunu detaylı bir şekilde göstermek
lsblk -f
sleep 1.5
clear
show_banner

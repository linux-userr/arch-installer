#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# Selected disk kontrolü
selected_disk="${1:-${selected_disk:-}}"
if [[ -z "$selected_disk" ]]; then
    echo "Hata: Kurulum yapılacak disk belirtilmedi!" >&2
    exit 1
fi

LABEL="ArchLinux"
OPTS="defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120"

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
    mkfs.btrfs -f -L "$LABEL" "$root_part"
}

create_disk_no() {
    echo "$selected_disk$([[ "$selected_disk" == *"nvme"* ]] && echo p)$1"
}

disc_mbr(){
    echo -e "o\nn\np\n1\n\n\nw" | fdisk "$selected_disk"
    root_no=1
    mkfs.btrfs -f -L "$LABEL" "$(create_disk_no "$root_no")"
}

if [[ -d /sys/firmware/efi ]]; then
    disc_efi
else
    disc_mbr
fi

SUBVOLS=( "@" "@/var" "@/usr/local" "@/srv" "@/root" "@/opt" "@/tmp" "@/home" )
MOUNT_SUBVOLS=( "@" "@/var" "@/usr/local" "@/srv" "@/root" "@/opt" "@/home" )

# 1. Kök alt birimi geçici olarak bağla ve tüm subvolume'leri oluştur
mkdir -p /mnt
mount -t btrfs -o "$OPTS" LABEL="$LABEL" /mnt

for sub in "${SUBVOLS[@]}"; do
    mkdir -p "/mnt/$(dirname "$sub")"
    btrfs subvolume create "/mnt/$sub"
done

umount /mnt

# 2. Seçilen subvolume'leri ana sisteme bağla
for sub in "${MOUNT_SUBVOLS[@]}"; do
    target="/mnt${sub#@}"
    mkdir -p "$target"
    mount -t btrfs -o "$OPTS,subvol=$sub" LABEL="$LABEL" "$target"
done

clear
show_banner
btrfs su l /mnt
lsblk -f
sleep 1.5
clear
show_banner

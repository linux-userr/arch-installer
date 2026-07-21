#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

selected_disk="${1:-${selected_disk:-}}"
if [[ -z "$selected_disk" ]]; then
    echo "Hata: Kurulum yapılacak disk belirtilmedi!" >&2
    exit 1
fi

LABEL="ArchLinux"
OPTS="defaults,rw,noatime,compress-force=zstd:2,ssd,discard=async,space_cache=v2,commit=120"

while :; do
    read -r -s -p "Lütfen şifreyi girin: " password1
    echo
    read -r -s -p "Şifreyi doğrulamak için tekrar girin: " password2
    echo

    if [[ -z "$password1" ]]; then
        sleep 0.5
        clear
        show_banner
        echo "Şifre boş olamaz! Lütfen geçerli bir şifre girin."
    elif [[ "$password1" != "$password2" ]]; then
        sleep 0.5
        clear
        show_banner
        echo "Şifreler eşleşmiyor! Lütfen tekrar deneyin."
    else
        echo "Şifre başarıyla doğrulandı."
        PASSWORD="$password1"
        break
    fi
done

disc_efi() {
    sgdisk --zap-all --clear \
        -n 1:0:+1GiB -c 1:EFI -t 1:ef00 \
        -n 2:0:0 -c 2:ArchLinux -t 2:8309 "$selected_disk"

    partprobe "$selected_disk"
    udevadm settle

    root_part=$(blkid -t PARTLABEL="ArchLinux" -o device "$selected_disk"*)
    efi_part=$(blkid -t PARTLABEL="EFI" -o device "$selected_disk"*)

    if [[ -z "$root_part" ]]; then
        echo "Hata: Root partition bulunamadı!"
        exit 1
    fi

    mkfs.vfat -F32 -n EFI "$efi_part"

    echo -n "$PASSWORD" | cryptsetup luksFormat --perf-no_read_workqueue --perf-no_write_workqueue --type luks2 --use-random --verify-passphrase --cipher aes-xts-plain64 -S 1 -s 512 -h sha512 -i 2000 --pbkdf pbkdf2 --force-password "$root_part"
    echo -n "$PASSWORD" | cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent --force-password open "$root_part" ArchLinux

    mkfs.btrfs -f -L "$LABEL" /dev/mapper/ArchLinux
    mkdir -p /root/secrets && chmod 700 /root/secrets
    head -c 64 /dev/urandom >/root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin

    echo -n "$PASSWORD" | cryptsetup -v luksAddKey "$root_part" /root/secrets/crypto_keyfile.bin
}

create_disk_no() {
    echo "$selected_disk$([[ "$selected_disk" == *"nvme"* ]] && echo p)$1"
}

disc_mbr() {
    echo -e "o\nn\np\n1\n\n\nw" | fdisk "$selected_disk"
    root_no=1
    local root_p
    root_p=$(create_disk_no "$root_no")
    echo -n "$PASSWORD" | cryptsetup luksFormat --perf-no_read_workqueue --perf-no_write_workqueue --type luks2 --use-random --verify-passphrase --cipher aes-xts-plain64 -S 1 -s 512 -h sha512 -i 2000 --pbkdf pbkdf2 --force-password "$root_p"
    echo -n "$PASSWORD" | cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --force-password open "$root_p" ArchLinux

    mkfs.btrfs -f -L "$LABEL" /dev/mapper/ArchLinux
    mkdir -p /root/secrets && chmod 700 /root/secrets
    head -c 64 /dev/urandom >/root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin

    echo -n "$PASSWORD" | cryptsetup -v luksAddKey "$root_part" /root/secrets/crypto_keyfile.bin
}

if [[ -d /sys/firmware/efi ]]; then
    disc_efi
else
    disc_mbr
fi

SUBVOLS=("@" "@/var" "@/usr/local" "@/srv" "@/root" "@/opt" "@/tmp" "@/home")
MOUNT_SUBVOLS=("@" "@/var" "@/usr/local" "@/srv" "@/root" "@/opt" "@/home")

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

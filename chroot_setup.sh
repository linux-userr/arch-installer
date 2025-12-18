#!/bin/bash


set -eou pipefail
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# IP'den zaman dilimini al
timezone=$(curl -s https://ipinfo.io/timezone)

# Zaman dilimini kullanarak saat dilimini ayarla
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc


while true; do
    sleep 0.5
    clear
    banner.sh

    read -p "Yeni hostname'i girin: " new_hostname

    # Uzunluk kontrolü (boş ya da 61'den büyük)
    if (( ${#new_hostname} < 1 || ${#new_hostname} > 61 )); then
        echo "Hata: Hostname 1 ile 61 karakter arasında olmalıdır!"

    # Geçersiz karakter kontrolü
    elif [[ "$new_hostname" =~ [^a-zA-Z0-9_] ]]; then
        echo "Hata: Hostname yalnızca harf, rakam ve alt çizgi (_) içerebilir!"

    else
        # Her şey geçerliyse döngüden çık
        break
    fi
done



# /etc/hostname dosyasını güncelle
echo "$new_hostname" | tee /etc/hostname > /dev/null

# /etc/hosts dosyasını güncelle
cat <<EOF > /etc/hosts
127.0.0.1       localhost
::1             localhost
127.0.0.1       $new_hostname.localdomain       $new_hostname
EOF

echo "$new_hostname, /etc/hostname dosyasına başarıyla eklendi."
echo "/etc/hosts dosyası başarıyla düzenlendi."
sleep 2.5

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

clear
banner.sh
locale-gen
echo 0.5
clear
banner.sh

pacman-key --init && pacman-key --populate && pacman -S archlinux-keyring --noconfirm

# Pacman config dosya yolu
pacman_conf=/etc/pacman.conf

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 
pacman-key --lsign-key 3056513887B78AEB 
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

sed -i '/^\[multilib\]/{
    n
    a\
\
[chaotic-aur]\
Include = /etc/pacman.d/chaotic-mirrorlist
}' /etc/pacman.conf


pacman -Syu --noconfirm && wait 

curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz && wait
tar xvf cachyos-repo.tar.xz && cd cachyos-repo && sed -i '/${mirror_url}\/pacman/ s/$/ --noconfirm/' cachyos-repo.sh;sed -i '/pacman -Syu/ s/$/ --noconfirm/' cachyos-repo.sh;sed -i 's/\(${mirror_url}.*\.zst"\)/\1 --noconfirm/' cachyos-repo.sh
./cachyos-repo.sh
wait

pacman -Syu xdg-user-dirs xorg xorg-xinit xorg-appres sysfsutils xorg-xwayland wayland-utils xorg-xauth vim nano p7zip unzip unrar zip udisks2 gvfs-afc gvfs-mtp gvfs-gphoto2 gphoto2 sudo mkinitcpio git wget curl networkmanager openssh mlocate inxi noto-fonts ttf-dejavu ttf-dejavu-nerd ttf-roboto ttf-roboto-mono ttf-roboto-mono-nerd gnu-free-fonts noto-fonts noto-fonts-emoji noto-fonts-extra ttf-font-awesome ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-liberation ttf-liberation-mono-nerd ttf-nerd-fonts-symbols-mono ttf-nerd-fonts-symbols-common ttf-roboto ttf-roboto-mono ttf-roboto-mono-nerd awesome-terminal-fonts ttf-font-awesome otf-font-awesome pipewire pipewire-pulse pipewire-alsa pipewire-audio pipewire-jack lib32-pipewire lib32-pipewire-jack wireplumber alsa-tools alsa-utils alsa-firmware fastfetch --noconfirm --needed
wait

pacman -Suuy --noconfirm && wait
pacman -Syu && wait
user_setup.sh

sleep 1.5

# mkinitcpio.conf dosyasını düzenleme
bootloader_select.sh

rm /bin/chroot_setup.sh

#!/bin/bash

# --- Hata Yönetimi ve Ortam Ayarları ---
set -Eeuo pipefail
IFS=$'\n\t'

# Kurulum sırasında daha iyi okunabilirlik için konsol fontunu ayarla
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# --- Fonksiyonlar ---

# Başlamadan önce internet bağlantısını kontrol et
check_internet() {
    if ! curl -s --head https://google.com > /dev/null; then
        echo "Hata: İnternet bağlantısı yok! Lütfen ağınızı kontrol edin."
        exit 1
    fi
}

# --- 1. Zaman Dilimi Yapılandırması ---
echo ">> Zaman dilimi ayarlanıyor..."
check_internet
# IP üzerinden zaman dilimini al, başarısız olursa UTC'ye dön
timezone=$(curl -s https://ipinfo.io/timezone || echo "UTC")

if [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
    ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    echo "Zaman dilimi ayarlandı: $timezone"
else
    echo "Uyarı: Zaman dilimi bulunamadı, UTC varsayılan olarak ayarlanıyor."
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
fi

hwclock --systohc

# --- 2. Hostname (Makine Adı) Yapılandırması ---
while true; do
    echo ""
    read -p "Yeni hostname'i girin: " new_hostname

    # RFC 1123 Uyumluluk Kontrolü:
    # 1. Uzunluk 1-63 karakter arası
    # 2. Sadece harf, rakam ve tire (-)
    # 3. Tire ile başlayamaz veya bitemez
    if [[ ${#new_hostname} -lt 1 || ${#new_hostname} -gt 63 ]]; then
        echo "Hata: Hostname 1 ile 63 karakter arasında olmalıdır!"
    elif [[ ! "$new_hostname" =~ ^[a-zA-Z0-9-]+$ ]]; then
        echo "Hata: Hostname sadece harf, rakam ve tire içerebilir (Alt çizgi _ kullanılamaz)!"
    elif [[ "$new_hostname" =~ ^- || "$new_hostname" =~ -$ ]]; then
        echo "Hata: Hostname tire (-) ile başlayamaz veya bitemez!"
    else
        break
    fi
done

echo "$new_hostname" > /etc/hostname

cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.0.1   $new_hostname.localdomain $new_hostname
EOF

echo ">> Hostname başarıyla ayarlandı: $new_hostname"
sleep 1

# --- 3. Yerel Ayarlar (Locale) ---
echo ">> Yerel ayarlar yapılandırılıyor (en_US.UTF-8)..."
# Mevcut satırı güvenli bir şekilde yorumdan çıkar
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# --- 4. Paket Yöneticisi ve Depolar ---
echo ">> Pacman anahtarları hazırlanıyor..."
pacman-key --init
pacman-key --populate archlinux

# 32-bit desteği için [multilib] deposunu etkinleştir
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo ">> Paket veritabanları güncelleniyor..."
pacman -Syu --noconfirm

# --- 5. Chaotic AUR Kurulumu ---
echo ">> Chaotic AUR deposu ekleniyor..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    cat <<EOF >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
fi

# Yeni repolarla birlikte tüm sistemi ve veritabanlarını güncelle
pacman -Syyu --noconfirm

# --- 6. Paket Kurulumu ---
echo ">> Sistem paketleri kuruluyor..."

# Kategorize edilmiş paket listeleri
sys_utils=(base-devel sudo git wget curl vim nano mkinitcpio networkmanager openssh mlocate inxi sysfsutils p7zip unzip unrar zip udisks2 pacman-contrib)
display=(xorg xorg-xinit xorg-appres xorg-xwayland wayland-utils xorg-xauth xdg-user-dirs gvfs-afc gvfs-mtp gvfs-gphoto2 gphoto2)
audio=(pipewire pipewire-pulse pipewire-alsa pipewire-audio pipewire-jack lib32-pipewire lib32-pipewire-jack wireplumber alsa-tools alsa-utils alsa-firmware)
fonts=(noto-fonts ttf-dejavu ttf-dejavu-nerd ttf-roboto ttf-roboto-mono ttf-roboto-mono-nerd gnu-free-fonts noto-fonts-emoji noto-fonts-extra ttf-font-awesome otf-font-awesome ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-liberation ttf-liberation-mono-nerd ttf-nerd-fonts-symbols-mono ttf-nerd-fonts-symbols-common awesome-terminal-fonts)

pacman -S --needed --noconfirm "${sys_utils[@]}" "${display[@]}" "${audio[@]}" "${fonts[@]}" fastfetch

# --- 7. Alt Scriptlerin Çalıştırılması ---
echo ">> Alt yapılandırmalar başlatılıyor..."
[[ -f /bin/user_setup.sh ]] && bash /bin/user_setup.sh || echo "Uyarı: user_setup.sh bulunamadı!"
[[ -f /bin/bootloader_select.sh ]] && bash /bin/bootloader_select.sh || echo "Uyarı: bootloader_select.sh bulunamadı!"

# --- 8. Kendi Kendini İmha (Temizlik) ---
echo ">> Kurulum bitti. Script temizleniyor..."
rm -- "$0"

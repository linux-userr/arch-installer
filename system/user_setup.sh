#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

[[ "$-" == *x* ]] && {
    echo "Hata: Bu script debug modunda (-x) çalıştırılamaz, şifreler açığa çıkabilir!" >&2
    exit 1
}

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

while true; do
    sleep 0.5
    clear
    banner.sh
    read -r -p "Yeni kullanıcı adını girin: " username
    if [ ${#username} -lt 1 ]; then
        echo "Hata: Geçersiz kullanıcı adı. Boş bırakılamaz."
        sleep 0.5
        clear
        banner.sh
    elif [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "Hata: Kullanıcı adı küçük harf veya alt çizgi ile başlamalı, Türkçe/büyük harf veya özel karakter içermemelidir."
        sleep 0.5
        clear
        banner.sh
    else
        if id "$username" &>/dev/null; then
            echo "Hata: '$username' adında bir kullanıcı zaten mevcut."
            sleep 0.5
            clear
            banner.sh
        else
            break
        fi
    fi
done

while true; do
    read -r -s -p "Kullanıcı şifresini girin: " user_password
    echo
    if [ -z "$user_password" ]; then
        echo "Hata: Şifre boş bırakılamaz! Lütfen geçerli bir şifre girin."
        sleep 0.5
        clear
        banner.sh
        continue
    fi

    read -r -s -p "Şifreyi tekrar girin: " user_password_confirm
    echo
    if [ "$user_password" != "$user_password_confirm" ]; then
        echo "Hata: Parolalar eşleşmiyor. Lütfen tekrar deneyin."
        sleep 0.5
        clear
        banner.sh
    else
        break
    fi
done

while true; do
    read -r -s -p "Root şifresini girin: " root_password
    echo
    if [ -z "$root_password" ]; then
        echo "Hata: Şifre boş bırakılamaz! Lütfen geçerli bir şifre girin."
        sleep 0.5
        clear
        banner.sh
        continue
    fi

    read -r -s -p "Şifreyi tekrar girin: " root_password_confirm
    echo
    if [ "$root_password" != "$root_password_confirm" ]; then
        echo "Hata: Parolalar eşleşmiyor. Lütfen tekrar deneyin."
        sleep 0.5
        clear
        banner.sh
    else
        break
    fi
done

while true; do
    read -r -p "Kullanıcıya root yetkisi verilsin mi? (E/H): " root_access
    if [[ "$root_access" =~ ^[EeHh]$ ]]; then
        break
    else
        echo "Hatalı giriş! Lütfen sadece 'E' veya 'H' girin."
        sleep 0.5
        clear
        banner.sh
    fi
done

if [[ "$root_access" =~ ^[Ee]$ ]]; then
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    echo "Kullanıcıya root yetkisi verildi."
else
    echo "Kullanıcıya root yetkisi verilmedi."
fi

useradd -m -G wheel -s /usr/bin/zsh "$username"
cp /root/.zshrc "/home/$username/"
cp /root/.zprofile "/home/$username/"
chown -R "$username:$username" "/home/$username"

xdg-user-dirs-update --force

if ! echo "$username:$user_password" | chpasswd; then
    echo "Hata: '$username' kullanıcısının şifresi ayarlanamadı!" >&2
    exit 1
fi

if ! echo "root:$root_password" | chpasswd; then
    echo "Hata: Root şifresi ayarlanamadı!" >&2
    exit 1
fi

echo "Kullanıcı '$username' ve şifreler başarıyla yapılandırıldı."

sleep 0.5
clear
banner.sh

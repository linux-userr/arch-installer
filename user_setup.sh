#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# Kullanıcı adı girişi için döngü
while true; do
    sleep 0.5
    clear
    banner.sh
    read -p "Yeni kullanıcı adını girin: " username
    if [ ${#username} -lt 1 ]; then
        echo "Hata: Geçersiz kullanıcı adı. Boş bırakılamaz."
	sleep 0.5
	clear
	banner.sh
    elif [[ "$username" =~ [^a-zA-Z0-9_] ]]; then
        echo "Hata: Kullanıcı adı yalnızca alfasayısal ve alt çizgi karakterlerinden oluşmalıdır."
    else
        # Kullanıcı adının zaten var olup olmadığını kontrol et
        if id "$username" &>/dev/null; then
            echo "Hata: '$username' adında bir kullanıcı zaten mevcut."
        else
            break
        fi
    fi
done

# Kullanıcı şifresi girişi için döngü
while true; do
    read -s -p "Kullanıcı şifresini girin: " user_password
    echo
    if [ -z "$user_password" ]; then
        echo "Hata: Şifre boş bırakılamaz! Lütfen geçerli bir şifre girin."
	sleep 0.5
	clear
	banner.sh
        continue
    fi

    read -s -p "Şifreyi tekrar girin: " user_password_confirm
    echo
    # Parolaların eşleşip eşleşmediğini kontrol et
    if [ "$user_password" != "$user_password_confirm" ]; then
        echo "Hata: Parolalar eşleşmiyor. Lütfen tekrar deneyin."
	sleep 0.5
	clear
	banner.sh
    else
        break
    fi
done

# Root şifresi girişi için döngü
while true; do
    read -s -p "Root şifresini girin: " root_password
    echo
    if [ -z "$root_password" ]; then
        echo "Hata: Şifre boş bırakılamaz! Lütfen geçerli bir şifre girin."
	sleep 0.5
	clear
	banner.sh
        continue
    fi

    read -s -p "Şifreyi tekrar girin: " root_password_confirm
    echo
    # Parolaların eşleşip eşleşmediğini kontrol et
    if [ "$root_password" != "$root_password_confirm" ]; then
        echo "Hata: Parolalar eşleşmiyor. Lütfen tekrar deneyin."
	sleep 0.5
	clear
	banner.sh
    else
        break
    fi
done

# Kullanıcıya root yetkisi verilsin mi?
while true; do
    read -p "Kullanıcıya root yetkisi verilsin mi? (E/H): " root_access
    if [[ "$root_access" =~ ^[EeHh]$ ]]; then
        break
    else
        echo "Hatalı giriş! Lütfen sadece 'E' veya 'H' girin."
	sleep 0.5
	clear
	banner.sh
    fi
done

# Evet seçeneği seçilirse
if [[ "$root_access" =~ ^[Ee]$ ]]; then
    sed -i '/^#\s*%wheel\s*ALL=(ALL:ALL)\s*ALL/s/^#\s*//' /etc/sudoers
    echo "Defaults rootpw" >> /etc/sudoers
    echo "Kullanıcıya root yetkisi verildi."
else
    echo "Kullanıcıya root yetkisi verilmedi."
fi

# Kullanıcı oluşturma komutu
useradd -m -G wheel -s /usr/bin/zsh "$username"
cp /root/.zshrc /home/$username
cp /root/.zprofile /home/$username
chown $username:$username /home/$username/.zshrc /home/$username/.zprofile

xdg-user-dirs-update --force

# Kullanıcı ve root şifrelerini ayarla
echo "$username:$user_password" | chpasswd
echo "root:$root_password" | chpasswd

if [ $? -eq 0 ]; then
    echo "Kullanıcı '$username' başarıyla oluşturuldu."
else
    echo "Hata: Kullanıcı oluşturulurken bir sorun oluştu."
fi
sleep 0.5
clear
banner.sh

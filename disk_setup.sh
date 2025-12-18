#!/bin/bash

set -eou pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ./banner.sh

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

# Hata mesajlarını yazdırma fonksiyonu
function hata_mesaji {
    echo "Hata: $1" >&2
    exit 1
}

# Kullanıcı girişi doğrulama fonksiyonu
function kullanici_dogrulama {
    local input="$1"
    local regex="$2"
    if [[ ! "$input" =~ $regex ]]; then
        echo "Geçersiz giriş! $3"
        return 1
    fi
    return 0
}

# Disk listeleme
disks=$(lsblk -dno NAME,SIZE | grep -E 'sd[a-z]|nvme[0-9]+n[0-9]+|vd[a-z]') || hata_mesaji "Diskler alınamadı."

echo "Lütfen bir disk seçin:"
echo "$disks" | nl -s ') '

# Disk seçimi
while :; do
    	read -p "Kurulum yapmak istediğiniz diski seçin (1-$(echo "$disks" | wc -l)): " selection
	selected_disk=$(echo "$disks" | awk -v sel="$selection" 'NR==sel {print "/dev/" $1}')
	export selected_disk
	echo "export selected_disk=$selected_disk" >> "$SCRIPT_DIR"/selected_disk.sh
    	if [[ -n "$selected_disk" ]]; then
		echo "Seçilen Disk: $selected_disk"
		break
    	else
		sleep 0.5
		clear
		source ./banner.sh
	        echo "Geçersiz seçim! Lütfen geçerli bir numara girin."
	fi
done

# Disk formatlama
while :; do
    read -p "Diski formatlamak istiyor musunuz? (E/H): " format_option
    case "$format_option" in
        [Ee])
            echo "Disk formatlama işlemi başlatılıyor..."
            for i in {3..1}; do echo -ne "Kalan süre: $i\033[0K\r"; sleep 1; done
            if wipefs -af "$selected_disk"; then
                echo "Disk başarıyla formatlandı."
		sleep 1.0
		clear
            else
                hata_mesaji "Disk formatlama başarısız oldu!"
            fi
            break
            ;;
        [Hh])
            echo "Disk formatlama işlemi iptal edildi."
            exit 42
	    break
            ;;
        *)
	    echo "Seçilen Disk: $selected_disk"
            echo "Geçersiz giriş! Lütfen 'E' veya 'H' girin."
	    sleep 1.5
	    clear
	    source ./banner.sh
            ;;
    esac
done

# Şifreleme seçeneği
while :; do
    clear
    source ./banner.sh
    read -p "Diski şifrelemek istiyor musunuz? (E/H): " encrypt_option
    encrypt_option=${encrypt_option,,}
    case "$encrypt_option" in
        e)
            echo "Disk şifreleme seçildi. Şifreleme işlemi başlıyor..."
            export selected_disk
	    export encrypt_option
	    echo "export encrypt_option=$encrypt_option" > "$SCRIPT_DIR"/enc_opt.sh
	    ./disk_luks.sh "$selected_disk" || hata_mesaji "Şifreleme işlemi başarısız oldu!"
            break
            ;;
        h)
            echo "Şifreleme seçilmedi. Devam ediliyor..."
            export selected_disk
	    export encrypt_option
	    echo "export encrypt_option=$encrypt_option" > "$SCRIPT_DIR"/enc_opt.sh
	    ./disk_plain.sh "$selected_disk" || hata_mesaji "Şifresiz işlem başarısız oldu!"
            break
            ;;
        *)
	    echo "Geçersiz giriş! Lütfen 'E' veya 'H' girin."
	    sleep 1.5
	    clear
	    source ./banner.sh
            ;;
    esac
done


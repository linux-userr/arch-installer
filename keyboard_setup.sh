#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
source ./banner.sh

# Varsayılan fontu ayarla
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz


while true; do
    echo "Lütfen klavye düzeninizi seçin:"
    echo "1) Türkçe"
    echo "2) İngilizce"
    read -p "Seçiminizi yapın (1 veya 2): " choice

    case $choice in
        1)
            if localectl set-x11-keymap tr && localectl set-keymap trq && loadkeys trq; then
                echo "Klavye düzeni Türkçe olarak ayarlandı."
                selected_layout="Türkçe"
                break
            else
                echo "Hata: Türkçe klavye düzeni ayarlanamadı!"
            fi
            ;;
        2)
            if loadkeys us && localectl set-keymap us; then
                echo "Klavye düzeni İngilizce olarak ayarlandı."
                selected_layout="İngilizce"
                break
            else
                echo "Hata: İngilizce klavye düzeni ayarlanamadı!"
            fi
            ;;
        *)
		echo "Hatalı giriş! Lütfen 1 veya 2 tuşlarından birini seçin."
		sleep 0.2
		clear
		source ./banner.sh
            ;;
    esac
done

# Kullanıcı doğrulaması
while true; do
    read -p "Klavye düzeninizin doğru olduğundan emin misiniz? (E/H): " confirm

    case $confirm in
        [Ee])  # E veya e kabul edilir
            echo "Klavye düzeni başarıyla ayarlandı: $selected_layout"
	    sleep 2.0
	    clear
            break
            ;;
        [Hh])  # H veya h kabul edilir
            echo "Klavye düzeni ayarı iptal edildi. Lütfen betiği yeniden çalıştırın."
            exit 1
            ;;
        *)
            echo "Hatalı giriş! Lütfen 'E' veya 'H' tuşlarından birini seçin." 
	    sleep 0.2
	    clear
	    source ./banner.sh
	    ;;
    esac
done


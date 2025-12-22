#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

[[ -d "/sys/firmware/efi" ]]  && BL_LIST=("grub" "systemd") || BL_LIST=("grub")
SELECTION=""

select_bl() {
        last_index=$(( ${#BL_LIST[@]} - 1 ))
        if (( $last_index == 0 )); then
                SELECTION="${BL_LIST[0]}"
                return 0
        fi

        for i in "${!BL_LIST[@]}"; do
                echo "$i - ${BL_LIST[$i]}"
        done

        while [[ -z "$SELECTION" ]]; do
                read -p "Bootloader numarasi seçiniz: " BL_NO
                if [[ "$BL_NO" =~ [0-9]+ ]] && [ $BL_NO -le $last_index ]; then
                        SELECTION="${BL_LIST[$BL_NO]}"
                else
                        echo "0 - $last_index arasinda numara girişi yapiniz"
                fi


        done

}
select_bl

case "$SELECTION" in
        "grub")
                grub_setup.sh
                ;;
        "systemd")
                systemd_boot_setup.sh
                ;;
        *)
                echo "Geçersiz seçim."
		exit 42
                ;;
esac

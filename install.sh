#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

# Ana dizini BİR KEZ bulup export ediyoruz
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export SCRIPT_DIR

# Modül yollarını export ediyoruz (Alt scriptler bunları doğrudan görecek)
export LIB_DIR="${SCRIPT_DIR}/lib"
export SYSTEM_DIR="${SCRIPT_DIR}/system"
export DISK_DIR="${SCRIPT_DIR}/disk"
export BOOT_DIR="${SCRIPT_DIR}/boot"

# Fonksiyon: Banner'ı istediğin her yerden kolayca çağırmak için
show_banner() {
    # shellcheck source=/dev/null
    source "${LIB_DIR}/banner.sh"
}
export -f show_banner

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz
clear

# --- AKIŞ ---

# 1. Saat Ayarı
# shellcheck source=/dev/null
source "${SYSTEM_DIR}/time_setup.sh"

# 2. Klavye Ayarı
# shellcheck source=/dev/null
source "${SYSTEM_DIR}/keyboard_setup.sh"

# 3. Disk Ayarı
# shellcheck source=/dev/null
source "${DISK_DIR}/disk_setup.sh"

# 4. Pacman Ayarı
# shellcheck source=/dev/null
source "${SYSTEM_DIR}/pacman_setup.sh"

# 5. Pacstrap / Taban Sistem
# shellcheck source=/dev/null
source "${SYSTEM_DIR}/base_install.sh"

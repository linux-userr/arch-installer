#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

clear 
# Saat Ayarı 
./time_setup.sh

# Klavye Ayarı
./keyboard_setup.sh

#Disk Ayarı
./disk_setup.sh

#Pacman Ayarı
./pacman_setup.sh

# Pacstrap Ayarı
./base_install.sh

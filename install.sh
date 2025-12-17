#!/bin/bash

set -e

setfont /usr/share/kbd/consolefonts/ter-v16b.psf.gz

clear 
# Saat Ayarı 
./Saat_Ayari.sh

# Klavye Ayarı
./Klavye_Duzeni.sh

#Disk Ayarı
./Disk_Ayari.sh

#Pacman Ayarı
./Pacman_Ayari.sh

# Pacstrap Ayarı
./Pacstrap_Ayari.sh

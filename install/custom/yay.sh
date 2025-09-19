#!/bin/bash

# The packages are downloaded during iso creation and built there
# Therefore we can use pacman here without yay being installed
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/custom/custom-yay.packages" | grep -v '^$')
sudo pacman -S --noconfirm --needed "${packages[@]}"

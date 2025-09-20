#!/bin/bash

# The packages are downloaded during iso creation and built there
# Therefore we can use pacman here without yay being installed
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/custom/custom-yay.packages" | grep -v '^$')

for pkg in "${packages[@]}"; do
  if ! sudo pacman -S --noconfirm --needed "$pkg"; then
    echo "Failed to install $pkg, skipping..."
  fi
done

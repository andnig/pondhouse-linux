#!/bin/bash
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/custom/custom-yay.packages" | grep -v '^$')
yay -S --noconfirm --needed "${packages[@]}"

yay -S --needed --noconfirm \
  calcure \
  ttf-ms-win11-auto

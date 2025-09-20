#!/bin/bash
mapfile -t packages < <(grep -v '^#' "$HOME/.local/share/omarchy/install/custom/custom-yay.packages" | grep -v '^$')
yay -S --noconfirm --needed "${packages[@]}"

yay -S --needed --noconfirm \
  ttf-ms-win11-auto

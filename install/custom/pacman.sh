#!/bin/bash

mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/custom/custom-pacman.packages" | grep -v '^$')
sudo pacman -S --noconfirm --needed "${packages[@]}"

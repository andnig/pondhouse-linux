#!/bin/bash

mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/custom/custom-pacman.packages" | grep -v '^$')
sudo pacman -S --noconfirm --needed "${packages[@]}"

echo "Installing tpm (tmux plugin manager)"
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

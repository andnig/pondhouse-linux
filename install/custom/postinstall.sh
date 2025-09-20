#!/bin/bash
mapfile -t packages < <(grep -v '^#' "$HOME/.local/share/omarchy/install/custom/custom-yay.packages" | grep -v '^$')
yay -Sy --noconfirm --needed "${packages[@]}"

yay -S --needed --noconfirm \
  ttf-ms-win11-auto

# Install Tailscale
gum style --foreground 212 --bold "Installing Tailscale..."
omarchy-install-tailscale

# Ask which code editors to install
gum style --foreground 212 --bold "Select optional packages to install (Space to select, Enter to confirm):"
selected=$(gum choose --no-limit --selected.foreground="212" \
  "VSCode" \
  "Cursor" \
  "Windows 11")

# Install selected editors
if echo "$selected" | grep -q "VSCode"; then
  omarchy-launch-floating-terminal-with-presentation echo 'Installing VSCode...' &&
    sudo pacman -S --noconfirm visual-studio-code-bin &&
    setsid gtk-launch code
fi

if echo "$selected" | grep -q "Cursor"; then
  omarchy-launch-floating-terminal-with-presentation echo 'Installing Cursor...' &&
    sudo pacman -S --noconfirm cursor-bin &&
    setsid gtk-launch cursor
fi

if echo "$selected" | grep -q "Windows 11"; then
  omarchy-launch-tiling-terminal-with-presentation omarchy-install-virt-windows
fi

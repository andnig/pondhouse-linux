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
selected=$(
  gum choose --no-limit --selected.foreground="212" \
    "VSCode" \
    "Cursor" \
    "Zen Browser" \
    "Brave Browser" \
    "Windows 11"
)

# Install selected editors
if echo "$selected" | grep -q "VSCode"; then
  omarchy-launch-floating-terminal-with-presentation echo 'Installing VSCode...' &&
    sudo pacman -S --noconfirm visual-studio-code-bin
fi

if echo "$selected" | grep -q "Cursor"; then
  omarchy-launch-floating-terminal-with-presentation echo 'Installing Cursor...' &&
    sudo pacman -S --noconfirm cursor-bin
fi

if echo "$selected" | grep -q "Windows 11"; then
  omarchy-launch-tiling-terminal-with-presentation omarchy-install-virt-windows
fi

if echo "$selected" | grep -q "Zen Browser"; then
  omarchy-launch-floating-terminal-with-presentation echo 'Installing Zen Browser...' &&
    yay -S --noconfirm zen-browser-bin &&
    xdg-settings set default-web-browser zen.desktop || true &&
    xdg-mime default zen.desktop x-scheme-handler/http || true &&
    xdg-mime default zen.desktop x-scheme-handler/https || true
fi

if echo "$selected" | grep -q "Brave Browser"; then
  omarchy-launch-floating-terminal-with-presentation echo 'Installing Brave Browser...' &&
    yay -S --noconfirm brave-bin &&
    xdg-settings set default-web-browser brave-browser.desktop || true &&
    xdg-mime default brave-browser.desktop x-scheme-handler/http || true &&
    xdg-mime default brave-browser.desktop x-scheme-handler/https || true
fi

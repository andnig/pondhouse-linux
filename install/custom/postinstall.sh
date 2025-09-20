#!/bin/bash
gum style --foreground 212 --bold "Installing all AUR packages, if missing..."
mapfile -t packages < <(grep -v '^#' "$HOME/.local/share/omarchy/install/custom/custom-yay.packages" | grep -v '^$')
yay -Sy --noconfirm --needed "${packages[@]}"

gum style --foreground 212 --bold "Installing Microsoft fonts..."
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
    "Brave Browser" \
    "Windows 11" \
    "Claude Code" \
    "opencode"
)

# Install selected editors
if echo "$selected" | grep -q "VSCode"; then
  omarchy-launch-floating-terminal-with-presentation "echo 'Installing VSCode...'; sudo pacman -S --noconfirm visual-studio-code-bin"
fi

if echo "$selected" | grep -q "Cursor"; then
  omarchy-launch-floating-terminal-with-presentation "echo 'Installing Cursor...'; sudo pacman -S --noconfirm cursor-bin"
fi

if echo "$selected" | grep -q "Windows 11"; then
  omarchy-launch-tiling-terminal-with-presentation omarchy-install-virt-windows
fi

if echo "$selected" | grep -q "Brave Browser"; then
  omarchy-launch-floating-terminal-with-presentation "echo 'Installing Brave Browser...'; yay -S --noconfirm brave-bin"
  # Ask to set Brave as default browser
  if gum confirm "Set Brave as default browser?"; then
    echo "Setting Brave as default browser..."
    xdg-settings set default-web-browser brave-browser.desktop || true &&
      xdg-mime default brave-browser.desktop x-scheme-handler/http || true &&
      xdg-mime default brave-browser.desktop x-scheme-handler/https || true
  fi
fi

if echo "$selected" | grep -q "Claude Code"; then
  omarchy-launch-floating-terminal-with-presentation "echo 'Installing Claude Code...'; sudo pacman -S --noconfirm claude-code"
fi

if echo "$selected" | grep -q "opencode"; then
  omarchy-launch-floating-terminal-with-presentation "echo 'Installing opencode...'; sudo pacman -S --noconfirm opencode"
fi

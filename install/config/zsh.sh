#!/bin/bash

set -e # Exit on error

echo "Installing zsh and plugins for Omarchy..."

# Install zsh and related packages from pacman
sudo pacman -S --needed --noconfirm \
  zsh \
  zsh-autocomplete \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-completions

echo "Setting up custom zsh plugins directory..."

# Ensure custom zsh plugins directory exists
mkdir -p "$HOME/.zsh/plugins"
chmod 755 "$HOME/.zsh/plugins"

echo "Cloning ohmyzsh to get tmux plugin..."

git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git /tmp/ohmyzsh
cp -r /tmp/ohmyzsh/plugins/tmux "$HOME/.zsh/plugins/"
rm -rf /tmp/ohmyzsh

# Stow zsh configuration
stow -d ~/.local/share/omarchy/config -t $HOME zsh

# Set zsh as default shell for current user
echo "Setting zsh as default shell..."
chsh -s /usr/bin/zsh

echo "zsh installation complete!"
echo "Default shell changed to zsh. Please log out and back in for the change to take effect."

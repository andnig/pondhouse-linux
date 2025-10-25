#!/bin/bash

set -e # Exit on error

echo "Installing zsh and plugins for Omarchy..."

# Install zsh and related packages from pacman
sudo pacman -S --needed --noconfirm \
  zsh \
  zsh-autocomplete \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-completions \
  zsh-vi-mode

echo "Setting up custom zsh plugins directory..."

# Stow zsh configuration
stow -d ~/.local/share/omarchy/config -t $HOME zsh

# Set zsh as default shell for current user
echo "Setting zsh as default shell..."
sudo usermod -s /usr/bin/zsh "$USER"

echo "zsh installation complete!"
echo "Default shell changed to zsh. Please log out and back in for the change to take effect."

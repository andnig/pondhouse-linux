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

# Ensure custom zsh plugins directory exists
mkdir -p "$HOME/.zsh/plugins"
chmod 755 "$HOME/.zsh/plugins"

echo "Cloning ohmyzsh to get tmux plugin..."

mkdir -p "$HOME/.zsh/plugins"
echo "User home: $HOME"
ls -lah /usr/share
ls -lah /usr/share/oh-my-zsh
ls -lah /usr/share/oh-my-zsh/plugins
ls -lah $HOME/.zsh/plugins

mv /usr/share/oh-my-zsh/plugins/tmux "$HOME/.zsh/plugins/."

# Stow zsh configuration
stow -d ~/.local/share/omarchy/config -t $HOME zsh

# Set zsh as default shell for current user
echo "Setting zsh as default shell..."
sudo usermod -s /usr/bin/zsh "$USER"

echo "zsh installation complete!"
echo "Default shell changed to zsh. Please log out and back in for the change to take effect."

echo "Installing tpm (tmux plugin manager)"
rm -rf $HOME/.tmux/plugins/tpm || true
mkdir -p "$HOME/.tmux/plugins"
mv /usr/share/tmux/plugins/tpm $HOME/.tmux/plugins/tpm

#!/bin/bash

# Copy over Omarchy configs
mkdir -p ~/.config

# cp -R ~/.local/share/omarchy/config/* ~/.config/
# Use ln instead of cp to allow symlinked updates
for dir in ~/.local/share/omarchy/config/*; do
  dirname=$(basename "$dir")
  #   This doesn't work because stow creates a subdirectory
  #   stow -d ~/.local/share/omarchy/config -t $HOME/.config -R "$(basename "$dir")"
  ln -sfn "$HOME/.local/share/omarchy/config/$dirname" "$HOME/.config/$dirname"
done

# Use default bashrc from Omarchy
cp ~/.local/share/omarchy/default/bashrc ~/.bashrc

# Ensure application directory exists for update-desktop-database
mkdir -p ~/.local/share/applications

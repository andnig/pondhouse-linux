#!/bin/bash

# Copy over Omarchy configs
mkdir -p ~/.config

# cp -R ~/.local/share/omarchy/config/* ~/.config/
# Use stow instead of cp to allow symlinked updates
for dir in ~/.local/share/omarchy/config/*/; do
  stow -d ~/.local/share/omarchy/config -t ~/.config -R "$(basename "$dir")"
done

# Use default bashrc from Omarchy
cp ~/.local/share/omarchy/default/bashrc ~/.bashrc

# Ensure application directory exists for update-desktop-database
mkdir -p ~/.local/share/applications

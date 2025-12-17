#!/bin/bash

# Add LizardByte repo to pacman.conf if not already present
if ! grep -q "^\[lizardbyte\]" /etc/pacman.conf; then
    echo '
[lizardbyte]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/latest/download' | sudo tee -a /etc/pacman.conf > /dev/null
fi

# Install sunshine
sudo pacman -Sy --noconfirm sunshine

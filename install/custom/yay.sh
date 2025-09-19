#!/bin/bash

mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/custom/custom-yay.packages" | grep -v '^$')
yay -S --needed --noconfirm "${packages[@]}"

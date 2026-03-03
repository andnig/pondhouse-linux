#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export OMARCHY_ONLINE_INSTALL=true
ansi_art='
#######\   ######\  ##\   ##\ #######\  ##\   ##\  ######\  ##\   ##\  ######\  ########\       #######\   ######\ ########\  ######\  
##  __##\ ##  __##\ ###\  ## |##  __##\ ## |  ## |##  __##\ ## |  ## |##  __##\ ##  _____|      ##  __##\ ##  __##\\__##  __|##  __##\ 
## |  ## |## /  ## |####\ ## |## |  ## |## |  ## |## /  ## |## |  ## |## /  \__|## |            ## |  ## |## /  ## |  ## |   ## /  ## |
#######  |## |  ## |## ##\## |## |  ## |######## |## |  ## |## |  ## |\######\  #####\          ## |  ## |######## |  ## |   ######## |
##  ____/ ## |  ## |## \#### |## |  ## |##  __## |## |  ## |## |  ## | \____##\ ##  __|         ## |  ## |##  __## |  ## |   ##  __## |
## |      ## |  ## |## |\### |## |  ## |## |  ## |## |  ## |## |  ## |##\   ## |## |            ## |  ## |## |  ## |  ## |   ## |  ## |
## |       ######  |## | \## |#######  |## |  ## | ######  |\######  |\######  |########\       #######  |## |  ## |  ## |   ## |  ## |
\__|       \______/ \__|  \__|\_______/ \__|  \__| \______/  \______/  \______/ \________|      \_______/ \__|  \__|  \__|   \__|  \__|
'

clear
echo -e "\n\033[32m$ansi_art\033[0m\n"

# Use custom branch if instructed, otherwise default to master
OMARCHY_REF="${OMARCHY_REF:-master}"

# Set mirror based on branch
if [[ $OMARCHY_REF == "dev" ]]; then
  export OMARCHY_MIRROR=edge
  echo 'Server = https://mirror.omarchy.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
elif [[ $OMARCHY_REF == "rc" ]]; then
  export OMARCHY_MIRROR=rc
  echo 'Server = https://rc-mirror.omarchy.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
else
  export OMARCHY_MIRROR=stable
  echo 'Server = https://stable-mirror.omarchy.org/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/omarchy
OMARCHY_REPO="${OMARCHY_REPO:-andnig/dotfiles-arch}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

echo -e "\e[32mUsing branch: $OMARCHY_REF\e[0m"
cd ~/.local/share/omarchy
git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh

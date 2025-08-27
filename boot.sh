#!/bin/bash

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

sudo pacman -Sy --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/omarchy
OMARCHY_REPO="${OMARCHY_REPO:-andnig/dotfiles-arch}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

# Use custom branch if instructed, otherwise default to master
OMARCHY_REF="${OMARCHY_REF:-master}"
if [[ $OMARCHY_REF != "master" ]]; then
  echo -e "\eUsing branch: $OMARCHY_REF"
  cd ~/.local/share/omarchy
  git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh

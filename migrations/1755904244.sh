echo "Update fastfetch config with new Omarchy logo"

omarchy-refresh-config fastfetch/config.jsonc

# pondhouse-fork: ensure ~/.config/omarchy symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/omarchy && ! -L $HOME/.config/omarchy ]]; then
  ln -sfn "$OMARCHY_PATH/config/omarchy" "$HOME/.config/omarchy"
elif [[ ! -L $HOME/.config/omarchy ]]; then
  mkdir -p ~/.config/omarchy/branding
  cp $OMARCHY_PATH/icon.txt ~/.config/omarchy/branding/about.txt
fi

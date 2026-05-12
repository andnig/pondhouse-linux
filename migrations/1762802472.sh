echo "Update imv config with new keybindings"

# pondhouse-fork: ensure ~/.config/imv symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/imv && ! -L $HOME/.config/imv ]]; then
  ln -sfn "$OMARCHY_PATH/config/imv" "$HOME/.config/imv"
elif [[ ! -L $HOME/.config/imv ]]; then
  mkdir -p ~/.config/imv
  cp $OMARCHY_PATH/config/imv/config ~/.config/imv/
fi

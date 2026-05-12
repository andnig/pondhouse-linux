echo "Improve audio controls icon for default selection"

# pondhouse-fork: ensure ~/.config/wiremix symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/wiremix && ! -L $HOME/.config/wiremix ]]; then
  ln -sfn "$OMARCHY_PATH/config/wiremix" "$HOME/.config/wiremix"
elif [[ ! -L $HOME/.config/wiremix ]]; then
  if [[ ! -f ~/.config/wiremix/wiremix.toml ]]; then
    mkdir -p ~/.config/wiremix
    cp -f $OMARCHY_PATH/config/wiremix/wiremix.toml ~/.config/wiremix/
  fi
fi

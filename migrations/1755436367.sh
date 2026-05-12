echo "Add minimal starship prompt to terminal"

if omarchy-cmd-missing starship; then
  omarchy-pkg-add starship
  # pondhouse-fork: ensure ~/.config/starship.toml symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/starship.toml && ! -L $HOME/.config/starship.toml ]]; then
    ln -sfn "$OMARCHY_PATH/config/starship.toml" "$HOME/.config/starship.toml"
  elif [[ ! -L $HOME/.config/starship.toml ]]; then
    cp $OMARCHY_PATH/config/starship.toml ~/.config/starship.toml
  fi
fi

echo "Add default Ctrl+P binding for imv; backup existing config if present"

# pondhouse-fork: ensure ~/.config/imv symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/imv && ! -L $HOME/.config/imv ]]; then
  ln -sfn "$OMARCHY_PATH/config/imv" "$HOME/.config/imv"
elif [[ ! -L $HOME/.config/imv ]]; then
  if [[ -f ~/.config/imv/config ]]; then
    cp ~/.config/imv/config ~/.config/imv/config.bak.$(date +%s)
  else
    mkdir -p ~/.config/imv
  fi

  cp ~/.local/share/omarchy/config/imv/config ~/.config/imv/config
fi

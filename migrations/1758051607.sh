echo "Copy configs for ghostty + kitty so they're available as alternative terminal options"

if [[ ! -f ~/.config/ghostty/config ]]; then
  # pondhouse-fork: ensure ~/.config/ghostty symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/ghostty && ! -L $HOME/.config/ghostty ]]; then
    ln -sfn "$OMARCHY_PATH/config/ghostty" "$HOME/.config/ghostty"
  elif [[ ! -L $HOME/.config/ghostty ]]; then
    mkdir -p ~/.config/ghostty
    cp -Rpf $OMARCHY_PATH/config/ghostty/config ~/.config/ghostty/config
  fi
fi

if [[ ! -f ~/.config/kitty/kitty.conf ]]; then
  # pondhouse-fork: ensure ~/.config/kitty symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/kitty && ! -L $HOME/.config/kitty ]]; then
    ln -sfn "$OMARCHY_PATH/config/kitty" "$HOME/.config/kitty"
  elif [[ ! -L $HOME/.config/kitty ]]; then
    mkdir -p ~/.config/kitty
    cp -Rpf $OMARCHY_PATH/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
  fi
fi

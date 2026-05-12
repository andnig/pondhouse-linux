echo "Replace wofi with walker as the default launcher"

if omarchy-cmd-missing walker; then
  omarchy-pkg-add walker-bin libqalculate

  omarchy-pkg-drop wofi
  rm -rf ~/.config/wofi

  # pondhouse-fork: ensure ~/.config/walker symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/walker && ! -L $HOME/.config/walker ]]; then
    ln -sfn "$OMARCHY_PATH/config/walker" "$HOME/.config/walker"
  elif [[ ! -L $HOME/.config/walker ]]; then
    mkdir -p ~/.config/walker
    cp -r ~/.local/share/omarchy/config/walker/* ~/.config/walker/
  fi
fi

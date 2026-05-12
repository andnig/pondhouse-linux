echo "Set a default fontconfig"

if [[ ! -f $HOME/.config/fontconfig/fonts.conf ]]; then
  # pondhouse-fork: ensure ~/.config/fontconfig symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/fontconfig && ! -L $HOME/.config/fontconfig ]]; then
    ln -sfn "$OMARCHY_PATH/config/fontconfig" "$HOME/.config/fontconfig"
  elif [[ ! -L $HOME/.config/fontconfig ]]; then
    mkdir -p ~/.config/fontconfig
    cp ~/.local/share/omarchy/config/fontconfig/fonts.conf ~/.config/fontconfig/
  fi
  fc-cache -fv
fi

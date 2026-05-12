echo "Ensure .config/hypr/looknfeel.conf is available and included"

if [[ ! -f ~/.config/hypr/looknfeel.conf ]]; then
  # pondhouse-fork: ensure ~/.config/hypr symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/hypr && ! -L $HOME/.config/hypr ]]; then
    ln -sfn "$OMARCHY_PATH/config/hypr" "$HOME/.config/hypr"
  elif [[ ! -L $HOME/.config/hypr ]]; then
    cp $OMARCHY_PATH/config/hypr/looknfeel.conf ~/.config/hypr/looknfeel.conf
  fi
fi

if [[ -f ~/.config/hypr/hyprland.conf ]]; then
  grep -qx 'source = ~/.config/hypr/looknfeel.conf' ~/.config/hypr/hyprland.conf ||
    sed -i '/^source = ~\/.config\/hypr\/envs\.conf$/a source = ~/.config/hypr/looknfeel.conf' ~/.config/hypr/hyprland.conf
fi

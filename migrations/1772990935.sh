echo "Add sample low battery notification hook"

# pondhouse-fork: ensure ~/.config/omarchy symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/omarchy && ! -L $HOME/.config/omarchy ]]; then
  ln -sfn "$OMARCHY_PATH/config/omarchy" "$HOME/.config/omarchy"
elif [[ ! -L $HOME/.config/omarchy ]]; then
  mkdir -p ~/.config/omarchy/hooks/battery-low.d

  if [[ ! -f ~/.config/omarchy/hooks/battery-low.d/play-warning-sound.sample ]]; then
    cp "$OMARCHY_PATH/config/omarchy/hooks/battery-low.d/play-warning-sound.sample" ~/.config/omarchy/hooks/battery-low.d/play-warning-sound.sample
  fi
fi

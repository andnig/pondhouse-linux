echo "Adding SwayOSD theming"

if [[ ! -d ~/.config/swayosd ]]; then
  # pondhouse-fork: ensure ~/.config/swayosd symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/swayosd && ! -L $HOME/.config/swayosd ]]; then
    ln -sfn "$OMARCHY_PATH/config/swayosd" "$HOME/.config/swayosd"
  elif [[ ! -L $HOME/.config/swayosd ]]; then
    mkdir -p ~/.config/swayosd
    cp -r ~/.local/share/omarchy/config/swayosd/* ~/.config/swayosd/
  fi

  pkill swayosd-server
  setsid uwsm-app -- swayosd-server &>/dev/null &
fi

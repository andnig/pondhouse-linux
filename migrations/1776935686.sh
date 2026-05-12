echo "Recover the internal monitor at login when no external display is connected"

SERVICE=omarchy-recover-internal-monitor.service

# pondhouse-fork: ensure ~/.config/systemd symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/systemd && ! -L $HOME/.config/systemd ]]; then
  ln -sfn "$OMARCHY_PATH/config/systemd" "$HOME/.config/systemd"
elif [[ ! -L $HOME/.config/systemd ]]; then
  mkdir -p ~/.config/systemd/user
  cp $OMARCHY_PATH/config/systemd/user/$SERVICE ~/.config/systemd/user/$SERVICE
fi

systemctl --user daemon-reload
systemctl --user enable $SERVICE

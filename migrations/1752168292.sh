echo "Enable battery low notifications for laptops"

if ls /sys/class/power_supply/BAT* &>/dev/null && [[ ! -f ~/.local/share/omarchy/config/systemd/user/omarchy-battery-monitor.service ]]; then
  # pondhouse-fork: ensure ~/.config/systemd symlinked, copy only on real-dir installs (see install/config/config.sh)
  if [[ ! -e $HOME/.config/systemd && ! -L $HOME/.config/systemd ]]; then
    ln -sfn "$OMARCHY_PATH/config/systemd" "$HOME/.config/systemd"
  elif [[ ! -L $HOME/.config/systemd ]]; then
    mkdir -p ~/.config/systemd/user

    cp ~/.local/share/omarchy/config/systemd/user/omarchy-battery-monitor.* ~/.config/systemd/user/
  fi

  systemctl --user daemon-reload
  systemctl --user enable --now omarchy-battery-monitor.timer || true
fi

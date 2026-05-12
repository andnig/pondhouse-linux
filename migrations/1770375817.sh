echo "Ensure walker service is restarted if it's killed or crashes"

# pondhouse-fork: ensure ~/.config/systemd symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/systemd && ! -L $HOME/.config/systemd ]]; then
  ln -sfn "$OMARCHY_PATH/config/systemd" "$HOME/.config/systemd"
elif [[ ! -L $HOME/.config/systemd ]]; then
  mkdir -p ~/.config/systemd/user/app-walker@autostart.service.d/
  cp $OMARCHY_PATH/default/walker/restart.conf ~/.config/systemd/user/app-walker@autostart.service.d/restart.conf
fi

systemctl --user daemon-reload


echo "Run SwayOSD as a supervised session service"

# pondhouse-fork: ensure ~/.config/systemd symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/systemd && ! -L $HOME/.config/systemd ]]; then
  ln -sfn "$OMARCHY_PATH/config/systemd" "$HOME/.config/systemd"
elif [[ ! -L $HOME/.config/systemd ]]; then
  mkdir -p ~/.config/systemd/user
  cp "$OMARCHY_PATH/config/systemd/user/swayosd-server.service" ~/.config/systemd/user/swayosd-server.service
fi

if [[ -f ~/.config/hypr/autostart.conf ]]; then
  sed -i '/^exec-once = uwsm-app -- swayosd-server$/d' ~/.config/hypr/autostart.conf
fi

pkill -x swayosd-server || true

bash "$OMARCHY_PATH/install/first-run/swayosd.sh"

echo "Switch Elephant to run as a systemd service and walker to be autostarted on login"

pkill elephant
elephant service enable
systemctl --user start elephant.service

pkill walker
mkdir -p ~/.config/autostart/
# pondhouse-fork: ensure ~/.config/autostart symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/autostart && ! -L $HOME/.config/autostart ]]; then
  ln -sfn "$OMARCHY_PATH/config/autostart" "$HOME/.config/autostart"
elif [[ ! -L $HOME/.config/autostart ]]; then
  cp $OMARCHY_PATH/default/walker/walker.desktop ~/.config/autostart/
fi
setsid walker --gapplication-service &

echo "Copy Fcitx5 autostart desktop file to ~/.config/autostart"

# pondhouse-fork: ensure ~/.config/autostart symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/autostart && ! -L $HOME/.config/autostart ]]; then
  ln -sfn "$OMARCHY_PATH/config/autostart" "$HOME/.config/autostart"
elif [[ ! -L $HOME/.config/autostart ]]; then
  mkdir -p ~/.config/autostart/
  cp "$OMARCHY_PATH/config/autostart/org.fcitx.Fcitx5.desktop" ~/.config/autostart/
fi

omarchy-restart-xcompose

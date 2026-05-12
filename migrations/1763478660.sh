echo "Configure XDPH config for screensharing to remember token selection"

# pondhouse-fork: ensure ~/.config/hypr symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/hypr && ! -L $HOME/.config/hypr ]]; then
  ln -sfn "$OMARCHY_PATH/config/hypr" "$HOME/.config/hypr"
elif [[ ! -L $HOME/.config/hypr ]]; then
  cp $OMARCHY_PATH/config/hypr/xdph.conf ~/.config/hypr/
fi
systemctl --user restart xdg-desktop-portal-hyprland

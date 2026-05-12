echo "Add custom share portal picker"
omarchy-pkg-add hyprland-preview-share-picker

mkdir -p ~/.config/hyprland-preview-share-picker
# pondhouse-fork: ensure ~/.config/hyprland-preview-share-picker symlinked before refresh-config
if [[ ! -e $HOME/.config/hyprland-preview-share-picker ]]; then
  ln -sfn "$OMARCHY_PATH/config/hyprland-preview-share-picker" "$HOME/.config/hyprland-preview-share-picker"
fi

if ! grep -q "custom_picker_binary" ~/.config/hypr/xdph.conf; then
  sed -i '/screencopy {/a\    custom_picker_binary = hyprland-preview-share-picker' ~/.config/hypr/xdph.conf
fi

sleep 1
killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal-wlr
killall xdg-desktop-portal
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &

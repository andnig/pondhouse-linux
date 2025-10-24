echo -e "Offer new Omarchy hotkeys\n"

cat <<EOF
* Add SUPER + C / V for unified clipboard in both terminal and other apps. If you like this kind of thing.
* Add SUPER + CTRL + V for clipboard history manager. Super handy. If for some reasons this stops working, run command 'omarchy-refresh-walker'.
* Move fullscreen from F11 to SUPER + F
* Keep terminal on SUPER + RETURN
* Move toggling tiling/floating to SUPER + T
EOF

sed -i 's|source = ~/.local/share/omarchy/default/hypr/bindings/tiling\.conf|source = ~/.local/share/omarchy/default/hypr/bindings/clipboard.conf\
source = ~/.local/share/omarchy/default/hypr/bindings/tiling-v2.conf|' ~/.config/hypr/hyprland.conf

gum confirm --affirmative "OK" "Have you read and acknowledged the above message?" || true

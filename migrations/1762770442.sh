echo "Slow down Ghostty mouse scrolling to match Alacritty"

# pondhouse-fork: ensure ~/.config/ghostty symlinked, append only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/ghostty && ! -L $HOME/.config/ghostty ]]; then
  ln -sfn "$OMARCHY_PATH/config/ghostty" "$HOME/.config/ghostty"
elif [[ ! -L $HOME/.config/ghostty ]]; then
  if ! grep -q "mouse-scroll-multiplier" ~/.config/ghostty/config; then
    echo -e "\n# Slowdown mouse scrolling\nmouse-scroll-multiplier = 0.95" >> ~/.config/ghostty/config
  fi
fi

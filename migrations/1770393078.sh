echo "Add async-backend = epoll to ghostty config to fix high IO pressure"

# pondhouse-fork: ensure ~/.config/ghostty symlinked, write only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/ghostty && ! -L $HOME/.config/ghostty ]]; then
  ln -sfn "$OMARCHY_PATH/config/ghostty" "$HOME/.config/ghostty"
elif [[ ! -L $HOME/.config/ghostty ]]; then
  if [[ -f ~/.config/ghostty/config ]] && ! grep -q "^async-backend" ~/.config/ghostty/config; then
    echo "" >> ~/.config/ghostty/config
    echo "# Fix general slowness on hyprland (https://github.com/ghostty-org/ghostty/discussions/3224)" >> ~/.config/ghostty/config
    echo "async-backend = epoll" >> ~/.config/ghostty/config
  fi
fi

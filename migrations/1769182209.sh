echo "Enable auto-pasting for the emoji picker"

# pondhouse-fork: ensure ~/.config/elephant symlinked before refresh-config
if [[ ! -e $HOME/.config/elephant ]]; then
  ln -sfn "$OMARCHY_PATH/config/elephant" "$HOME/.config/elephant"
fi
omarchy-restart-walker

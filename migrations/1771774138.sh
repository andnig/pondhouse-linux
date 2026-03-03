dirname="opencode"
if [ ! -d "$HOME/.config/$dirname" ]; then
  ln -sfn "$HOME/.local/share/omarchy/config/$dirname" "$HOME/.config/$dirname"
fi

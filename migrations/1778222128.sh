echo "Add sample post-boot hook"

# pondhouse-fork: ensure ~/.config/omarchy symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/omarchy && ! -L $HOME/.config/omarchy ]]; then
  ln -sfn "$OMARCHY_PATH/config/omarchy" "$HOME/.config/omarchy"
elif [[ ! -L $HOME/.config/omarchy ]]; then
  mkdir -p ~/.config/omarchy/hooks/post-boot.d

  if [[ ! -f ~/.config/omarchy/hooks/post-boot.d/weather.sample ]]; then
    cp "$OMARCHY_PATH/config/omarchy/hooks/post-boot.d/weather.sample" ~/.config/omarchy/hooks/post-boot.d/weather.sample
  fi
fi

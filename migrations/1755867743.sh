echo "Copy Omarchy logo to ~/.config/omarchy/branding/screensaver.txt so screensaver can be personalized"

# pondhouse-fork: ensure ~/.config/omarchy symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/omarchy && ! -L $HOME/.config/omarchy ]]; then
  ln -sfn "$OMARCHY_PATH/config/omarchy" "$HOME/.config/omarchy"
elif [[ ! -L $HOME/.config/omarchy ]]; then
  mkdir -p ~/.config/omarchy/branding
  cp $OMARCHY_PATH/logo.txt ~/.config/omarchy/branding/screensaver.txt
fi

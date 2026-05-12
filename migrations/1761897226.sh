echo "Install Copy URL extension for Brave"

# pondhouse-fork: ensure ~/.config/brave-flags.conf symlinked before refresh-config
if [[ ! -e $HOME/.config/brave-flags.conf ]]; then
  ln -sfn "$OMARCHY_PATH/config/brave-flags.conf" "$HOME/.config/brave-flags.conf"
fi

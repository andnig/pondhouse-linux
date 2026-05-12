echo "Add .config/brave-flags.conf by default to ensure Brave runs under Wayland"

# pondhouse-fork: ensure ~/.config/brave-flags.conf symlinked (see install/config/config.sh)
if [[ ! -e $HOME/.config/brave-flags.conf ]]; then
  ln -sfn "$OMARCHY_PATH/config/brave-flags.conf" "$HOME/.config/brave-flags.conf"
fi

echo "Install zen-cal and link its config"

bash "$OMARCHY_PATH/install/custom/zen-cal.sh"

if [[ ! -e $HOME/.config/zen-cal && ! -L $HOME/.config/zen-cal ]]; then
  mkdir -p "$HOME/.config"
  ln -sfn "$OMARCHY_PATH/config/zen-cal" "$HOME/.config/zen-cal"
fi

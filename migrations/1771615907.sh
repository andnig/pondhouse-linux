echo "Add emoji font fallback to fontconfig"
# pondhouse-fork: ensure ~/.config/fontconfig symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/fontconfig && ! -L $HOME/.config/fontconfig ]]; then
  ln -sfn "$OMARCHY_PATH/config/fontconfig" "$HOME/.config/fontconfig"
elif [[ ! -L $HOME/.config/fontconfig ]]; then
  cp $OMARCHY_PATH/config/fontconfig/fonts.conf ~/.config/fontconfig/fonts.conf
fi
fc-cache -f

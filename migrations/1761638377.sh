echo "Turn off fcitx5 clipboard that is interferring with other applications"

# pondhouse-fork: ensure ~/.config/fcitx5 symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/fcitx5 && ! -L $HOME/.config/fcitx5 ]]; then
  ln -sfn "$OMARCHY_PATH/config/fcitx5" "$HOME/.config/fcitx5"
elif [[ ! -L $HOME/.config/fcitx5 ]]; then
  mkdir -p ~/.config/fcitx5/conf
  cp $OMARCHY_PATH/config/fcitx5/conf/clipboard.conf ~/.config/fcitx5/conf/
fi

omarchy-restart-xcompose

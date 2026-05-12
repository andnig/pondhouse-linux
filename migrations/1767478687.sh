echo "Add opencode with system theming"

omarchy-pkg-add opencode

# Add config using omarchy theme by default
# pondhouse-fork: ensure ~/.config/opencode symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/opencode && ! -L $HOME/.config/opencode ]]; then
  ln -sfn "$OMARCHY_PATH/config/opencode" "$HOME/.config/opencode"
elif [[ ! -L $HOME/.config/opencode ]]; then
  if [[ ! -f ~/.config/opencode/opencode.json ]]; then
    mkdir -p ~/.config/opencode
    cp $OMARCHY_PATH/config/opencode/opencode.json ~/.config/opencode/opencode.json
  fi
fi

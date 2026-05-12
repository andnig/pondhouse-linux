echo "Migrate to Walker 2.0.0"

NEEDS_MIGRATION=false

PACKAGES=(
  "elephant"
  "elephant-calc"
  "elephant-clipboard"
  "elephant-bluetooth"
  "elephant-desktopapplications"
  "elephant-files"
  "elephant-menus"
  "elephant-providerlist"
  "elephant-runner"
  "elephant-symbols"
  "elephant-unicode"
  "elephant-websearch"
  "elephant-todo"
  "walker"
  "libqalculate"
)

for pkg in "${PACKAGES[@]}"; do
  if ! omarchy-pkg-present "$pkg"; then
    NEEDS_MIGRATION=true
    break
  fi
done

WALKER_MAJOR=$(walker -v 2>&1 | grep -oP '^\d+' || echo "0")
if (( WALKER_MAJOR < 2 )); then
  NEEDS_MIGRATION=true
fi

# Ensure basic config is present
# pondhouse-fork: ensure ~/.config/walker symlinked, copy only on real-dir installs (see install/config/config.sh)
if [[ ! -e $HOME/.config/walker && ! -L $HOME/.config/walker ]]; then
  ln -sfn "$OMARCHY_PATH/config/walker" "$HOME/.config/walker"
elif [[ ! -L $HOME/.config/walker ]]; then
  mkdir -p ~/.config/walker
  cp -r ~/.local/share/omarchy/config/walker/* ~/.config/walker/
fi

if $NEEDS_MIGRATION; then
  kill -9 $(pgrep -x walker) 2>/dev/null || true

  omarchy-pkg-drop walker-bin walker-bin-debug

  omarchy-pkg-add "${PACKAGES[@]}"

  source $OMARCHY_PATH/install/config/walker-elephant.sh

  rm -rf ~/.config/walker/themes

  omarchy-refresh-config walker/config.toml
  # pondhouse-fork: ensure ~/.config/elephant symlinked before refresh-config
  if [[ ! -e $HOME/.config/elephant ]]; then
    ln -sfn "$OMARCHY_PATH/config/elephant" "$HOME/.config/elephant"
  fi
fi

echo # Assure final success

echo "Symlink opencode config to omarchy default"

dirname="opencode"
target="$HOME/.config/$dirname"
source="$HOME/.local/share/omarchy/config/$dirname"

if [[ -d $target && ! -L $target ]]; then
  if gum confirm "Found existing ~/.config/$dirname folder. Remove it and symlink to omarchy default?"; then
    rm -rf "$target"
    ln -sfn "$source" "$target"
  fi
elif [[ ! -e $target ]]; then
  ln -sfn "$source" "$target"
fi

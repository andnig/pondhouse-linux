echo "Installing Herdr..."

bin_dir="$HOME/.local/bin"
bin_dest="$bin_dir/herdr"
offline_dir="/opt/packages"
offline_binary="$offline_dir/herdr-linux-x86_64"
offline_checksum="$offline_binary.sha256"
offline_license="$offline_dir/herdr-LICENSE"

if omarchy-cmd-present herdr || [[ -x $bin_dest ]]; then
  echo "Herdr is already installed, skipping"
elif [[ -x $offline_binary && -f $offline_checksum ]]; then
  if (cd "$offline_dir" && sha256sum -c "$(basename "$offline_checksum")"); then
    mkdir -p "$bin_dir"
    install -m 755 "$offline_binary" "$bin_dest"
    if [[ -f $offline_license ]]; then
      install -Dm644 "$offline_license" "$HOME/.local/share/licenses/herdr/LICENSE"
    fi
    echo "Installed Herdr from offline ISO"
  else
    echo "Herdr offline binary checksum verification failed" >&2
    false
  fi
else
  installer=$(mktemp)

  if curl -fsSL https://herdr.dev/install.sh -o "$installer" && bash "$installer"; then
    rm -f "$installer"
  else
    rm -f "$installer"
    echo "Herdr installation failed" >&2
    false
  fi
fi

#!/bin/bash

set -euo pipefail

bin_dir="$HOME/.local/bin"
bin_dest="$bin_dir/zen-cal"
download_url="https://github.com/beaterblank/zen-cal/releases/latest/download/zen-cal"

cmd_present() {
  if command -v omarchy-cmd-present >/dev/null 2>&1; then
    omarchy-cmd-present "$1"
  else
    command -v "$1" >/dev/null 2>&1
  fi
}

if [[ -x $bin_dest ]]; then
  echo "zen-cal already installed at $bin_dest"
  exit 0
fi

mkdir -p "$bin_dir"
tmp_file=$(mktemp)

cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT

echo "Installing zen-cal to $bin_dest..."

if cmd_present curl; then
  curl -fL -o "$tmp_file" "$download_url"
elif cmd_present wget; then
  wget -O "$tmp_file" "$download_url"
else
  echo "Error: curl or wget is required to install zen-cal" >&2
  exit 1
fi

chmod +x "$tmp_file"
mv "$tmp_file" "$bin_dest"
trap - EXIT

echo "Installed zen-cal at $bin_dest"

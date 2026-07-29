echo "Installing herdr-reviewr..."

if omarchy-cmd-present herdr; then
  herdr_bin=$(command -v herdr)
elif [[ -x $HOME/.local/bin/herdr ]]; then
  herdr_bin="$HOME/.local/bin/herdr"
else
  echo "Herdr must be installed before herdr-reviewr" >&2
  false
fi

offline_plugin="/opt/packages/herdr-reviewr"
plugin_dir="$HOME/.local/share/herdr/plugins/persiyanov.reviewr"

if "$herdr_bin" plugin list --plugin persiyanov.reviewr --json 2>/dev/null | jq -e '.result.plugins | length > 0' >/dev/null; then
  echo "herdr-reviewr is already installed, skipping"
elif [[ -f $plugin_dir/herdr-plugin.toml && -x $plugin_dir/bin/herdr-reviewr ]]; then
  "$herdr_bin" plugin link "$plugin_dir"
  echo "Registered existing herdr-reviewr installation"
elif [[ -e $plugin_dir ]]; then
  echo "Cannot install herdr-reviewr because $plugin_dir already exists" >&2
  false
elif [[ -f $offline_plugin/herdr-plugin.toml && -x $offline_plugin/bin/herdr-reviewr ]]; then
  mkdir -p "$(dirname "$plugin_dir")"
  cp -R "$offline_plugin" "$plugin_dir"
  "$herdr_bin" plugin link "$plugin_dir"
  echo "Installed herdr-reviewr from offline ISO"
else
  "$herdr_bin" plugin install persiyanov/herdr-reviewr --yes
fi

echo "Install Herdr and herdr-reviewr, then link Herdr config"

omarchy-pkg-aur-add herdr-bin

if [[ -e $HOME/.config/herdr || -L $HOME/.config/herdr ]]; then
  echo "Herdr config already exists, skipping"
else
  omarchy-refresh-config herdr/config.toml
fi

bash "$OMARCHY_PATH/install/custom/herdr-reviewr.sh"

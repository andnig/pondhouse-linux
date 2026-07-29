echo "Install Herdr and herdr-reviewr, then link Herdr config"

bash "$OMARCHY_PATH/install/custom/herdr.sh"
bash "$OMARCHY_PATH/install/custom/herdr-reviewr.sh"

if [[ -e $HOME/.config/herdr || -L $HOME/.config/herdr ]]; then
  echo "Herdr config already exists, skipping"
else
  omarchy-refresh-config herdr/config.toml
fi

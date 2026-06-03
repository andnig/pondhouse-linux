echo "Enable Sunshine user service after upstream unit rename"

if omarchy-pkg-present sunshine; then
  stale_links=(
    "$HOME/.config/systemd/user/xdg-desktop-autostart.target.wants/sunshine.service"
    "$HOME/.config/systemd/user/graphical-session.target.wants/sunshine.service"
  )

  for stale_link in "${stale_links[@]}"; do
    if [[ -L $stale_link && ! -e $stale_link ]]; then
      stale_target=$(readlink "$stale_link")
      if [[ $stale_target == "/usr/lib/systemd/user/sunshine.service" ]]; then
        rm -f "$stale_link"
      fi
    fi
  done

  systemctl --user daemon-reload
  if [[ -f /usr/lib/systemd/user/app-dev.lizardbyte.app.Sunshine.service ]]; then
    systemctl --user enable --now app-dev.lizardbyte.app.Sunshine.service || true
  elif [[ -f /usr/lib/systemd/user/sunshine.service ]]; then
    systemctl --user enable --now sunshine.service || true
  fi
fi

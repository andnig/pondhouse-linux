#!/bin/bash
xdg-settings set default-web-browser zen-browser.desktop || true
xdg-mime default zen-browser.desktop x-scheme-handler/http || true
xdg-mime default zen-browser.desktop x-scheme-handler/https || true

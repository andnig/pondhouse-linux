#!/bin/bash

echo "Adding zen-bin to 1Password allowed browsers"

if [ ! -d /etc/1password ]; then
  sudo mkdir /etc/1password
  sudo touch /etc/1password/custom_allowed_browsers
  echo "zen-bin" | sudo tee -a /etc/1password/custom_allowed_browsers
else
  echo "1Password directory already exists, skipping creation"
fi

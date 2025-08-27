#!/bin/bash

sudo pacman -S --noconfirm --needed \
  base-devel \
  ca-certificates \
  cmake \
  containerd \
  devtools \
  doxx \
  fontconfig \
  gcc \
  gettext \
  gnupg \
  grim \
  hplip \
  httpie \
  kitty \
  krew \
  kubectl \
  libappindicator-gtk3 \
  lua \
  luajit \
  meson \
  npm \
  pandoc \
  python \
  python-pip \
  python-pynvim \
  python-ruff \
  python-setuptools \
  seahorse \
  stow \
  swappy \
  syncthing \
  tailscale \
  thunderbird \
  tmux \
  uv \
  wget \
  yazi \
  yq \
  7zip

echo "Installing tpm (tmux plugin manager)"
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

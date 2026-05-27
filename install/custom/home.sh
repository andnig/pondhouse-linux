#!/bin/bash

stow -d ~/.local/share/omarchy/config -t $HOME ssh
stow -d ~/.local/share/omarchy/config -t $HOME scripts
stow -d ~/.local/share/omarchy/config -t $HOME agents

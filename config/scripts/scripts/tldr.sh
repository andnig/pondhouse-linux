#!/usr/bin/env bash

read -p "Enter tldr: " query

tmux neww bash -c "tldr $query & while [ : ]; do sleep 1; done"

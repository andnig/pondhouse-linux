#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
	selected=$1
else
	selected=$(find ~/github ~/ ~/.dotfiles -mindepth 1 -maxdepth 3 -type d 2>/dev/null | fzf)
fi

if [[ -z $selected ]]; then
	exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

# If tmux is not running at all, start tmux and create a new session
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
	tmux new-session -s default -c $selected -d # -d detaches the session
	tmux rename-window -t default $selected_name
	tmux attach-session -t default
	exit 0
fi

# If inside a tmux session or tmux is running, we proceed to manage windows
session_target=${TMUX%%,*} # Extract current session name if inside tmux

# Check if a window with the desired name already exists in the current session
if ! tmux list-windows -F '#W' | grep -q "^$selected_name$"; then
	tmux new-window -n $selected_name -c $selected
else
	# If window exists, select it
	tmux select-window -t $selected_name
fi

# Optionally, focus tmux to the newly created or selected window
tmux select-window -t $selected_name

#!/bin/bash

# Function to create a new tmux session based on selected directory
create_tmux_session() {
  # Capture the output from the find command piped to fzf
  selected_dir=$(find ~/github ~/ ~/.dotfiles -mindepth 1 -maxdepth 3 -type d 2>/dev/null | fzf)

  # Check if the selection is non-empty
  if [[ -n "$selected_dir" ]]; then
    # Extract the basename of the selected directory
    session_name=$(basename "$selected_dir")

    # Create a new tmux session with the selected directory basename as the session name
    # and cd into the selected directory
    tmux new-session -d -s "$session_name" -n "$session_name" "cd \"$selected_dir\"; exec zsh"

    # Attach to the newly created session
    tmux switch-client -t "$session_name"
  else
    echo "No directory selected."
  fi
}

create_tmux_session

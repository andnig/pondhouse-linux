#!/bin/bash

if (( $# == 1 )); then
  selected=$1
else
  selected=$(find ~/github ~/ ~/.dotfiles -mindepth 1 -maxdepth 3 -type d 2>/dev/null | fzf)
fi

[[ -z $selected ]] && exit 0

selected=$(realpath "$selected")
selected_name=$(basename "$selected" | tr '.:' '__')

if ! herdr status server &>/dev/null; then
  builtin cd "$selected" || exit 1
  exec herdr
fi

workspace_id=$(herdr workspace list | jq -r --arg label "$selected_name" \
  '.result.workspaces[] | select(.label == $label) | .workspace_id' | while IFS= read -r id; do
    printf '%s\n' "$id"
    break
  done)

if [[ -n $workspace_id ]]; then
  herdr workspace focus "$workspace_id" >/dev/null
else
  herdr workspace create --cwd "$selected" --label "$selected_name" --focus >/dev/null
fi

[[ -z $HERDR_SOCKET_PATH ]] && exec herdr

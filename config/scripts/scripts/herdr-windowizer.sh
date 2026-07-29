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

workspace_id=${HERDR_ACTIVE_WORKSPACE_ID:-${HERDR_WORKSPACE_ID:-}}
if [[ -z $workspace_id ]]; then
  workspace_id=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused) | .workspace_id')
fi

if [[ -z $workspace_id ]]; then
  herdr workspace create --cwd "$selected" --label "$selected_name" --focus >/dev/null
else
  tab_id=$(herdr tab list --workspace "$workspace_id" | jq -r --arg label "$selected_name" \
    '.result.tabs[] | select(.label == $label) | .tab_id' | while IFS= read -r id; do
      printf '%s\n' "$id"
      break
    done)

  if [[ -n $tab_id ]]; then
    herdr tab focus "$tab_id" >/dev/null
  else
    herdr tab create --workspace "$workspace_id" --cwd "$selected" --label "$selected_name" --focus >/dev/null
  fi
fi

[[ -z $HERDR_SOCKET_PATH ]] && exec herdr

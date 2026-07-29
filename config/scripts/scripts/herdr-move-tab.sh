#!/bin/bash

direction=$1
tab_id=${HERDR_ACTIVE_TAB_ID:-${HERDR_TAB_ID:-}}
socket_path=${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}

[[ -z $tab_id || ! -S $socket_path ]] && exit 1
[[ $direction == "left" || $direction == "right" ]] || exit 2

tab_json=$(herdr tab get "$tab_id") || exit 1
workspace_id=$(jq -r '.result.tab.workspace_id' <<< "$tab_json")
tabs_json=$(herdr tab list --workspace "$workspace_id") || exit 1
tab_index=$(jq --arg tab_id "$tab_id" '.result.tabs | map(.tab_id) | index($tab_id)' <<< "$tabs_json")
tab_count=$(jq '.result.tabs | length' <<< "$tabs_json")

[[ $tab_index != "null" ]] || exit 1

if [[ $direction == "left" ]]; then
  (( tab_index == 0 )) && exit 0
  insert_index=$((tab_index - 1))
else
  (( tab_index + 1 >= tab_count )) && exit 0
  insert_index=$((tab_index + 2))
fi

request=$(jq -cn \
  --arg tab_id "$tab_id" \
  --argjson insert_index "$insert_index" \
  '{id:"user:move-tab",method:"tab.move",params:{tab_id:$tab_id,insert_index:$insert_index}}')
response=$(printf '%s\n' "$request" | socat - "UNIX-CONNECT:$socket_path") || exit 1
jq -e 'has("result")' >/dev/null <<< "$response"

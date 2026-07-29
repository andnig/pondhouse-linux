#!/bin/bash

hyprctl dispatch workspace 1 >/dev/null

agents_json=$(herdr agent list 2>/dev/null) || exit 0
pane_id=$(jq -r '
  .result.agents as $agents |
  (
    [$agents[] | select(.agent_status == "blocked")] +
    [$agents[] | select(.agent_status == "done" or .agent_status == "idle")]
  )[0].pane_id // empty
' <<< "$agents_json")

[[ -n $pane_id ]] && herdr agent focus "$pane_id" >/dev/null

#!/bin/bash

frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
frame_index=0
refresh_tick=0
online=false
total=0
working=0
blocked=0
done=0
idle=0
unknown=0
tooltip="Herdr is not running"

json_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

while true; do
  if (( refresh_tick == 0 )); then
    if agents_json=$(herdr agent list 2>/dev/null) && jq -e '.result.agents' >/dev/null <<< "$agents_json"; then
      online=true
      total=$(jq '.result.agents | length' <<< "$agents_json")
      working=$(jq '[.result.agents[] | select(.agent_status == "working")] | length' <<< "$agents_json")
      blocked=$(jq '[.result.agents[] | select(.agent_status == "blocked")] | length' <<< "$agents_json")
      done=$(jq '[.result.agents[] | select(.agent_status == "done")] | length' <<< "$agents_json")
      idle=$(jq '[.result.agents[] | select(.agent_status == "idle")] | length' <<< "$agents_json")
      unknown=$((total - working - blocked - done - idle))
      details=$(jq -r '
        ["blocked", "working", "done", "idle", "unknown"][] as $status |
        [.result.agents[] | select(.agent_status == $status)] as $agents |
        select($agents | length > 0) |
        "\($status | ascii_upcase) \($agents | length)\n" +
        ($agents | map("  \(.agent) · \((.cwd // "") | split("/") | last)") | join("\n"))
      ' <<< "$agents_json")
      tooltip=$(printf 'Herdr · %d agents' "$total")
      [[ -n $details ]] && tooltip+=$(printf '\n\n%s' "$details")
    else
      online=false
      tooltip="Herdr is not running"
    fi
  fi

  if [[ $online != true ]]; then
    text="󰚩"
    class="offline"
  else
    text=""
    (( blocked > 0 )) && text="󰀪 $blocked"
    (( working > 0 )) && text+="${text:+  }${frames[$frame_index]} $working"
    (( done > 0 )) && text+="${text:+  }󰄬 $done"
    (( idle > 0 )) && text+="${text:+  }󰚩 $idle"
    (( unknown > 0 )) && text+="${text:+  }󰋗 $unknown"
    [[ -z $text ]] && text="󰚩 0"

    if (( blocked > 0 )); then
      class="blocked"
    elif (( working > 0 )); then
      class="working"
    elif (( done > 0 )); then
      class="done"
    else
      class="idle"
    fi
  fi

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" "$(json_escape "$tooltip")" "$class"

  (( frame_index = (frame_index + 1) % ${#frames[@]} ))
  (( refresh_tick = (refresh_tick + 1) % 8 ))
  sleep 0.15
done

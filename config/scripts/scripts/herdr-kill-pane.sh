#!/bin/bash

pane_id=${HERDR_ACTIVE_PANE_ID:-${HERDR_PANE_ID:-}}
[[ -z $pane_id ]] && exit 1

read -r -p "Kill this pane? (y/N) " answer
if [[ $answer == "y" || $answer == "Y" ]]; then
  "${HERDR_BIN_PATH:-herdr}" pane close "$pane_id" >/dev/null
fi

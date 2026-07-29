#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
selected=$(cat "$script_dir/tmux-cht-languages" "$script_dir/tmux-cht-commands" | fzf)
[[ -z $selected ]] && exit 0

read -r -p "Enter Query: " query

if grep -Fqx "$selected" "$script_dir/tmux-cht-languages"; then
  query=${query// /+}
  printf 'curl cht.sh/%s/%s/\n\n' "$selected" "$query"
  curl "cht.sh/$selected/$query"
else
  curl -s "cht.sh/$selected~$query" | less
fi

printf '\nPress Enter to close...'
read -r

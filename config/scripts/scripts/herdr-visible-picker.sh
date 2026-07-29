#!/bin/bash

pane_id=${HERDR_ACTIVE_PANE_ID:-${HERDR_PANE_ID:-}}
pane_cwd=${HERDR_ACTIVE_PANE_CWD:-$PWD}
[[ -z $pane_id ]] && exit 1

visible=$(herdr pane read "$pane_id" --source visible 2>/dev/null) || exit 1
pattern="https?://[^[:space:]<>\"'\\]\\[(){}]+|(?:~|\\.{1,2})?/(?:[[:alnum:]_.@+%-]+/)*[[:alnum:]_.@+%-]+(?::[0-9]+(?::[0-9]+)?)?|(?:[[:alnum:]_.@+-]+/)+[[:alnum:]_.@+%-]+(?::[0-9]+(?::[0-9]+)?)?|[[:alnum:]_.@+-]+\\.[[:alnum:]]{1,10}(?::[0-9]+(?::[0-9]+)?)?|\\.[[:alnum:]_.-]+"
quoted_pattern="([\"'\\x60])([^\"'\\x60\\r\\n]+)\\1"
trailing_punctuation='[.,:;!?]$'

declare -A seen
items=()

add_candidate() {
  local candidate=$1
  local path line resolved key

  while [[ $candidate =~ $trailing_punctuation ]]; do
    candidate=${candidate%?}
  done
  [[ -z $candidate ]] && return

  if [[ $candidate == http://* || $candidate == https://* ]]; then
    key="url:$candidate"
    if [[ -z ${seen[$key]} ]]; then
      seen[$key]=1
      items+=("url"$'\t'"$candidate"$'\t'"$candidate"$'\t')
    fi
    return
  fi

  path=$candidate
  line=""
  if [[ $path =~ ^(.+):([0-9]+)(:[0-9]+)?$ ]]; then
    path=${BASH_REMATCH[1]}
    line=${BASH_REMATCH[2]}
  fi

  path=${path/#\~/$HOME}
  if [[ $path == /* ]]; then
    resolved=$path
  else
    resolved="$pane_cwd/$path"
  fi
  resolved=$(realpath "$resolved" 2>/dev/null) || return
  [[ -e $resolved ]] || return

  key="file:$resolved:$line"
  if [[ -z ${seen[$key]} ]]; then
    seen[$key]=1
    items+=("file"$'\t'"$candidate"$'\t'"$resolved"$'\t'"$line")
  fi
}

while IFS= read -r candidate; do
  add_candidate "$candidate"
done < <(printf '%s\n' "$visible" | rg --only-matching --no-filename --pcre2 "$pattern")

while IFS= read -r candidate; do
  add_candidate "$candidate"
done < <(printf '%s\n' "$visible" | rg --only-matching --no-filename --pcre2 --replace '$2' "$quoted_pattern")

if (( ${#items[@]} == 0 )); then
  printf 'No visible files or links found.\n'
  sleep 1.5
  exit 0
fi

selected=$(printf '%s\n' "${items[@]}" | fzf \
  --delimiter=$'\t' \
  --with-nth=2 \
  --prompt='open visible › ' \
  --header='code opens in nvim · everything else uses the default application')
[[ -z $selected ]] && exit 0

IFS=$'\t' read -r kind display value line <<< "$selected"
if [[ $kind == "url" || -d $value ]]; then
  setsid -f xdg-open "$value" >/dev/null 2>&1
  exit 0
fi

mime_type=$(xdg-mime query filetype "$value" 2>/dev/null)
case $mime_type in
  text/* | application/json | application/*+json | application/javascript | application/x-javascript | application/xml | application/*+xml | application/x-shellscript | application/x-perl | application/x-python | application/x-ruby | application/toml | application/x-yaml | inode/x-empty)
    if [[ -n $line ]]; then
      setsid -f xdg-terminal-exec -e nvim "+$line" "$value" >/dev/null 2>&1
    else
      setsid -f xdg-terminal-exec -e nvim "$value" >/dev/null 2>&1
    fi
    ;;
  *)
    setsid -f xdg-open "$value" >/dev/null 2>&1
    ;;
esac

#!/bin/bash
input=$(cat)

if [[ -n "$SSH_CONNECTION" && -z "$WAYLAND_DISPLAY" ]]; then
    printf '\033]52;c;%s\a' "$(echo -n "$input" | base64)" > /dev/tty
else
    echo -n "$input" | /usr/bin/wl-copy
fi

#!/bin/bash
if [[ -n "$SSH_CONNECTION" && -z "$WAYLAND_DISPLAY" ]]; then
    tmux save-buffer - 2>/dev/null
else
    /usr/bin/wl-paste
fi

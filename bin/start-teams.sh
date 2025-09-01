#!/bin/bash

# Switch to workspace 7
hyprctl dispatch workspace 7

# Launch all Teams instances with delays
uwsm app -- chromium --user-data-dir='/home/andreas/.config/chromium' --profile-directory="Profile 1" --ozone-platform=wayland --app='https://teams.microsoft.com' &
PID1=$!
sleep 0.5
uwsm app -- chromium --user-data-dir='/home/andreas/.config/chromium' --profile-directory="Profile 2" --ozone-platform=wayland --app='https://teams.microsoft.com' &
PID2=$!
sleep 0.5
uwsm app -- chromium --user-data-dir='/home/andreas/.config/chromium' --profile-directory="Profile 3" --ozone-platform=wayland --app='https://teams.microsoft.com' &
PID3=$!
sleep 0.5
uwsm app -- chromium --user-data-dir='/home/andreas/.config/chromium' --profile-directory="Profile 4" --ozone-platform=wayland --app='https://teams.microsoft.com'
PID4=$!

# Wait for all windows to fully load
sleep 0.5

hyprctl dispatch focuswindow pid:$PID3
sleep 0.1
hyprctl dispatch movewindow l
hyprctl dispatch movewindow l

hyprctl dispatch workspace previous

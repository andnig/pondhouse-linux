#!/bin/bash

# Define an array of hosts
HOSTS=("mt.db1" "mt.compute1" "engie.db1" "emco.db1" "emco.compute1")

# Create the command string with proper escaping
REMOTE_COMMANDS='
echo "=== System Status Report ==="
echo ""
echo "Drives more than 80% full and at least 275 MB in size:"
df_output=$(df -BM | awk "NR>1 && int(\$2) >= 275 && int(\$5) > 80 {print \$0}")
echo "$df_output"
echo ""
echo "Docker services below target replicas:"
docker_output=$(docker service ls --format "{{.ID}}\t{{.Name}}\t{{.Mode}}\t{{.Replicas}}" | awk -F"\t" "{split(\$4, a, \"/\"); if (a[1] < a[2]) print \$0}")
echo "$docker_output"
echo ""
echo "=== End of Report ==="
echo "Press Enter to close..."
read
'

# Check if we're already inside a tmux session
if [ -z "$TMUX" ]; then
  # If not in tmux, start a new session
  tmux new-session -d

  # Create a window for each host
  for host in "${HOSTS[@]}"; do
    tmux new-window -n "${host}" "SSH_AUTH_SOCK=$SSH_AUTH_SOCK ssh -t ${host} '${REMOTE_COMMANDS}'"
  done

  tmux kill-window -t 0
  tmux attach-session
else
  # If already in tmux, create a window for each host
  for host in "${HOSTS[@]}"; do
    tmux new-window -n "${host}" "SSH_AUTH_SOCK=$SSH_AUTH_SOCK ssh -t ${host} '${REMOTE_COMMANDS}'"
  done
fi

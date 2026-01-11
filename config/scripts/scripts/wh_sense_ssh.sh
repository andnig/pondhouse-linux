#!/bin/bash

# Define an array of hosts
HOSTS=("wh.mt.db1" "wh.mt.compute1" "wh.engie.db1" "wh.emco.db1" "wh.emco.compute1")

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
echo "pgbackrest backups older than 2 days:"
tsnode_container=$(docker ps --format "{{.Names}}" | grep tsnode | head -1)
if [ -n "$tsnode_container" ]; then
  last_backup_time=$(docker exec "$tsnode_container" pgbackrest info 2>/dev/null | grep "timestamp start/stop" | tail -1 | sed "s/.*timestamp start\/stop: \([0-9-]* [0-9:]*\).*/\1/")
  if [ -n "$last_backup_time" ]; then
    last_backup_epoch=$(date -d "$last_backup_time" +%s 2>/dev/null)
    two_days_ago_epoch=$(date -d "2 days ago" +%s)
    if [ -n "$last_backup_epoch" ] && [ "$last_backup_epoch" -lt "$two_days_ago_epoch" ]; then
      echo "WARNING: Last pgbackrest backup is older than 2 days!"
      echo "  Container: $tsnode_container"
      echo "  Last backup: $last_backup_time"
    fi
  else
    echo "WARNING: Could not parse pgbackrest backup timestamp"
  fi
else
  echo "INFO: No tsnode container found"
fi
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

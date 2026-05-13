#!/bin/bash

set -euo pipefail

OMARCHY_CONFIG_DIR="$HOME/.local/share/omarchy/config"
USER_CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$USER_CONFIG_DIR/backup"

dry_run=false
assume_yes=false

CONFIGS=(
  foot
  Typora
  chromium-flags.conf
  imv
  obsidian
  wiremix
  hyprland-preview-share-picker
  ghostty
  xdg-terminals.list
  git
  elephant
)

usage() {
  cat <<'EOF'
Usage: ./repair-omarchy-configs.sh [--dry-run] [--yes]

Repair selected Omarchy ~/.config entries by replacing real files/dirs with
symlinks to ~/.local/share/omarchy/config/<name>.

Backups are moved to:
  ~/.config/backup/<name>.shadowed.<timestamp>

Options:
  --dry-run   Show what would happen, but do not change anything.
  --yes       Do not prompt before making changes.
  -h, --help  Show this help.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run|-n)
      dry_run=true
      shift
      ;;
    --yes|-y)
      assume_yes=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

have_gum() {
  command -v gum >/dev/null 2>&1
}

style() {
  if have_gum; then
    gum style "$@"
  else
    shift $(( $# > 1 ? $# - 1 : 0 ))
    printf '%s\n' "$1"
  fi
}

header() {
  if have_gum; then
    gum style --border rounded --border-foreground 4 --padding "1 3" --bold \
      "Repair Omarchy config symlinks" \
      "Backups: $BACKUP_DIR" \
      "Mode: $($dry_run && echo dry-run || echo repair)"
  else
    echo "Repair Omarchy config symlinks"
    echo "Backups: $BACKUP_DIR"
    echo "Mode: $($dry_run && echo dry-run || echo repair)"
  fi
  echo
}

status_label() {
  local status=$1

  case "$status" in
    ok) echo "already linked" ;;
    link) echo "will symlink" ;;
    backup) echo "backup + symlink" ;;
    skip) echo "skip" ;;
  esac
}

backup_path_for() {
  local name=$1
  local timestamp
  local backup
  local n=1

  timestamp=$(date +%Y%m%d-%H%M%S)
  backup="$BACKUP_DIR/$name.shadowed.$timestamp"

  while [[ -e $backup || -L $backup ]]; do
    backup="$BACKUP_DIR/$name.shadowed.$timestamp.$n"
    n=$((n + 1))
  done

  echo "$backup"
}

planned_status_for() {
  local name=$1
  local src="$OMARCHY_CONFIG_DIR/$name"
  local dst="$USER_CONFIG_DIR/$name"

  if [[ ! -e $src && ! -L $src ]]; then
    echo "skip|source missing"
    return
  fi

  if [[ -L $dst ]]; then
    local target
    target=$(readlink "$dst")
    if [[ $target == "$src" ]]; then
      echo "ok|already points to source"
    else
      echo "backup|existing symlink points elsewhere: $target"
    fi
    return
  fi

  if [[ -e $dst ]]; then
    echo "backup|real entry exists"
  else
    echo "link|missing locally"
  fi
}

print_plan() {
  if have_gum; then
    {
      printf 'Config|Action|Reason\n'
      for name in "${CONFIGS[@]}"; do
        IFS='|' read -r action reason <<<"$(planned_status_for "$name")"
        printf '%s|%s|%s\n' "$name" "$(status_label "$action")" "$reason"
      done
    } | gum table --print --separator '|' --border rounded --border.foreground 8
  else
    printf '%-32s %-18s %s\n' "Config" "Action" "Reason"
    printf '%-32s %-18s %s\n' "------" "------" "------"
    for name in "${CONFIGS[@]}"; do
      IFS='|' read -r action reason <<<"$(planned_status_for "$name")"
      printf '%-32s %-18s %s\n' "$name" "$(status_label "$action")" "$reason"
    done
  fi
  echo
}

confirm_or_exit() {
  if $dry_run || $assume_yes; then
    return
  fi

  if have_gum; then
    if ! gum confirm "Back up selected real ~/.config entries and replace them with symlinks?"; then
      echo "Cancelled."
      exit 1
    fi
  else
    read -r -p "Proceed with repair? [y/N] " answer </dev/tty || answer="n"
    case "$answer" in
      y|Y|yes|YES) ;;
      *) echo "Cancelled."; exit 1 ;;
    esac
  fi
}

repair_one() {
  local name=$1
  local src="$OMARCHY_CONFIG_DIR/$name"
  local dst="$USER_CONFIG_DIR/$name"
  local action reason backup

  IFS='|' read -r action reason <<<"$(planned_status_for "$name")"

  case "$action" in
    ok)
      echo "OK    $name ($reason)"
      return
      ;;
    skip)
      echo "SKIP  $name ($reason)"
      return
      ;;
    link)
      echo "LINK  $name -> $src"
      if ! $dry_run; then
        ln -sfn "$src" "$dst"
      fi
      return
      ;;
    backup)
      backup=$(backup_path_for "$name")
      echo "FIX   $name"
      echo "      backup: $backup"
      echo "      target: $src"
      if ! $dry_run; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$backup"
        ln -sfn "$src" "$dst"
      fi
      return
      ;;
  esac
}

header

if [[ ! -d $OMARCHY_CONFIG_DIR ]]; then
  echo "Missing Omarchy config source: $OMARCHY_CONFIG_DIR" >&2
  exit 1
fi

print_plan
confirm_or_exit

if ! $dry_run; then
  mkdir -p "$BACKUP_DIR"
fi

for name in "${CONFIGS[@]}"; do
  repair_one "$name"
done

echo
if $dry_run; then
  if have_gum; then
    gum style --foreground 3 --bold "Dry run complete. No changes made."
  else
    echo "Dry run complete. No changes made."
  fi
else
  if have_gum; then
    gum style --foreground 2 --bold "Repair complete. Backups are in $BACKUP_DIR"
  else
    echo "Repair complete. Backups are in $BACKUP_DIR"
  fi
fi

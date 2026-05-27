echo "Convert ~/.agents to stow-based symlink (pondhouse-fork)"

AGENTS_DIR="$HOME/.agents"
SOURCE_DIR="$OMARCHY_PATH/config/agents/.agents"
BACKUP_DIR="$HOME/.config/backup"

if [[ ! -d $SOURCE_DIR ]]; then
  echo "skip: $SOURCE_DIR is not present; nothing to stow"
  return 0 2>/dev/null || exit 0
fi

if [[ -L $AGENTS_DIR ]]; then
  target=$(readlink "$AGENTS_DIR")
  if [[ $target == "$SOURCE_DIR" ]]; then
    echo "ok: ~/.agents already symlinked to $SOURCE_DIR"
    return 0 2>/dev/null || exit 0
  fi
  echo "info: ~/.agents is a symlink pointing elsewhere: $target"
fi

remove_agents=true

if [[ -e $AGENTS_DIR || -L $AGENTS_DIR ]]; then
  if command -v gum >/dev/null 2>&1; then
    gum style --border rounded --border-foreground 4 --padding "1 3" --bold \
      "Migrating ~/.agents to symlink" \
      "Current: $AGENTS_DIR" \
      "Target:  $SOURCE_DIR" \
      "Backup:  $BACKUP_DIR/agents.shadowed.<timestamp>"

    if ! gum confirm "Back up the current ~/.agents and replace it with a stow symlink?"; then
      echo "cancelled by user"
      return 0 2>/dev/null || exit 0
    fi
  else
    echo "About to back up $AGENTS_DIR and replace it with a stow symlink to $SOURCE_DIR."
    read -r -p "Proceed? [y/N] " answer </dev/tty || answer="n"
    case "$answer" in
      y|Y|yes|YES) ;;
      *) echo "cancelled by user"; return 0 2>/dev/null || exit 0 ;;
    esac
  fi
fi

if $remove_agents && [[ -e $AGENTS_DIR || -L $AGENTS_DIR ]]; then
  mkdir -p "$BACKUP_DIR"
  backup="$BACKUP_DIR/agents.shadowed.$(date +%Y%m%d-%H%M%S)"
  n=1
  while [[ -e $backup || -L $backup ]]; do
    backup="$BACKUP_DIR/agents.shadowed.$(date +%Y%m%d-%H%M%S).$n"
    n=$((n + 1))
  done
  mv "$AGENTS_DIR" "$backup"
  echo "backed up old ~/.agents to: $backup"
fi

if omarchy-cmd-missing stow; then
  omarchy-pkg-add stow
fi

stow -d "$OMARCHY_PATH/config" -t "$HOME" agents

if [[ -L $AGENTS_DIR ]]; then
  echo "ok: ~/.agents -> $(readlink "$AGENTS_DIR")"
else
  echo "warn: stow ran but ~/.agents is not a symlink" >&2
fi

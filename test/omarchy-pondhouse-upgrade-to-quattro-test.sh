#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
COMMAND="$ROOT/bin/omarchy-pondhouse-upgrade-to-quattro"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  echo "not ok - $1" >&2
  exit 1
}

pass() {
  echo "ok - $1"
}

make_fixture() {
  local name=$1 fixture
  fixture="$TMPDIR/$name"
  mkdir -p "$fixture/home/.local/share/omarchy/config/agents/.agents/skills" \
    "$fixture/home/.local/share/omarchy/config/opencode" \
    "$fixture/home/.local/share/omarchy/config/nested" \
    "$fixture/home/.config" "$fixture/home/.claude" "$fixture/bin" \
    "$fixture/packages" "$fixture/quattro-root"

  printf 'legacy\n' >"$fixture/home/.local/share/omarchy/config/nested/value"
  printf 'ignored\n' >"$fixture/home/.local/share/omarchy/config/opencode/secret.json"
  ln -s "$fixture/home/.local/share/omarchy/config/nested/value" \
    "$fixture/home/.local/share/omarchy/config/agents/.agents/nested-legacy"
  ln -s "$fixture/home/.local/share/omarchy/config/nested" "$fixture/home/.config/nested"
  ln -s "$fixture/home/.local/share/omarchy/config/agents/.agents" "$fixture/home/.agents"
  ln -s "$fixture/home/.local/share/omarchy/config/nested/value" "$fixture/home/.claude/untouched"

  git -C "$fixture/home/.local/share/omarchy" init -q
  printf 'config/opencode/\n' >"$fixture/home/.local/share/omarchy/.gitignore"
  git -C "$fixture/home/.local/share/omarchy" add .gitignore config/nested/value
  git -C "$fixture/home/.local/share/omarchy" \
    -c user.name=Test -c user.email=test@example.com commit -qm initial

  cat >"$fixture/upgrader" <<'EOF'
#!/bin/bash
echo run >>"$HOME/upgrader-runs"
if (( ${MOCK_UPGRADER_FAIL:-0} == 1 )); then
  exit 1
fi
if gum confirm "Reboot to complete Quattro upgrade now?"; then
  touch "$HOME/rebooted"
fi
mkdir -p "$PONDHOUSE_QUATTRO_ROOT"
EOF
  chmod 755 "$fixture/upgrader"

  printf 'keyring package\n' >"$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst"
  printf 'signature\n' >"$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst.sig"
  printf 'pondhouse package\n' >"$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst"
  printf 'signature\n' >"$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst.sig"

  cat >"$fixture/bin/pacman" <<'EOF'
#!/bin/bash
case "${1:-}" in
  -Q)
    case "${2:-}" in
      pondhouse-omarchy) echo "pondhouse-omarchy 2" ;;
      pondhouse-keyring) echo "pondhouse-keyring 1" ;;
      *) echo "git 1" ;;
    esac
    ;;
  -Qqe) echo git ;;
  -Qqm) echo foreign-package ;;
  -Qkk) echo "pondhouse-omarchy: 1 total file, 0 altered files" ;;
  -U) printf 'pacman %s\n' "$*" >>"$HOME/package-actions" ;;
esac
EOF

  cat >"$fixture/bin/cp" <<'EOF'
#!/bin/bash
destination=${@: -1}
/usr/bin/cp "$@"
if (( ${MOCK_CP_FAIL_ON_BACKUP:-0} == 1 )) && [[ $destination == */backups/*.partial ]]; then
  exit 1
fi
EOF

  cat >"$fixture/bin/systemctl" <<'EOF'
#!/bin/bash
echo "mock.service enabled"
EOF

  cat >"$fixture/bin/xdg-settings" <<'EOF'
#!/bin/bash
echo browser.desktop
EOF

  cat >"$fixture/bin/sudo" <<'EOF'
#!/bin/bash
case "${1:-}" in
  pacman) shift; exec pacman "$@" ;;
  pacman-key) exit 0 ;;
  install) exit 0 ;;
  tee) cat >/dev/null ;;
  omarchy-pondhouse-reconcile-system) exec "$1" ;;
  *) exec "$@" ;;
esac
EOF

  for command in omarchy-pondhouse-reconcile-packages omarchy-pondhouse-reconcile-system omarchy-pondhouse-reconcile-user; do
    cat >"$fixture/bin/$command" <<EOF
#!/bin/bash
echo $command >>"\$HOME/reconciliation-actions"
EOF
  done
  chmod 755 "$fixture/bin"/*
  printf '%s\n' "$fixture"
}

run_migration() {
  local fixture=$1
  shift
  HOME="$fixture/home" USER=tester SHELL=/bin/zsh \
    PATH="$fixture/bin:/usr/bin:/bin" \
    PONDHOUSE_LEGACY_ROOT="$fixture/home/.local/share/omarchy" \
    PONDHOUSE_QUATTRO_ROOT="$fixture/quattro-root" \
    PONDHOUSE_MIGRATION_STATE="$fixture/state" \
    PONDHOUSE_MIGRATION_BACKUPS="$fixture/backups" \
    PONDHOUSE_UPGRADER_FILE="$fixture/upgrader" \
    PONDHOUSE_UPGRADER_SHA256="$(sha256sum "$fixture/upgrader" | cut -d' ' -f1)" \
    PONDHOUSE_PACKAGE_VERSION=2 PONDHOUSE_KEYRING_VERSION=1 \
    PONDHOUSE_PACKAGE_SHA256="$(sha256sum "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" | cut -d' ' -f1)" \
    PONDHOUSE_KEYRING_SHA256="$(sha256sum "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" | cut -d' ' -f1)" \
    PONDHOUSE_SNAPSHOT_URL="file://$fixture/packages" \
    "$COMMAND" "$@"
}

fixture=$(make_fixture dry-run)
run_migration "$fixture" --dry-run --yes >/dev/null
run_dir=$(find "$fixture/state" -mindepth 1 -maxdepth 1 -type d -name '*-dry-run' -print -quit)
[[ -s $run_dir/inventory/legacy-status.txt ]] || fail "dry run records git state"; pass "dry run records git state"
grep -Fq 'config/opencode/secret.json' "$run_dir/inventory/legacy-ignored.tsv" || fail "dry run inventories ignored paths"; pass "dry run inventories ignored paths"
grep -Fq "$fixture/home/.agents/nested-legacy" "$run_dir/inventory/materialized-links.tsv" || fail "dry run records nested checkout links"; pass "dry run records nested checkout links"
[[ -L $fixture/home/.config/nested ]] || fail "dry run leaves checkout link intact"; pass "dry run leaves checkout link intact"
[[ ! -e $fixture/backups ]] || fail "dry run makes no backup"; pass "dry run makes no backup"

fixture=$(make_fixture complete)
run_migration "$fixture" --yes >/dev/null
run_dir=$(readlink -f "$fixture/state/latest")
backup_dir=$(<"$run_dir/inventory/backup-path")
[[ -f $backup_dir/config/opencode/secret.json ]] || fail "migration keeps a private data backup"; pass "migration keeps a private data backup"
[[ ! -L $fixture/home/.agents ]] || fail "migration materializes selected top-level link"; pass "migration materializes selected top-level link"
[[ ! -L $fixture/home/.config/nested ]] || fail "migration materializes selected config link"; pass "migration materializes selected config link"
[[ ! -L $fixture/home/.agents/nested-legacy ]] || fail "migration materializes nested legacy link"; pass "migration materializes nested legacy link"
[[ -L $fixture/home/.claude/untouched ]] || fail "migration excludes Claude"; pass "migration excludes Claude"
(( $(wc -l <"$fixture/home/package-actions") == 2 )) || fail "migration installs exact package artifacts"; pass "migration installs exact package artifacts"
(( $(wc -l <"$fixture/home/reconciliation-actions") == 3 )) || fail "migration runs package-owned reconcilers"; pass "migration runs package-owned reconcilers"
[[ -f $run_dir/phases/complete ]] || fail "migration records completion"; pass "migration records completion"
[[ ! -e $fixture/home/rebooted ]] || fail "migration suppresses upstream reboot"; pass "migration suppresses upstream reboot"

fixture=$(make_fixture preservation-resume)
if MOCK_CP_FAIL_ON_BACKUP=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "interrupted preservation fails"
fi
pass "interrupted preservation fails"
run_dir=$(readlink -f "$fixture/state/latest")
run_migration "$fixture" --resume "$run_dir" --yes >/dev/null
[[ -f $run_dir/phases/complete ]] || fail "interrupted preservation resumes"; pass "interrupted preservation resumes"
(( $(find "$fixture/backups" -mindepth 1 -maxdepth 1 -type d ! -name '*.partial' | wc -l) == 1 )) || fail "resume creates one permanent backup"; pass "resume creates one permanent backup"

fixture=$(make_fixture resume)
if MOCK_UPGRADER_FAIL=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "interrupted upstream upgrade fails"
fi
pass "interrupted upstream upgrade fails"
run_dir=$(readlink -f "$fixture/state/latest")
[[ ! -e $run_dir/phases/complete ]] || fail "partial migration is not complete"; pass "partial migration is not complete"
run_migration "$fixture" --resume "$run_dir" --yes >/dev/null
(( $(find "$fixture/state" -mindepth 1 -maxdepth 1 -type d | wc -l) == 1 )) || fail "resume reuses the original state"; pass "resume reuses the original state"
(( $(wc -l <"$fixture/home/upgrader-runs") == 2 )) || fail "resume reruns only incomplete upstream phase"; pass "resume reruns only incomplete upstream phase"
[[ -f $run_dir/phases/complete ]] || fail "resume completes migration"; pass "resume completes migration"

echo "All Pondhouse package-backed Quattro migration tests passed"

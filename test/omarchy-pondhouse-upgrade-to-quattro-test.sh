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

assert() {
  local description=$1
  shift
  "$@" || fail "$description"
  pass "$description"
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
if [[ ${MOCK_UPGRADER_FAIL:-0} == 1 ]]; then
  exit 1
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
    if [[ ${2:-} == "pondhouse-omarchy" ]]; then
      echo "pondhouse-omarchy 2"
    else
      echo "git 1"
    fi
    ;;
  -Qqe) echo git ;;
  -Qqm) echo foreign-package ;;
  -Qkk) echo "pondhouse-omarchy: 1 total file, 0 altered files" ;;
  -U) printf 'pacman %s\n' "$*" >>"$HOME/package-actions" ;;
esac
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
assert "dry run records git state" test -s "$run_dir/inventory/legacy-status.txt"
assert "dry run inventories ignored paths" grep -Fq 'config/opencode/secret.json' "$run_dir/inventory/legacy-ignored.tsv"
assert "dry run records nested checkout links" grep -Fq "$fixture/home/.agents/nested-legacy" "$run_dir/inventory/materialized-links.tsv"
assert "dry run leaves checkout link intact" test -L "$fixture/home/.config/nested"
assert "dry run makes no backup" test ! -e "$run_dir/legacy-checkout"

fixture=$(make_fixture complete)
run_migration "$fixture" --yes >/dev/null
run_dir=$(readlink -f "$fixture/state/latest")
assert "migration keeps a private checkout backup" test -f "$run_dir/legacy-checkout/config/opencode/secret.json"
assert "migration materializes selected top-level link" test ! -L "$fixture/home/.agents"
assert "migration materializes selected config link" test ! -L "$fixture/home/.config/nested"
assert "migration materializes nested legacy link" test ! -L "$fixture/home/.agents/nested-legacy"
assert "migration excludes Claude" test -L "$fixture/home/.claude/untouched"
assert "migration installs exact package artifacts" test "$(wc -l <"$fixture/home/package-actions")" -eq 2
assert "migration runs package-owned reconcilers" test "$(wc -l <"$fixture/home/reconciliation-actions")" -eq 3
assert "migration records completion" test -f "$run_dir/phases/complete"

fixture=$(make_fixture resume)
if MOCK_UPGRADER_FAIL=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "interrupted upstream upgrade fails"
fi
pass "interrupted upstream upgrade fails"
run_dir=$(readlink -f "$fixture/state/latest")
assert "partial migration is not complete" test ! -e "$run_dir/phases/complete"
run_migration "$fixture" --resume "$run_dir" --yes >/dev/null
assert "resume reuses the original backup" test "$(find "$fixture/state" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1
assert "resume reruns only incomplete upstream phase" test "$(wc -l <"$fixture/home/upgrader-runs")" -eq 2
assert "resume completes migration" test -f "$run_dir/phases/complete"

echo "All Pondhouse package-backed Quattro migration tests passed"

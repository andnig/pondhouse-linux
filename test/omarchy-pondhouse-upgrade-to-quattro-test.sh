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
    "$fixture/packages" "$fixture/quattro-root" "$fixture/signing" "$fixture/pacman-gnupg"
  chmod 700 "$fixture/signing" "$fixture/pacman-gnupg"

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
mkdir -p "$HOME/.codex" "$HOME/.pi"
echo generated >"$HOME/.codex/generated"
echo generated >"$HOME/.pi/generated"
rm -rf "$HOME/.claude"
mkdir "$HOME/.claude"
echo changed >"$HOME/.claude/changed"
if (( ${MOCK_UPGRADER_FAIL:-0} == 1 )); then
  exit 1
fi
if gum confirm "Reboot to complete Quattro upgrade now?"; then
  touch "$HOME/rebooted"
fi
mkdir -p "$PONDHOUSE_QUATTRO_ROOT"
EOF
  chmod 755 "$fixture/upgrader"

  gpg --batch --homedir "$fixture/signing" --passphrase '' \
    --quick-gen-key 'Pondhouse Test Signing <test@example.com>' ed25519 sign 0 >/dev/null 2>&1
  fingerprint=$(gpg --batch --homedir "$fixture/signing" --with-colons --list-keys |
    awk -F: '$1 == "fpr" { print $10; exit }')
  printf '%s\n' "$fingerprint" >"$fixture/fingerprint"
  gpg --batch --homedir "$fixture/pacman-gnupg" --passphrase '' \
    --quick-gen-key 'Pacman Local Trust <root@localhost>' ed25519 cert 0 >/dev/null 2>&1
  mkdir -p "$fixture/keyring-root/usr/share/pacman/keyrings"
  gpg --batch --homedir "$fixture/signing" --export "$fingerprint" \
    >"$fixture/keyring-root/usr/share/pacman/keyrings/pondhouse.gpg"
  bsdtar -caf "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" \
    -C "$fixture/keyring-root" usr
  printf 'pondhouse package\n' >"$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst"
  printf 'repository metadata\n' >"$fixture/packages/pondhouse.db.tar.gz"
  for artifact in \
    "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" \
    "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" \
    "$fixture/packages/pondhouse.db.tar.gz"; do
    gpg --batch --homedir "$fixture/signing" --detach-sign "$artifact"
  done
  printf '[options]\nLocalFileSigLevel = Optional\n' >"$fixture/pacman.conf"

  cat >"$fixture/bin/pacman" <<'EOF'
#!/bin/bash
set -euo pipefail
case "${1:-}" in
  -Q)
    case "${2:-}" in
      pondhouse-omarchy) [[ -f $MOCK_GPGDIR/installed-package ]] && echo "pondhouse-omarchy 2" ;;
      pondhouse-keyring) [[ -f $MOCK_GPGDIR/installed-keyring ]] && echo "pondhouse-keyring 1" ;;
      *) echo "git 1" ;;
    esac
    ;;
  -Qqe) echo git ;;
  -Qqm) echo foreign-package ;;
  -Qkk) echo "pondhouse-omarchy: 1 total file, 0 altered files" ;;
  *)
    if [[ " $* " == *" -U "* ]]; then
      package=${@: -1}
      config=""
      for (( i = 1; i <= $#; i++ )); do
        if [[ ${!i} == "--config" ]]; then
          (( i++ ))
          config=${!i}
        fi
      done
      [[ -n $config ]] && grep -Fqx 'LocalFileSigLevel = Required' "$config"
      gpg --batch --homedir "$MOCK_GPGDIR" --verify "$package.sig" "$package" >/dev/null 2>&1
      if [[ $package == *pondhouse-keyring* ]]; then
        touch "$MOCK_GPGDIR/installed-keyring"
      else
        [[ -f $MOCK_GPGDIR/populated ]]
        touch "$MOCK_GPGDIR/installed-package"
      fi
      printf 'pacman %s\n' "$*" >>"$HOME/package-actions"
      printf 'pacman %s\n' "$*" >>"$HOME/release-actions"
    fi
    ;;
esac
EOF

  cat >"$fixture/bin/cp" <<'EOF'
#!/bin/bash
destination=${@: -1}
/usr/bin/cp "$@"
if (( ${MOCK_CP_FAIL_ON_BACKUP:-0} == 1 )) && [[ $destination == */backups/*.partial/legacy-checkout ]]; then
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
set -euo pipefail
case "${1:-}" in
  pacman) shift; exec pacman "$@" ;;
  pacman-key)
    shift
    printf 'pacman-key %s\n' "$*" >>"$HOME/release-actions"
    case "${1:-}" in
      --add) gpg --batch --homedir "$MOCK_GPGDIR" --import "$2" >/dev/null 2>&1 ;;
      --lsign-key) gpg --batch --homedir "$MOCK_GPGDIR" --quick-lsign-key "$2" >/dev/null 2>&1 ;;
      --export) gpg --batch --homedir "$MOCK_GPGDIR" --export "$2" ;;
      --populate)
        (( ${MOCK_POPULATE_FAIL:-0} == 0 ))
        [[ $2 == "pondhouse" && -f $MOCK_GPGDIR/installed-keyring ]]
        touch "$MOCK_GPGDIR/populated"
        ;;
      *) exit 1 ;;
    esac
    ;;
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
    PONDHOUSE_SIGNING_FINGERPRINT="${TEST_SIGNING_FINGERPRINT:-$(<"$fixture/fingerprint")}" \
    PONDHOUSE_PACKAGE_SHA256="$(sha256sum "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" | cut -d' ' -f1)" \
    PONDHOUSE_KEYRING_SHA256="${TEST_KEYRING_SHA256:-$(sha256sum "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" | cut -d' ' -f1)}" \
    PONDHOUSE_REPOSITORY_SHA256="$(sha256sum "$fixture/packages/pondhouse.db.tar.gz" | cut -d' ' -f1)" \
    PONDHOUSE_SNAPSHOT_URL="${TEST_SNAPSHOT_URL:-file://$fixture/packages}" \
    PONDHOUSE_PACMAN_CONFIG="$fixture/pacman.conf" MOCK_GPGDIR="$fixture/pacman-gnupg" \
    "$COMMAND" "$@"
}

grep -Fq 'PACKAGE_VERSION=${PONDHOUSE_PACKAGE_VERSION:-2026.08.15-15}' "$COMMAND" || fail "production package release is pinned"; pass "production package release is pinned"
grep -Fq 'PACKAGE_SHA256=${PONDHOUSE_PACKAGE_SHA256:-8cf5d0a6f0e34796953ee8c46a936a729ad9e388a88af997928c0d51d2d5da1d}' "$COMMAND" || fail "production package checksum is pinned"; pass "production package checksum is pinned"
grep -Fq 'KEYRING_SHA256=${PONDHOUSE_KEYRING_SHA256:-3f08cbadc45c8a229780ad5641a7f0afee6f1e16835422cca81ab856948580c0}' "$COMMAND" || fail "production keyring checksum is pinned"; pass "production keyring checksum is pinned"
grep -Fq 'REPOSITORY_SHA256=${PONDHOUSE_REPOSITORY_SHA256:-0bfaef463b2700f28252519e65c5c737f97efffc1266fc67acc6098298651f11}' "$COMMAND" || fail "production repository checksum is pinned"; pass "production repository checksum is pinned"

fixture=$(make_fixture dry-run)
truncate -s 2M "$fixture/home/.claude/agent-state"
dry_run_output=$(run_migration "$fixture" --dry-run --yes)
run_dir=$(find "$fixture/state" -mindepth 1 -maxdepth 1 -type d -name '*-dry-run' -print -quit)
[[ -s $run_dir/inventory/legacy-status.txt ]] || fail "dry run records git state"; pass "dry run records git state"
grep -Fq 'config/opencode/secret.json' "$run_dir/inventory/legacy-ignored.tsv" || fail "dry run inventories ignored paths"; pass "dry run inventories ignored paths"
grep -Fq "$fixture/home/.agents/nested-legacy" "$run_dir/inventory/materialized-links.tsv" || fail "dry run records nested checkout links"; pass "dry run records nested checkout links"
[[ -L $fixture/home/.config/nested ]] || fail "dry run leaves checkout link intact"; pass "dry run leaves checkout link intact"
[[ ! -e $fixture/backups ]] || fail "dry run makes no backup"; pass "dry run makes no backup"
estimated_size=$(sed -n 's/^Estimated preservation space: \([0-9.]*\)MiB$/\1/p' <<<"$dry_run_output")
awk "BEGIN { exit !($estimated_size >= 2) }" || fail "dry run includes protected agent state in required space"; pass "dry run includes protected agent state in required space"

fixture=$(make_fixture complete)
if gpg --batch --homedir "$fixture/pacman-gnupg" --list-keys "$(<"$fixture/fingerprint")" >/dev/null 2>&1; then
  fail "isolated pacman trust starts without Pondhouse key"
fi
pass "isolated pacman trust starts without Pondhouse key"
run_migration "$fixture" --yes >/dev/null
run_dir=$(readlink -f "$fixture/state/latest")
backup_dir=$(<"$run_dir/inventory/backup-path")
[[ -f $backup_dir/legacy-checkout/config/opencode/secret.json ]] || fail "migration keeps a private data backup"; pass "migration keeps a private data backup"
[[ -f $backup_dir/inventory/legacy-status.txt ]] || fail "migration permanently backs up evidence"; pass "migration permanently backs up evidence"
[[ ! -L $fixture/home/.agents ]] || fail "migration materializes selected top-level link"; pass "migration materializes selected top-level link"
[[ ! -L $fixture/home/.config/nested ]] || fail "migration materializes selected config link"; pass "migration materializes selected config link"
[[ ! -L $fixture/home/.agents/nested-legacy ]] || fail "migration materializes nested legacy link"; pass "migration materializes nested legacy link"
[[ -L $fixture/home/.claude/untouched ]] || fail "migration excludes Claude"; pass "migration excludes Claude"
[[ ! -e $fixture/home/.claude/changed && ! -e $fixture/home/.codex && ! -e $fixture/home/.pi ]] || fail "migration restores excluded agent state"; pass "migration restores excluded agent state"
(( $(wc -l <"$fixture/home/package-actions") == 2 )) || fail "migration installs exact package artifacts"; pass "migration installs exact package artifacts"
add_line=$(grep -n 'pacman-key --add' "$fixture/home/release-actions" | cut -d: -f1)
sign_line=$(grep -n 'pacman-key --lsign-key' "$fixture/home/release-actions" | cut -d: -f1)
keyring_line=$(grep -n 'pacman .*pondhouse-keyring' "$fixture/home/release-actions" | cut -d: -f1)
populate_line=$(grep -n 'pacman-key --populate pondhouse' "$fixture/home/release-actions" | cut -d: -f1)
package_line=$(grep -n 'pacman .*pondhouse-omarchy' "$fixture/home/release-actions" | cut -d: -f1)
(( add_line < sign_line && sign_line < keyring_line && keyring_line < populate_line && populate_line < package_line )) || fail "migration establishes trust before package install"; pass "migration establishes trust before package install"
grep -Fqx 'LocalFileSigLevel = Optional' "$fixture/pacman.conf" || fail "migration preserves global pacman policy"; pass "migration preserves global pacman policy"
(( $(wc -l <"$fixture/home/reconciliation-actions") == 3 )) || fail "migration runs package-owned reconcilers"; pass "migration runs package-owned reconcilers"
[[ -f $run_dir/phases/complete ]] || fail "migration records completion"; pass "migration records completion"
[[ ! -e $fixture/home/rebooted ]] || fail "migration suppresses upstream reboot"; pass "migration suppresses upstream reboot"

fixture=$(make_fixture altered-keyring)
keyring_hash=$(sha256sum "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" | cut -d' ' -f1)
printf 'altered\n' >>"$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst"
if TEST_KEYRING_SHA256="$keyring_hash" run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "altered keyring archive fails closed"
fi
[[ ! -e $fixture/home/upgrader-runs ]] || fail "altered keyring fails before destructive upgrade"; pass "altered keyring archive fails closed"

fixture=$(make_fixture wrong-fingerprint)
if TEST_SIGNING_FINGERPRINT=0000000000000000000000000000000000000000 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "wrong signing fingerprint fails closed"
fi
[[ ! -e $fixture/home/upgrader-runs ]] || fail "wrong fingerprint fails before destructive upgrade"; pass "wrong signing fingerprint fails closed"

fixture=$(make_fixture invalid-signature)
printf 'invalid signature\n' >"$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst.sig"
if run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "invalid package signature fails closed"
fi
[[ ! -e $fixture/home/upgrader-runs ]] || fail "invalid signature fails before destructive upgrade"; pass "invalid package signature fails closed"

fixture=$(make_fixture unavailable-snapshot)
if TEST_SNAPSHOT_URL=file:///does-not-exist run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "unavailable snapshot fails closed"
fi
[[ ! -e $fixture/home/upgrader-runs ]] || fail "unavailable snapshot fails before destructive upgrade"; pass "unavailable snapshot fails closed"

fixture=$(make_fixture failed-population)
if MOCK_POPULATE_FAIL=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "failed keyring population fails closed"
fi
[[ ! -e $fixture/pacman-gnupg/installed-package ]] || fail "failed population installs company package"; pass "failed keyring population fails closed"

fixture=$(make_fixture preservation-resume)
if MOCK_CP_FAIL_ON_BACKUP=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "interrupted preservation fails"
fi
pass "interrupted preservation fails"
run_dir=$(readlink -f "$fixture/state/latest")
HOME="$fixture/home" USER=tester SHELL=/bin/zsh \
  PATH="$fixture/bin:/usr/bin:/bin" \
  PONDHOUSE_LEGACY_ROOT="$fixture/home/.local/share/omarchy" \
  PONDHOUSE_QUATTRO_ROOT="$fixture/quattro-root" \
  PONDHOUSE_MIGRATION_STATE="$fixture/state" \
  PONDHOUSE_MIGRATION_BACKUPS="$fixture/backups" \
  PONDHOUSE_UPGRADER_FILE="$fixture/upgrader" \
  PONDHOUSE_UPGRADER_SHA256="$(sha256sum "$fixture/upgrader" | cut -d' ' -f1)" \
  PONDHOUSE_PACKAGE_VERSION=2 PONDHOUSE_KEYRING_VERSION=1 \
  PONDHOUSE_SIGNING_FINGERPRINT="$(<"$fixture/fingerprint")" \
  PONDHOUSE_PACKAGE_SHA256="$(sha256sum "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" | cut -d' ' -f1)" \
  PONDHOUSE_KEYRING_SHA256="$(sha256sum "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" | cut -d' ' -f1)" \
  PONDHOUSE_REPOSITORY_SHA256="$(sha256sum "$fixture/packages/pondhouse.db.tar.gz" | cut -d' ' -f1)" \
  PONDHOUSE_SNAPSHOT_URL="file://$fixture/packages" \
  PONDHOUSE_PACMAN_CONFIG="$fixture/pacman.conf" MOCK_GPGDIR="$fixture/pacman-gnupg" \
  "$run_dir/pondhouse-upgrade-to-quattro" --resume "$run_dir" --yes >/dev/null
[[ -f $run_dir/phases/complete ]] || fail "interrupted preservation resumes"; pass "interrupted preservation resumes"
(( $(find "$fixture/backups" -mindepth 1 -maxdepth 1 -type d ! -name '*.partial' | wc -l) == 1 )) || fail "resume creates one permanent backup"; pass "resume creates one permanent backup"

fixture=$(make_fixture resume)
if MOCK_UPGRADER_FAIL=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "interrupted upstream upgrade fails"
fi
pass "interrupted upstream upgrade fails"
run_dir=$(readlink -f "$fixture/state/latest")
[[ -L $fixture/home/.claude/untouched && ! -e $fixture/home/.codex && ! -e $fixture/home/.pi ]] || fail "failed upgrader restores excluded agent state"; pass "failed upgrader restores excluded agent state"
[[ ! -e $run_dir/phases/complete ]] || fail "partial migration is not complete"; pass "partial migration is not complete"
run_migration "$fixture" --resume "$run_dir" --yes >/dev/null
(( $(find "$fixture/state" -mindepth 1 -maxdepth 1 -type d | wc -l) == 1 )) || fail "resume reuses the original state"; pass "resume reuses the original state"
(( $(wc -l <"$fixture/home/upgrader-runs") == 2 )) || fail "resume reruns only incomplete upstream phase"; pass "resume reruns only incomplete upstream phase"
[[ -f $run_dir/phases/complete ]] || fail "resume completes migration"; pass "resume completes migration"

echo "All Pondhouse package-backed Quattro migration tests passed"

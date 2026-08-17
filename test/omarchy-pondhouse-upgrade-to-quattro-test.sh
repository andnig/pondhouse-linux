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
    "$fixture/home/.local/share/omarchy/config/nvim" \
    "$fixture/home/.local/share/omarchy/config/nested" \
    "$fixture/home/.config" "$fixture/home/.claude" "$fixture/bin" \
    "$fixture/packages" "$fixture/quattro-root" "$fixture/signing" "$fixture/pacman-gnupg" \
    "$fixture/pacman-keyrings" "$fixture/share/scripts" "$fixture/share/tmux"
  chmod 700 "$fixture/signing" "$fixture/pacman-gnupg"
  for script in \
    herdr-close-tab.sh herdr-kill-pane.sh herdr-move-tab.sh \
    herdr-renumber-after-pane-exit.sh herdr-renumber-tabs.sh; do
    printf '#!/bin/bash\nprintf %s\\n %q\n' "$script" "$script" >"$fixture/share/scripts/$script"
    chmod 755 "$fixture/share/scripts/$script"
  done
  printf 'set -g history-limit 1000000\n' >"$fixture/share/tmux/tmux.conf"

  printf 'legacy\n' >"$fixture/home/.local/share/omarchy/config/nested/value"
  printf 'personal Neovim config\n' >"$fixture/home/.local/share/omarchy/config/nvim/personal.lua"
  printf 'ignored\n' >"$fixture/home/.local/share/omarchy/config/opencode/secret.json"
  ln -s "$fixture/home/.local/share/omarchy/config/nested/value" \
    "$fixture/home/.local/share/omarchy/config/agents/.agents/nested-legacy"
  ln -s "$fixture/home/.local/share/omarchy/config/nested" "$fixture/home/.config/nested"
  ln -s "$fixture/home/.local/share/omarchy/config/nvim" "$fixture/home/.config/nvim"
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
echo upstream >>"$HOME/phase-actions"
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
if (( ${MOCK_PACMAN_SIGNATURE_REJECT:-0} == 1 )) && [[ " $* " == *" --downloadonly "* ]]; then
  exit 1
fi
case "${1:-}" in
  -Q)
    case "${2:-}" in
      pondhouse-omarchy) [[ -f $MOCK_GPGDIR/installed-package ]] && echo "pondhouse-omarchy 2" ;;
      pondhouse-keyring)
        if [[ -f $MOCK_GPGDIR/installed-keyring ]]; then
          (( ${MOCK_WRONG_KEYRING_VERSION:-0} == 0 )) && echo "pondhouse-keyring 1" || echo "pondhouse-keyring 999"
        fi
        ;;
      *) echo "git 1" ;;
    esac
    ;;
  -Qqe) echo git ;;
  -Qqm) echo foreign-package ;;
  -Qkk) echo "${2:-package}: 3 total files, 0 altered files" ;;
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
      printf 'pacman %s\n' "$*" >>"$HOME/release-actions"
      if [[ " $* " == *" --downloadonly "* ]]; then
        echo signature-accepted >>"$HOME/phase-actions"
        exit 0
      fi
      if [[ $package == *pondhouse-keyring* ]]; then
        (( ${MOCK_KEYRING_INSTALL_FAIL:-0} == 0 ))
        touch "$MOCK_GPGDIR/installed-keyring"
        cp "$MOCK_PUBLIC_KEY" "$MOCK_KEYRING_DIR/pondhouse.gpg"
        touch "$MOCK_KEYRING_DIR/pondhouse-trusted" "$MOCK_KEYRING_DIR/pondhouse-revoked"
        echo keyring-installed >>"$HOME/phase-actions"
      else
        [[ -f $MOCK_GPGDIR/populated ]]
        (( ${MOCK_COMPANY_INSTALL_FAIL:-0} == 0 ))
        touch "$MOCK_GPGDIR/installed-package"
        echo company-installed >>"$HOME/phase-actions"
      fi
      printf 'pacman %s\n' "$*" >>"$HOME/package-actions"
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
if [[ $destination == */backups/*.partial/legacy-checkout ]]; then
  echo preservation >>"$HOME/phase-actions"
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

  cat >"$fixture/bin/mise" <<'EOF'
#!/bin/bash
echo "$*" >>"$HOME/mise-actions"
case "${1:-}" in
  use|which) exit 0 ;;
  *) exit 1 ;;
esac
EOF

  cat >"$fixture/bin/gum" <<'EOF'
#!/bin/bash
exit 0
EOF

  cat >"$fixture/bin/pgrep" <<'EOF'
#!/bin/bash
exit 1
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
      --add)
        (( ${MOCK_KEY_ADD_FAIL:-0} == 0 ))
        gpg --batch --homedir "$MOCK_GPGDIR" --import "$2" >/dev/null 2>&1
        ;;
      --lsign-key)
        (( ${MOCK_KEY_LSIGN_FAIL:-0} == 0 ))
        gpg --batch --homedir "$MOCK_GPGDIR" --quick-lsign-key "$2" >/dev/null 2>&1
        ;;
      --export)
        count=0
        [[ ! -f $MOCK_GPGDIR/export-count ]] || count=$(<"$MOCK_GPGDIR/export-count")
        (( count++ )) || true
        printf '%s\n' "$count" >"$MOCK_GPGDIR/export-count"
        if (( ${MOCK_EXPORT_MISMATCH:-0} == 1 )) || \
          (( ${MOCK_POST_POP_EXPORT_MISMATCH:-0} == 1 && count >= 2 )); then
          gpg --batch --homedir "$MOCK_GPGDIR" --export
          exit 0
        fi
        gpg --batch --homedir "$MOCK_GPGDIR" --export "$2"
        ;;
      --populate)
        (( ${MOCK_POPULATE_FAIL:-0} == 0 ))
        [[ $2 == "pondhouse" && -f $MOCK_GPGDIR/installed-keyring ]]
        touch "$MOCK_GPGDIR/populated"
        echo trust-populated >>"$HOME/phase-actions"
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
echo reconciliation >>"\$HOME/phase-actions"
if [[ $command == omarchy-pondhouse-reconcile-user ]]; then
  printf '%s\n' "\${PONDHOUSE_LEGACY_CHECKOUT:-}" >"\$HOME/nvim-legacy-checkout"
fi
EOF
  done
  chmod 755 "$fixture/bin"/*
  printf '%s\n' "$fixture"
}

run_migration() {
  local fixture=$1 upgrader_file=$1/upgrader
  shift
  (( ${TEST_DOWNLOAD_UPGRADER:-0} == 0 )) || upgrader_file=""
  HOME="$fixture/home" USER=tester SHELL=/bin/zsh \
    PATH="$fixture/bin:/usr/bin:/bin" \
    PONDHOUSE_LEGACY_ROOT="$fixture/home/.local/share/omarchy" \
    PONDHOUSE_QUATTRO_ROOT="$fixture/quattro-root" \
    PONDHOUSE_MIGRATION_STATE="$fixture/state" \
    PONDHOUSE_MIGRATION_BACKUPS="$fixture/backups" \
    PONDHOUSE_UPGRADER_FILE="$upgrader_file" \
    PONDHOUSE_UPGRADER_URL="file://$fixture/upgrader" \
    PONDHOUSE_UPGRADER_SHA256="$(sha256sum "$fixture/upgrader" | cut -d' ' -f1)" \
    PONDHOUSE_PACKAGE_VERSION=2 PONDHOUSE_KEYRING_VERSION=1 \
    PONDHOUSE_SIGNING_FINGERPRINT="${TEST_SIGNING_FINGERPRINT:-$(<"$fixture/fingerprint")}" \
    PONDHOUSE_PACKAGE_SHA256="${TEST_PACKAGE_SHA256:-$(sha256sum "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" | cut -d' ' -f1)}" \
    PONDHOUSE_KEYRING_SHA256="${TEST_KEYRING_SHA256:-$(sha256sum "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" | cut -d' ' -f1)}" \
    PONDHOUSE_REPOSITORY_SHA256="${TEST_REPOSITORY_SHA256:-$(sha256sum "$fixture/packages/pondhouse.db.tar.gz" | cut -d' ' -f1)}" \
    PONDHOUSE_SNAPSHOT_URL="${TEST_SNAPSHOT_URL:-file://$fixture/packages}" \
    PONDHOUSE_PACMAN_CONFIG="$fixture/pacman.conf" \
    PONDHOUSE_PACMAN_KEYRING_DIR="$fixture/pacman-keyrings" \
    PONDHOUSE_SHARE_DIR="$fixture/share" \
    MOCK_GPGDIR="$fixture/pacman-gnupg" MOCK_KEYRING_DIR="$fixture/pacman-keyrings" \
    MOCK_PUBLIC_KEY="$fixture/keyring-root/usr/share/pacman/keyrings/pondhouse.gpg" \
    "$COMMAND" "$@"
}

expect_preconversion_failure() {
  local fixture=$1 label=$2 output="$1/failure-output"
  shift 2
  if (( $# )); then
    if (export "$@"; run_migration "$fixture" --yes >"$output" 2>&1); then
      fail "$label"
    fi
  elif run_migration "$fixture" --yes >"$output" 2>&1; then
    fail "$label"
  fi
  [[ ! -e $fixture/home/upgrader-runs ]] || fail "$label invokes upstream"
  grep -Fq 'Migration is incomplete. Do not reboot. Resume with:' "$output" || \
    fail "$label omits failure and resume guidance"
  grep -Eq 'FAILED|did NOT match|fingerprint mismatch|gpgv:|curl:|Failed to |Real pacman rejected' "$output" || \
    fail "$label omits the failure cause"
  if [[ -d $fixture/state/latest/downloads ]]; then
    ! find "$fixture/state/latest/downloads" -maxdepth 1 \
      \( -name 'active-pondhouse-key.*' -o -name 'pacman-required.*' \) -print -quit | grep -q . || \
      fail "$label leaves temporary trust material"
  fi
  pass "$label leaves upstream invocation count at zero"
}

grep -Fq 'PACKAGE_VERSION=${PONDHOUSE_PACKAGE_VERSION:-2026.08.15-29}' "$COMMAND" || fail "production package release is pinned"; pass "production package release is pinned"
grep -Fq 'PACKAGE_SHA256=${PONDHOUSE_PACKAGE_SHA256:-66561287e7a8988216dac83fe836db07be75a643f8ac0fbc34ea79011190c86d}' "$COMMAND" || fail "production package checksum is pinned"; pass "production package checksum is pinned"
grep -Fq 'KEYRING_SHA256=${PONDHOUSE_KEYRING_SHA256:-d4e41fa5bc79de1ede3fd27202558d722d4ce433b98a6110e0736db2b7ada257}' "$COMMAND" || fail "production keyring checksum is pinned"; pass "production keyring checksum is pinned"
grep -Fq 'REPOSITORY_SHA256=${PONDHOUSE_REPOSITORY_SHA256:-3c3a14bfef30b20031a8f70fb9e188501e869c59433fdd630b3fb4dc7b2cf9ea}' "$COMMAND" || fail "production repository checksum is pinned"; pass "production repository checksum is pinned"
if grep -Fq 'configure_employee_zshrc' "$COMMAND"; then fail "migration duplicates package-owned shell policy"; fi; pass "migration delegates shell policy to package reconcilers"

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
[[ -f $backup_dir/legacy-checkout/config/nvim/personal.lua ]] || fail "migration keeps the Neovim config backup"; pass "migration keeps the Neovim config backup"
[[ -f $backup_dir/inventory/legacy-status.txt ]] || fail "migration permanently backs up evidence"; pass "migration permanently backs up evidence"
[[ ! -L $fixture/home/.agents ]] || fail "migration materializes selected top-level link"; pass "migration materializes selected top-level link"
[[ ! -L $fixture/home/.config/nested ]] || fail "migration materializes selected config link"; pass "migration materializes selected config link"
[[ ! -L $fixture/home/.config/nvim ]] || fail "migration materializes Neovim before reconciliation"; pass "migration materializes Neovim before reconciliation"
[[ ! -L $fixture/home/.agents/nested-legacy ]] || fail "migration materializes nested legacy link"; pass "migration materializes nested legacy link"
[[ -L $fixture/home/.claude/untouched ]] || fail "migration excludes Claude"; pass "migration excludes Claude"
[[ ! -e $fixture/home/.claude/changed && ! -e $fixture/home/.codex && ! -e $fixture/home/.pi ]] || fail "migration restores excluded agent state"; pass "migration restores excluded agent state"
(( $(wc -l <"$fixture/home/package-actions") == 2 )) || fail "migration installs exact package artifacts"; pass "migration installs exact package artifacts"
preservation_line=$(grep -n '^preservation$' "$fixture/home/phase-actions" | cut -d: -f1)
trust_line=$(grep -n '^trust-populated$' "$fixture/home/phase-actions" | head -n1 | cut -d: -f1)
upstream_line=$(grep -n '^upstream$' "$fixture/home/phase-actions" | cut -d: -f1)
package_line=$(grep -n '^company-installed$' "$fixture/home/phase-actions" | cut -d: -f1)
reconciliation_line=$(grep -n '^reconciliation$' "$fixture/home/phase-actions" | head -n1 | cut -d: -f1)
(( preservation_line < trust_line && trust_line < upstream_line && upstream_line < package_line && package_line < reconciliation_line )) || fail "migration phase ordering is safe"; pass "migration phase ordering is safe"
[[ -f $run_dir/phases/pondhouse-trust-ready ]] || fail "migration records trust readiness"; pass "migration records trust readiness"
grep -Fqx 'LocalFileSigLevel = Optional' "$fixture/pacman.conf" || fail "migration preserves global pacman policy"; pass "migration preserves global pacman policy"
(( $(wc -l <"$fixture/home/reconciliation-actions") == 3 )) || fail "migration runs package-owned reconcilers"; pass "migration runs package-owned reconcilers"
[[ $(<"$fixture/home/nvim-legacy-checkout") == "$backup_dir/legacy-checkout" ]] || fail "migration provides Neovim reset context"; pass "migration provides Neovim reset context"
[[ -f $run_dir/phases/complete ]] || fail "migration records completion"; pass "migration records completion"
[[ ! -e $fixture/home/rebooted ]] || fail "migration suppresses upstream reboot"; pass "migration suppresses upstream reboot"
grep -Fqx 'use --global node@22 npm:pnpm' "$fixture/home/mise-actions" || fail "migration configures Node and pnpm through Mise"; pass "migration configures Node and pnpm through Mise"
[[ -f $fixture/home/.config/tmux/tmux.conf && ! -L $fixture/home/.config/tmux/tmux.conf ]] || fail "migration installs employee-owned tmux config"; pass "migration installs employee-owned tmux config"
cmp -s "$fixture/share/tmux/tmux.conf" "$fixture/home/.config/tmux/tmux.conf" || fail "migration copies packaged tmux config"; pass "migration copies packaged tmux config"
[[ -f $fixture/home/.config/tmux/local.conf ]] || fail "migration retains tmux extension point"; pass "migration retains tmux extension point"
for script in \
  herdr-close-tab.sh herdr-kill-pane.sh herdr-move-tab.sh \
  herdr-renumber-after-pane-exit.sh herdr-renumber-tabs.sh; do
  cmp -s "$fixture/share/scripts/$script" "$fixture/home/scripts/$script" || \
    fail "migration installs $script"
  [[ -x $fixture/home/scripts/$script ]] || fail "migration makes $script executable"
done
pass "migration installs Herdr tab lifecycle scripts"

fixture=$(make_fixture downloaded-upgrader)
TEST_DOWNLOAD_UPGRADER=1 run_migration "$fixture" --yes >/dev/null
[[ -s $fixture/home/upgrader-runs ]] || fail "downloaded unsigned upstream upgrader runs"
pass "downloaded unsigned upstream upgrader runs"

fixture=$(make_fixture altered-keyring)
keyring_hash=$(sha256sum "$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst" | cut -d' ' -f1)
printf 'altered\n' >>"$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst"
expect_preconversion_failure "$fixture" "keyring checksum mismatch" "TEST_KEYRING_SHA256=$keyring_hash"

fixture=$(make_fixture altered-package)
package_hash=$(sha256sum "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" | cut -d' ' -f1)
printf 'altered\n' >>"$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst"
expect_preconversion_failure "$fixture" "company package checksum mismatch" "TEST_PACKAGE_SHA256=$package_hash"

fixture=$(make_fixture altered-repository)
repository_hash=$(sha256sum "$fixture/packages/pondhouse.db.tar.gz" | cut -d' ' -f1)
printf 'altered\n' >>"$fixture/packages/pondhouse.db.tar.gz"
expect_preconversion_failure "$fixture" "repository checksum mismatch" "TEST_REPOSITORY_SHA256=$repository_hash"

fixture=$(make_fixture wrong-fingerprint)
expect_preconversion_failure "$fixture" "wrong primary fingerprint" \
  TEST_SIGNING_FINGERPRINT=0000000000000000000000000000000000000000

fixture=$(make_fixture invalid-keyring-signature)
printf 'invalid signature\n' >"$fixture/packages/pondhouse-keyring-1-any.pkg.tar.zst.sig"
expect_preconversion_failure "$fixture" "invalid keyring signature"

fixture=$(make_fixture invalid-package-signature)
printf 'invalid signature\n' >"$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst.sig"
expect_preconversion_failure "$fixture" "invalid company package signature"

fixture=$(make_fixture invalid-repository-signature)
printf 'invalid signature\n' >"$fixture/packages/pondhouse.db.tar.gz.sig"
expect_preconversion_failure "$fixture" "invalid repository signature"

fixture=$(make_fixture unavailable-snapshot)
expect_preconversion_failure "$fixture" "unavailable snapshot" TEST_SNAPSHOT_URL=file:///does-not-exist

fixture=$(make_fixture failed-key-add)
expect_preconversion_failure "$fixture" "pacman-key add failure" MOCK_KEY_ADD_FAIL=1

fixture=$(make_fixture failed-local-sign)
expect_preconversion_failure "$fixture" "pacman-key local-sign failure" MOCK_KEY_LSIGN_FAIL=1

fixture=$(make_fixture failed-active-export)
expect_preconversion_failure "$fixture" "active fingerprint export mismatch" MOCK_EXPORT_MISMATCH=1

fixture=$(make_fixture failed-keyring-install)
expect_preconversion_failure "$fixture" "keyring pacman install failure" MOCK_KEYRING_INSTALL_FAIL=1

fixture=$(make_fixture wrong-keyring-version)
expect_preconversion_failure "$fixture" "wrong installed keyring version" MOCK_WRONG_KEYRING_VERSION=1

fixture=$(make_fixture failed-population)
expect_preconversion_failure "$fixture" "failed keyring population" MOCK_POPULATE_FAIL=1

fixture=$(make_fixture failed-post-population-export)
expect_preconversion_failure "$fixture" "post-population fingerprint mismatch" \
  MOCK_POST_POP_EXPORT_MISMATCH=1

fixture=$(make_fixture rejected-by-pacman)
expect_preconversion_failure "$fixture" "pacman package-signature rejection" \
  MOCK_PACMAN_SIGNATURE_REJECT=1

fixture=$(make_fixture preservation-resume)
if MOCK_CP_FAIL_ON_BACKUP=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "interrupted preservation fails"
fi
pass "interrupted preservation fails"
run_dir=$(readlink -f "$fixture/state/latest")
printf 'altered after preflight\n' >>"$run_dir/downloads/pondhouse-omarchy-2-x86_64.pkg.tar.zst"
if run_migration "$fixture" --resume "$run_dir" --yes >/dev/null 2>&1; then
  fail "resume trusts altered preflight artifacts"
fi
[[ ! -e $fixture/home/upgrader-runs ]] || fail "altered preflight resume invokes upstream"
cp "$fixture/packages/pondhouse-omarchy-2-x86_64.pkg.tar.zst" \
  "$run_dir/downloads/pondhouse-omarchy-2-x86_64.pkg.tar.zst"
pass "resume revalidates checkpointed release artifacts"
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
  PONDHOUSE_PACMAN_CONFIG="$fixture/pacman.conf" \
  PONDHOUSE_PACMAN_KEYRING_DIR="$fixture/pacman-keyrings" \
  MOCK_GPGDIR="$fixture/pacman-gnupg" MOCK_KEYRING_DIR="$fixture/pacman-keyrings" \
  MOCK_PUBLIC_KEY="$fixture/keyring-root/usr/share/pacman/keyrings/pondhouse.gpg" \
  "$run_dir/pondhouse-upgrade-to-quattro" --resume "$run_dir" --yes >/dev/null
[[ -f $run_dir/phases/complete ]] || fail "interrupted preservation resumes"; pass "interrupted preservation resumes"
(( $(find "$fixture/backups" -mindepth 1 -maxdepth 1 -type d ! -name '*.partial' | wc -l) == 1 )) || fail "resume creates one permanent backup"; pass "resume creates one permanent backup"

fixture=$(make_fixture company-install-resume)
if MOCK_COMPANY_INSTALL_FAIL=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "failed company package installation fails"
fi
run_dir=$(readlink -f "$fixture/state/latest")
[[ -f $run_dir/phases/pondhouse-trust-ready && -f $run_dir/phases/upstream-upgrade ]] || \
  fail "post-conversion failure retains trust and upstream checkpoints"
run_migration "$fixture" --resume "$run_dir" --yes >/dev/null
(( $(wc -l <"$fixture/home/upgrader-runs") == 1 )) || fail "resume reruns completed upstream conversion"
[[ -f $fixture/pacman-gnupg/installed-package ]] || fail "resume retries company package installation"
pass "resume reverifies trust and does not rerun completed upstream conversion"

fixture=$(make_fixture invalid-trust-checkpoint)
if MOCK_COMPANY_INSTALL_FAIL=1 run_migration "$fixture" --yes >/dev/null 2>&1; then
  fail "failed company package installation fails before checkpoint validation"
fi
run_dir=$(readlink -f "$fixture/state/latest")
gpg --batch --homedir "$fixture/pacman-gnupg" --yes --delete-key "$(<"$fixture/fingerprint")" >/dev/null 2>&1
rm -f "$fixture/pacman-gnupg/populated"
if run_migration "$fixture" --resume "$run_dir" --yes >/dev/null 2>&1; then
  fail "resume blindly trusts an invalid trust checkpoint"
fi
(( $(wc -l <"$fixture/home/upgrader-runs") == 1 )) || fail "resume reruns completed upstream conversion"
[[ ! -f $fixture/pacman-gnupg/installed-package ]] || fail "invalid checkpoint installs company package"
pass "resume fails closed when checkpointed trust is invalid"

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

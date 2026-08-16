#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${PONDHOUSE_ARCH_TEST_IMAGE:-archlinux:base-devel}

if [[ ${1:-} != "--inside" ]]; then
  exec docker run --rm --privileged -v "$ROOT:/repo:ro" "$IMAGE" \
    /bin/bash /repo/test/omarchy-pondhouse-pacman-integration-test.sh --inside
fi

pacman -Sy --noconfirm --needed curl git inetutils sudo >/dev/null
useradd -m -s /bin/bash tester
printf 'tester ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/pondhouse-test
chmod 440 /etc/sudoers.d/pondhouse-test
pacman-key --init

WORK=/tmp/pondhouse-pacman-integration
SIGNING_HOME="$WORK/signing"
PACKAGES="$WORK/packages"
HOME_DIR=/home/tester
mkdir -p "$SIGNING_HOME" "$PACKAGES" "$WORK/keyring" "$WORK/company" \
  "$HOME_DIR/.local/share/omarchy" "$HOME_DIR/.config" "$WORK/quattro-root"
chmod 700 "$SIGNING_HOME"
chown -R tester:tester "$WORK" "$HOME_DIR"

runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" --passphrase '' \
  --quick-gen-key 'Pondhouse Integration Signing <integration@pondhouse.test>' ed25519 sign 0 >/dev/null 2>&1
FINGERPRINT=$(runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" \
  --with-colons --list-keys | awk -F: '$1 == "fpr" { print $10; exit }')

runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" --export "$FINGERPRINT" \
  >"$WORK/keyring/pondhouse.gpg"
printf '%s:4:\n' "$FINGERPRINT" >"$WORK/keyring/pondhouse-trusted"
printf '%s\n' "$FINGERPRINT" >"$WORK/keyring/pondhouse-revoked"

cat >"$WORK/keyring/PKGBUILD" <<'EOF'
pkgname=pondhouse-keyring
pkgver=1
pkgrel=1
arch=(any)
package() {
  install -Dm644 "$startdir/pondhouse.gpg" "$pkgdir/usr/share/pacman/keyrings/pondhouse.gpg"
  install -Dm644 "$startdir/pondhouse-trusted" "$pkgdir/usr/share/pacman/keyrings/pondhouse-trusted"
  install -Dm644 "$startdir/pondhouse-revoked" "$pkgdir/usr/share/pacman/keyrings/pondhouse-revoked"
}
EOF

cat >"$WORK/company/PKGBUILD" <<'EOF'
pkgname=pondhouse-omarchy
pkgver=2
pkgrel=1
arch=(any)
package() {
  install -Dm644 /dev/null "$pkgdir/usr/share/pondhouse/integration-test"
}
EOF

runuser -u tester -- bash -c "cd '$WORK/keyring' && makepkg --noconfirm --nodeps >/dev/null"
runuser -u tester -- bash -c "cd '$WORK/company' && makepkg --noconfirm --nodeps >/dev/null"
mv "$WORK/keyring/pondhouse-keyring-1-1-any.pkg.tar.zst" "$PACKAGES/"
mv "$WORK/company/pondhouse-omarchy-2-1-any.pkg.tar.zst" \
  "$PACKAGES/pondhouse-omarchy-2-1-x86_64.pkg.tar.zst"
chown tester:tester "$PACKAGES"/*

for artifact in "$PACKAGES"/*.pkg.tar.zst; do
  runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" --detach-sign "$artifact"
done
runuser -u tester -- repo-add "$PACKAGES/pondhouse.db.tar.gz" \
  "$PACKAGES/pondhouse-omarchy-2-1-x86_64.pkg.tar.zst" >/dev/null
runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" --detach-sign \
  "$PACKAGES/pondhouse.db.tar.gz"

if pacman-key --export "$FINGERPRINT" >/dev/null 2>&1; then
  echo "not ok - isolated Arch environment unexpectedly contains Pondhouse trust" >&2
  exit 1
fi
echo "ok - isolated Arch environment starts without Pondhouse trust"

runuser -u tester -- git -C "$HOME_DIR/.local/share/omarchy" init -q
runuser -u tester -- git -C "$HOME_DIR/.local/share/omarchy" -c user.name=Test \
  -c user.email=test@example.com commit --allow-empty -qm initial

cat >"$WORK/upgrader" <<'EOF'
#!/bin/bash
printf 'run\n' >>"$HOME/upgrader-runs"
mkdir -p "$PONDHOUSE_QUATTRO_ROOT"
EOF
chmod 755 "$WORK/upgrader"

for command in omarchy-pondhouse-reconcile-packages omarchy-pondhouse-reconcile-system \
  omarchy-pondhouse-reconcile-user; do
  cat >"/usr/local/bin/$command" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod 755 "/usr/local/bin/$command"
done

KEYRING="$PACKAGES/pondhouse-keyring-1-1-any.pkg.tar.zst"
PACKAGE="$PACKAGES/pondhouse-omarchy-2-1-x86_64.pkg.tar.zst"
REPOSITORY="$PACKAGES/pondhouse.db.tar.gz"
COMMAND=/repo/bin/omarchy-pondhouse-upgrade-to-quattro

run_migration() {
  local state=$1
  runuser -u tester -- env HOME="$HOME_DIR" USER=tester SHELL=/bin/bash \
  PONDHOUSE_LEGACY_ROOT="$HOME_DIR/.local/share/omarchy" \
  PONDHOUSE_QUATTRO_ROOT="$WORK/quattro-root" \
  PONDHOUSE_MIGRATION_STATE="$WORK/$state" \
  PONDHOUSE_MIGRATION_BACKUPS="$WORK/backups" \
  PONDHOUSE_UPGRADER_FILE="$WORK/upgrader" \
  PONDHOUSE_UPGRADER_SHA256="$(sha256sum "$WORK/upgrader" | cut -d' ' -f1)" \
  PONDHOUSE_PACKAGE_VERSION=2-1 PONDHOUSE_KEYRING_VERSION=1-1 \
  PONDHOUSE_SIGNING_FINGERPRINT="$FINGERPRINT" \
  PONDHOUSE_KEYRING_SHA256="$(sha256sum "$KEYRING" | cut -d' ' -f1)" \
  PONDHOUSE_PACKAGE_SHA256="$(sha256sum "$PACKAGE" | cut -d' ' -f1)" \
  PONDHOUSE_REPOSITORY_SHA256="$(sha256sum "$REPOSITORY" | cut -d' ' -f1)" \
  PONDHOUSE_SNAPSHOT_URL="file://$PACKAGES" \
  "$COMMAND" --yes
}

if run_migration rejected-state >/dev/null 2>&1; then
  echo "not ok - real pacman accepted a package revoked by populated policy" >&2
  exit 1
fi
[[ ! -e $HOME_DIR/upgrader-runs ]]
echo "ok - real pacman policy rejection leaves upstream invocation count at zero"

pacman -Rdd --noconfirm pondhouse-keyring >/dev/null
pacman-key --delete "$FINGERPRINT" >/dev/null
: >"$WORK/keyring/pondhouse-revoked"
runuser -u tester -- bash -c "cd '$WORK/keyring' && makepkg -f --noconfirm --nodeps >/dev/null"
mv -f "$WORK/keyring/pondhouse-keyring-1-1-any.pkg.tar.zst" "$KEYRING"
rm -f "$KEYRING.sig" "$PACKAGES/pondhouse.db" "$PACKAGES/pondhouse.db.tar.gz" \
  "$PACKAGES/pondhouse.db.tar.gz.sig" "$PACKAGES/pondhouse.files" "$PACKAGES/pondhouse.files.tar.gz"
runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" --detach-sign "$KEYRING"
runuser -u tester -- repo-add "$REPOSITORY" "$PACKAGE" >/dev/null
runuser -u tester -- gpg --batch --homedir "$SIGNING_HOME" --detach-sign "$REPOSITORY"

run_migration state >/dev/null

[[ $(pacman -Q pondhouse-keyring) == "pondhouse-keyring 1-1" ]]
[[ $(pacman -Q pondhouse-omarchy) == "pondhouse-omarchy 2-1" ]]
EXPORTED_FINGERPRINT=$(pacman-key --export "$FINGERPRINT" |
  gpg --batch --show-keys --with-colons 2>/dev/null |
  awk -F: '$1 == "pub" { primary = 1; next } primary && $1 == "fpr" { print $10; exit }')
[[ $EXPORTED_FINGERPRINT == $FINGERPRINT ]]
[[ -f $WORK/state/latest/phases/pondhouse-trust-ready ]]
[[ $(wc -l <"$HOME_DIR/upgrader-runs") == 1 ]]
echo "ok - real pacman-key imports, trusts, populates, and exports the full primary fingerprint"
echo "ok - real pacman installs the exact signed keyring and company packages"

cp "$PACKAGE" "$WORK/tampered.pkg.tar.zst"
cp "$PACKAGE.sig" "$WORK/tampered.pkg.tar.zst.sig"
printf 'tampered\n' >>"$WORK/tampered.pkg.tar.zst"
cp /etc/pacman.conf "$WORK/strict-pacman.conf"
printf '\nLocalFileSigLevel = Required\n' >>"$WORK/strict-pacman.conf"
if pacman --config "$WORK/strict-pacman.conf" -U --noconfirm "$WORK/tampered.pkg.tar.zst" \
  >/dev/null 2>&1; then
  echo "not ok - real pacman accepted a modified package" >&2
  exit 1
fi
echo "ok - real pacman rejects a modified signed-package candidate"
echo "All isolated real pacman integration tests passed"

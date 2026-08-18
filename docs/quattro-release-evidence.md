# Quattro Rollout Evidence

Release `pondhouse-omarchy 2026.08.15-36` was checked against the immutable
snapshot at
`https://packages.pondhouse-data.com/snapshots/2026.08.15-36/x86_64` on
2026-08-18.

| Artifact | SHA-256 |
| --- | --- |
| `pondhouse-keyring-2026.08.15-1-any.pkg.tar.zst` | `059c6d78e1146dab47e707bb76b6e5ba4c5e86942a401511390bd27d7355d42b` |
| `pondhouse-omarchy-2026.08.15-36-x86_64.pkg.tar.zst` | `ba3bd0a1fbeab4d7a54dcf27d1f5c11b28afb9b5a35cfc96570737d4c4ec49f3` |
| `pondhouse.db.tar.gz` | `cab95c6032aa1db284686d8299c95a92cd9b526cd91530afecc701f78344815f` |

The package source is commit `915feac494d81a48d224e176057578230cfbab84`.
The database and both packages have valid signatures from the trusted Pondhouse
signing key. The v3 updater and ISO builder pin this exact snapshot and the full
primary fingerprint `2E4DE2E86D2D5D4EF994B0A849EE396C83FEEC69`.

The fast migration contract suite is reproducible with:

```bash
bash test/omarchy-pondhouse-upgrade-to-quattro-test.sh
```

It covers preservation, exact phase ordering, protected agent state, resume,
reconciliation, and suppressed reboot behavior. Every checksum, fingerprint,
artifact-signature, active-key, keyring-installation, population, and mocked
pacman-policy failure asserts that the upstream invocation count remains zero.
This suite mocks `pacman` and `pacman-key`; it is not evidence of real Arch trust
behavior.

The privileged release gate requires Docker with permission to run containers
and network access to pull the Arch image and synchronize its package database.
Run it with:

```bash
test/omarchy-pondhouse-pacman-integration-test.sh
```

The gate uses a digest-pinned disposable `archlinux:base-devel` container and
invokes the production migration command as an employee. It starts with no Pondhouse key,
builds real signed Arch package archives, invokes real `/usr/bin/pacman-key` for
initialization, import, local trust, population, and export, and invokes real
`/usr/bin/pacman` for required-signature acceptance and package installation.
The 2026-08-16 run reported:

```text
ok - isolated Arch environment starts without Pondhouse trust
ok - real pacman policy rejection leaves upstream invocation count at zero
ok - real pacman-key imports, trusts, populates, and exports the full primary fingerprint
ok - real pacman installs the exact signed keyring and company packages
ok - real pacman rejects a modified signed-package candidate
All isolated real pacman integration tests passed
```

The host pacman database, trust store, and `/etc/pacman.conf` are not mounted
into the disposable environment and remain unchanged. Temporary strict pacman
configuration is private, requires local-file signatures, and is removed by the
production command after both successful and failed transactions.

Committed employee-update coverage is reproducible with:

```bash
test/omarchy-pondhouse-update-layout-test.sh
```

It verifies both supported Git layouts:

- a direct checkout pulling `master` from the shared Pondhouse repository;
- a personal fork with the shared repository configured as `pondhouse`, while
  retaining and pushing the employee customization commit.

Both layouts receive the executable upgrade command and resolve `omarchy
pondhouse upgrade-to-quattro --help`. The personal-fork fixture retains the
employee commit and pushes only to employee `origin`; a conflicting update gives
recovery guidance without resetting or discarding employee work. Fresh and
upgraded parity for this package release is recorded by the closed Pondhouse
Omarchy issue #11 and the corresponding delivery evidence in the package and ISO
repositories.

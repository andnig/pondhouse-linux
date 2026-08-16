# Quattro Rollout Evidence

Release `pondhouse-omarchy 2026.08.15-14` was checked against the immutable
snapshot at
`https://packages.pondhouse-data.com/snapshots/2026.08.15-14/x86_64` on
2026-08-16.

| Artifact | SHA-256 |
| --- | --- |
| `pondhouse-keyring-2026.08.15-1-any.pkg.tar.zst` | `3a9e97447fb41d3be7df7825e98197227a7d39b332af093b7e66115488c4cdc4` |
| `pondhouse-omarchy-2026.08.15-14-x86_64.pkg.tar.zst` | `00a85f60451155c0e0ccc19c3e5447143eaeb127b4795e59b124336fad6eea87` |
| `pondhouse.db` | `492d31469eccc2d31b8fc8a22bf64fdad5f20b93f38d5f0c2f2b70a1f1b87d9b` |

`gpgv` accepted all three detached signatures using the packaged Pondhouse
public signing key. The signer was `Pondhouse Package Signing
<packages@pondhouse-data.com>` with signing subkey fingerprint
`68B44A47FF98508F594ECEC1BC705B1A8A53E72E`.

The shell migration harness passed preservation, protected agent state,
interruption/resume, exact package installation, reconciliation, and suppressed
reboot scenarios. Isolated employee update fixtures verified both supported Git
layouts:

- a direct checkout pulling `master` from the shared Pondhouse repository;
- a personal fork with the shared repository configured as `pondhouse`, while
  retaining and pushing the employee customization commit.

Both layouts received the executable upgrade command and exposed `omarchy
pondhouse upgrade-to-quattro` through CLI discovery. Fresh and upgraded parity
for this package release is recorded by the closed Pondhouse Omarchy issue #11
and the corresponding delivery evidence in the package and ISO repositories.

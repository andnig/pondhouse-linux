# Quattro Rollout Evidence

Release `pondhouse-omarchy 2026.08.15-15` was checked against the immutable
snapshot at
`https://packages.pondhouse-data.com/snapshots/2026.08.15-15/x86_64` on
2026-08-16.

| Artifact | SHA-256 |
| --- | --- |
| `pondhouse-keyring-2026.08.15-1-any.pkg.tar.zst` | `3f08cbadc45c8a229780ad5641a7f0afee6f1e16835422cca81ab856948580c0` |
| `pondhouse-omarchy-2026.08.15-15-x86_64.pkg.tar.zst` | `8cf5d0a6f0e34796953ee8c46a936a729ad9e388a88af997928c0d51d2d5da1d` |
| `pondhouse.db.tar.gz` | `0bfaef463b2700f28252519e65c5c737f97efffc1266fc67acc6098298651f11` |

`gpgv` accepted all three detached signatures using the packaged Pondhouse
public signing key. The signer was `Pondhouse Package Signing
<packages@pondhouse-data.com>` with signing subkey fingerprint
`68B44A47FF98508F594ECEC1BC705B1A8A53E72E`.

The shell migration harness passed a real isolated GnuPG trust bootstrap with no
preinstalled Pondhouse key, exact primary-fingerprint validation, required local
package signatures, keyring population, preservation, protected agent state,
interruption/resume, reconciliation, and suppressed reboot scenarios. Altered
archives, wrong fingerprints, failed population, invalid signatures, and an
unavailable snapshot all failed closed before the upstream upgrade. Isolated
employee update fixtures verified both supported Git
layouts:

- a direct checkout pulling `master` from the shared Pondhouse repository;
- a personal fork with the shared repository configured as `pondhouse`, while
  retaining and pushing the employee customization commit.

Both layouts received the executable upgrade command and exposed `omarchy
pondhouse upgrade-to-quattro` through CLI discovery. Fresh and upgraded parity
for this package release is recorded by the closed Pondhouse Omarchy issue #11
and the corresponding delivery evidence in the package and ISO repositories.

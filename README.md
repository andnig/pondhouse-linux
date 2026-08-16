# Pondhouse Omarchy v3

This repository is the maintained Pondhouse Omarchy v3 update lane. Its final
purpose is to migrate employees to **Pondhouse Linux, powered by Omarchy
Quattro**. After a successful migration, signed Pondhouse packages replace this
Git checkout as the company update mechanism.

## Upgrade To Quattro

Before starting:

- Connect your normal external backup and confirm important personal files are
  backed up.
- Save or commit work you need from the Omarchy checkout. The migration records
  dirty and untracked content, but it does not publish it for you.
- Ensure the machine has enough free space for a permanent checkout backup and
  materialized configuration links.
- Do not reset, clean, or force-update a checkout with conflicts. Ask for help
  instead so local work is not discarded.

Run these commands in order:

```bash
omarchy-update
omarchy pondhouse upgrade-to-quattro --help
omarchy pondhouse upgrade-to-quattro --dry-run
omarchy pondhouse upgrade-to-quattro
```

The dry run records Git state, ignored data, installed packages, services,
application defaults, onboarding markers, checkout-backed links, required
space, and backup destinations. It does not change workstation state. Review
the paths and space estimate before running the migration.

If migration is interrupted or fails, **do not reboot**. Run the exact
`--resume` command printed by the migration. Completed phases are checkpointed,
so resuming does not repeat successful destructive operations. Reboot only
after the command reports:

```text
Pondhouse Quattro migration completed.
```

After reboot, verify the package-backed workstation:

```bash
omarchy-pondhouse-verify-delivery upgraded
```

The result must report `PASS`. If it does not, keep the migration records and
backup and ask for help before changing or deleting either one.

## What Is Preserved

The migration inventories and backs up the legacy checkout before running the
checksum-pinned Basecamp Quattro upgrader. It materializes only active links
whose targets are inside that checkout. Foreign links and links in backup
directories are left untouched.

Application state, browser profiles, Teams assets, SSH state, Syncthing
identity and database, Sunshine credentials and pairing, personal scripts, and
the legacy checkout remain employee-owned. Claude, Codex, and Pi state is
explicitly excluded from Pondhouse reconciliation and restored if the upstream
upgrade touches it.

Permanent migration copies are stored under:

```text
~/.local/share/pondhouse/backups/quattro-migrations/
```

Private execution records and the saved resumable command are stored under:

```text
~/.local/state/pondhouse/quattro-migrations/
```

These backups are never deleted automatically. Do not restore the complete v3
configuration over Quattro. Use the package reconciliation report to restore
only deliberate employee overrides.

## Updates After Migration

The migration installs the immutable signed release
`pondhouse-omarchy 2026.08.15-15` and configures:

```ini
[pondhouse]
SigLevel = Required
Server = https://packages.pondhouse-data.com/stable/$arch
```

Future Pondhouse changes arrive through normal Omarchy and pacman updates. No
active command, configuration, or managed link should depend on this checkout
after delivery verification passes. The checkout and timestamped backup remain
only as migration evidence and employee data.

For Quattro setup, optional actions, dotfiles, Syncthing, terminal workflows,
and troubleshooting, use the
[Pondhouse Omarchy employee guide](https://github.com/pondhouse-data/pondhouse-omarchy#readme).
The short internal rollout notice is in
[`docs/quattro-rollout-announcement.md`](docs/quattro-rollout-announcement.md).

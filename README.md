# Omarchy

Omarchy is a beautiful, modern & opinionated Linux distribution by DHH.

Read more at [omarchy.org](https://omarchy.org).

## Getting Started

Run `curl -fsSL https://pondhouse-data.com/utilities/arch/install | bash`

## Install script

An install script is hosted at [https://pondhouse-data.com/utilities/arch/install](https://pondhouse-data.com/utilities/arch/install). This script will download and run the Omarchy installer. It is recommended to review the script before running it.

Add the script in the `public/utilities/arch` directory to the pondhouse-data.com website.

## Getting Started

On arch, we use [Omarchy](https://omarchy.org/) as a base configuration.
It provides a nice, minimal opinionated setup for Arch Linux. However, we
are not going to use it directly, as it's a bit too opinionated, so we
keep it as a git submodule and then only fetch the files we need.

## Tailscale

### Old (this is not needed anymore, as tailscale is part of pondhouse linux postinstall.sh)

Use systemctl to enable and start the service:
sudo systemctl enable --now tailscaled

### New

Connect your machine to your Tailscale network and authenticate in your browser:
sudo tailscale up

You can find your Tailscale IPv4 address by running:
tailscale ip -4

## Set up FIDO2 authentication

If you have a Fido-token you can use it for sudo authentication. Use the
omarchy menu to install it

## Set up Fingerprint reader

If you have a fingerprint reader, you can use it for sudo authentication
as well as user login. Use the omarchy menu to install it.

## "Windows Hello" like face recognition auth

Use howdy for that.

```bash
yay -S --noconfirm howdy-git
```

Add the following to `/etc/pam.d/system-auth` on top:

```
auth sufficient pam_howdy.so
auth sufficient pam_unix.so try_first_pass likeauth nullok
```

This will allow to use your camera for all authentication mechanisms (login,
sudo, ...)

Use `v4l2-ctl --list-devices` to list all cameras. Output is something
like this:

```bash
v4l2-ctl --list-devices
Logitech BRIO (usb-0000:2a:00.1-2.2):
        /dev/video0
        /dev/video1
        /dev/video2
        /dev/video3
        /dev/media0
```

Next you need to find, which is the infrared camera. Use `mpv /dev/video0`, ...
This will open a camera feed. Remember the black and white one.

Next and finally, we need to configure `howdy`:

```bash
sudo howdy config
```

Find these entries and change them as follows:

```conf
certainty = 3.8
device_path = /dev/video2 # Change this to your infrared device
max_height = 640
```

Now we can add our face:

```bash
sudo howdy add
```

And finally, we can test if the face recognition works by running:

```bash
sudo pacman -S xorg-xhost
xhost si:localuser:root
sudo howdy test
```

## Sunshine

0. Start sunshine service with `systemctl --user enable --now sunshine.service`
1. On first login to sunshine, create the username/password
2. Copy this to `~/.config/sunshine/sunshine.conf`

   ```ini
    global_prep_cmd = [{"do":"hyprctl output create headless sunshine","undo":""},{"do":"hyprctl keyword monitor \"sunshine,2560x1600@120,auto,1.25\"","undo":""},{"do":"hyprctl dispatch moveworkspacetomonitor 10 sunshine","undo":""},{"do":"hyprctl dispatch workspace 10","undo":""}]
    nvenc_preset = 6
    output_name = 1
    stream_audio = true
   ```

Running sunshine is still a bit manual.

```bash
hyprctl output crate headless sunshine
hyprctl keyword monitor "sunshine,2560x1600@120,auto,1.25"
xrandr -q
# Note down the id (number) of the headless output (probably 1)
```

Set the id in the sunshine -> audio/video settings -> "Display Number"

Then, create and dispatch workspace 10 to the headless output:

```bash
hyprctl dispatch workspace 10
hyprctl dispatch moveworkspacetomonitor 10 sunshine
hyprctl dispatch workspace 10
```

## 1Password

1Password is installed. If there are issues with storing 2FA tokens, try:

```bash
# Check if gnome-keyring is running
systemctl --user status gnome-keyring-daemon.socket
# If not, enable and start it
systemctl --user enable --now gnome-keyring-daemon.socket

# Create a test key (to set up the default keyring)
secret-tool store --label="test" testkey testvalue
# Retrieve the test key
secret-tool lookup testkey testvalue
# Remove the test key
secret-tool clear testkey testvalue
```

Now restart the 1Password app and see if it works.

### Setting up the 1Password Agent

1. Make sure you have an SSH key added to your 1Password account.
2. Open the 1Password app, then select your account or collection at the top of the sidebar and select Settings > Developer.
   Select Set Up SSH Agent, then choose whether or not you want to display SSH key names when you authorize connections.
3. Also select "Integrate with 1Password CLI"

### SSH alternative

If you do not want to use 1Password:

1. Place your private key in `~/.ssh/id_rsa` and set permissions to 600 with `chmod 600 ~/.ssh/id_rsa`
2. Also place your public key in `~/.ssh/id_rsa.pub` and set permissions to 644 with `chmod 644 ~/.ssh/id_rsa.pub`
3. Add the public key to your GitHub account (or other services you use)
4. in ~/.zshrc, search the line `SSH Agent` and follow the instructions there to enable the ssh-agent on login

## Zen Browser

Initially, there are some manual steps to do:

1. Create new workspaces for the zen browser:
   a. One for private/general purpose browsing
   b. One for Pondhouse
   c. One for DevOps and More
   d. One for Russmedia (deprecated)

2. Open zen browser in each workspace and log in to the respective accounts.

3. Add outlook, teams and sharepoint to "Essentials" (these are pinned to the sidebar).

## Chromium

Chromium is used for launching web apps (like Teams), as chromium allows for
border-less windows. For this, we also need respective profiles and logins.

```bash
chromium --profile-directory="Profile 1"
chromium --profile-directory="Profile 2"
chromium --profile-directory="Profile 3"
chromium --profile-directory="Profile 4"
```

## MS Teams

In the `applications` folder, copy the `teams.desktop` file and adjust accordingly.
Use different --profile-directory for different teams accounts.
Then run `omarchy-refresh-applications`.

## Syncthing

Start syncthing with `systemctl enable --now syncthing@andreas`

Open syncthing in your Pixel 6 and the web interface of the new computer on localhost:8384.
On Pixel 6, add the new device - when asked for confirmation on the new device
select "introducer" ("Verteilergeraet") - this automatically connects with all
other devices Pixel 6 is synced.
Add the shared folders on Pixel 6 as normal.
(If the web ui cant be reached, look at `systemctl status syncthing@andreas` for
info on which port the ui runs).

On desktop, use folders ~/.sync (id: sync-0), ~/.notes (id: notes-0).

> **NOTE:** Pixel 6 should be set as "Introducer" device for all folders, so that
> new devices added to Pixel 6 automatically get all folders.

### Pondhouse Syncthing setup

To have a dedicated pondhouse syncthing setup, create a new folder ~/.pondhouse-sync and
add the folder to the respective devices to sync.

## Google docker

```bash
gcloud init
gcloud auth configure-docker europe-west3-docker.pkg.dev
```

## Microsoft Fonts

If you desperately need Microsoft fonts, you can install them with:

```bash
yay -S --noconfirm ttf-ms-win11-auto
```

Note that free alternatives are installed by default.

## NVIDIA undervolting

To undervolt your NVIDIA GPU:

1. Download the latest release here: `https://github.com/Dreaming-Codes/nvidia_oc`
2. Move it to /user/local/bin and make it executable
3. Create a systemd service file at `/etc/systemd/system/nvidia-oc.service` with the following content:

   ```ini
   [Unit]
   Description=NVIDIA Overclocking Service
   After=network.target

   [Service]
   ExecStart=/usr/local/bin/nvidia_oc set --index 0 --power-limit 290000 --freq-offset 200 --mem-offset 850 --min-clock 210 --max-clock 2730
   User=root
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```

   These files are for a NVIDIA 4080.

   This will set the power limit 250W, GPU clock offset +255MHz, memory clock offset +850MHz, minimum clock 210MHz, maximum clock 2745MHz.
   - GPU clock offset means: The GPU will run the clock speed of eg. 1600MHz at voltage levels that would normally be used for 1855MHz. So it will be more efficient.
   - Minimum clock: This is the idle clock. Use `nvidia-smi` to find the default minimum idle clock.
   - Maximum clock: This is the maximum boost clock. Run your most advanced workload, then use `nvidia-smi` to find the maximum clock it reached.

4. Enable and start the service:

   ```bash
   sudo systemctl enable --now nvidia-oc.service
   ```

> **Note:** To test out different settings and compare them to default, you can manually run the command from `ExecStart` in a terminal.

## Thunderbird

In your thunderbird, go to menu -> help -> troubleshooting information. From there, click on the about:profiles link. This will show the currently active profile and its location.

Copy the whole content of the profile folder to backup.

To restore, copy the content back to the profile folder.

## Setting up a private pondhouse-linux fork

Most probably you'd want to customize some settings. For that, you want to:

1. Create a new repository on Github.
2. Run `omarchy-init-custom-repo`

This will set up your custom repository as the default origin and a `pondhouse`
remote pointing to the original repository.

From there, you can use the `omarchy-update` or `omarchy-update-git` commands
as normal to pull from both the original repository and your custom repository.
When pushing, your changes will be pushed to your custom repository, while you
can still pull updates from the original repository.

### Outdated

> The following section is outdated. Use the script above.

1. Create a new repository on Github.
2. Run `git remote add custom <your-repository-url>` in the pondhouse-linux/omarchy repository.
3. Run `git config remote.pushDefault custom` to set the default push remote to your custom repository.
4. Run `git pull custom master` to pull your latest custom changes

Now all pushes per default go to your custom repository. Pulls are still from
the original repository, meaning also updates are only pulled from the original
repository.

## Syncing with upstream basecamp

`install/config/config.sh` in this fork replaces upstream's `cp -R` install
with per-entry symlinks (`ln -sfn ~/.local/share/omarchy/config/<X>
~/.config/<X>`). That means every config directory under `~/.config/` is a
symlink into the source tree, so editing the source updates the running
config immediately.

The problem: upstream migration scripts under `migrations/` still use raw
`cp` to introduce new config files. When you `git pull basecamp master`,
those migrations will either (a) write *through* the symlink into the source
repo, or (b) replace the symlink with a real directory. On top of that,
`omarchy-refresh-config` is intentionally a no-op in this fork, so any
migration that calls it on a brand-new config dir silently does nothing and
the new package's config ends up missing entirely.

To detect these problems automatically, this repo ships three
`omarchy-dev-*` commands and a tracked `.githooks/post-merge` hook.

### One-time setup

```bash
omarchy dev install-hooks
```

This points `core.hooksPath` at `.githooks/` and makes the hook executable.
Run it once after cloning.

### What the hook does

After every merge (including `git pull basecamp master`), the hook checks
whether new migrations were added in `ORIG_HEAD..HEAD`. If so, it runs:

```
omarchy-dev-lint-migrations --since ORIG_HEAD
```

The linter scans each new migration for `cp` / `tee` / `omarchy-refresh-config`
patterns that conflict with the symlink install and classifies them:

| Class | Meaning |
|---|---|
| `BREAKS_SYMLINK` | `cp -R` into the symlinked dir itself - would replace the symlink with a real directory. |
| `WRITES_INTO_REPO` | `cp` into a file under a symlinked dir - the write follows the symlink into the source repo working tree. |
| `MISSING_SILENT_FAIL` | `omarchy-refresh-config X/...` where `~/.config/X` isn't symlinked - the no-op silently does nothing and the user is left without the new config. |
| `MISSING_NEW_DIR` | Migration creates a new top-level entry in `~/.config/` that isn't part of the symlink set. |
| `ALREADY_SHADOWED` | Informational - `~/.config/X` is already a real dir/file (an earlier migration broke the symlink). |

### Manual invocation

```bash
# Scan all migrations not yet applied on this machine
omarchy dev lint-migrations --pending

# Scan a specific range (same as the hook does)
omarchy dev lint-migrations --since basecamp/master

# Machine-readable output (consumed by the autopatcher)
omarchy dev lint-migrations --pending --json
```

### Auto-patching with opencode

After the linter flags problem migrations, you can have `opencode` patch
them automatically. The autopatcher reuses the linter's JSON output, then
constructs a focused prompt per migration explaining the symlink contract
and the required transformation, and invokes `opencode run` to edit the
file in place.

```bash
# Walk through pending migrations interactively (default)
omarchy dev autopatch-migrations --pending

# Same range the hook lints, no prompts
omarchy dev autopatch-migrations --since basecamp/master --yes

# Preview without invoking opencode
omarchy dev autopatch-migrations --pending --dry-run
```

The autopatcher only edits files. It does NOT stage, commit, or push -
review the resulting diff with `git diff` and commit yourself.

`ALREADY_SHADOWED` findings are skipped by default (patching them on this
machine won't undo the existing shadow, but patches still help other
machines pulling from your fork). Pass `--include-shadowed` to patch them
anyway.

### Repairing `ALREADY_SHADOWED` configs

`ALREADY_SHADOWED` means `~/.config/<X>` is already a real file or directory,
but should be a symlink to `~/.local/share/omarchy/config/<X>`. The migration
patch alone won't fix your current machine; you need to move the real entry
out of the way and recreate the symlink.

The autopatcher can do this safely with a timestamped backup:

```bash
# Preview which ~/.config entries would be moved and relinked
omarchy dev autopatch-migrations --all --fix-shadowed-configs --dry-run

# Repair them interactively
omarchy dev autopatch-migrations --all --fix-shadowed-configs

# Repair without prompts
omarchy dev autopatch-migrations --all --fix-shadowed-configs --yes
```

For each shadowed entry it does:

```bash
mv ~/.config/<X> ~/.config/<X>.shadowed.<timestamp>
ln -sfn ~/.local/share/omarchy/config/<X> ~/.config/<X>
```

Use `--pending` or `--since ORIG_HEAD` when you only want to repair entries
related to newly pulled migrations. Use `--all` when cleaning up historical
drift on a machine.

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).

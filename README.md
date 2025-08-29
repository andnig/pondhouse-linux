# Omarchy

Turn a fresh Arch installation into a fully-configured, beautiful, and modern web development system based on Hyprland by running a single command. That's the one-line pitch for Omarchy (like it was for Omakub). No need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools. Omarchy is an opinionated take on what Linux can be at its best.

Read more at [omarchy.org](https://omarchy.org).

## Getting Started

Run `curl -fsSL https://pondhouse-data.com/utilities/arch/install | bash`

## Install script

An install script is hosted at [https://pondhouse-data.com/utilities/arch/install](https://pondhouse-data.com/utilities/arch/install). This script will download and run the Omarchy installer. It is recommended to review the script before running it.

Add the script in the `public/utilities/arch` directory to the pondhouse-data.com website.

# Arch Linux

On arch, we use [Omarchy](https://omarchy.org/) as a base configuration.
It provides a nice, minimal opinionated setup for Arch Linux. However, we
are not going to use it directly, as it's a bit too opinionated, so we
keep it as a git submodule and then only fetch the files we need.

## Tailscale

Use systemctl to enable and start the service:
sudo systemctl enable --now tailscaled

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

The profiles are part of the dotfiles, but you need to log in manually.

Run all of these commands once and login to the respective accounts:

```bash
chromium --profile-directory="Profile 1"
chromium --profile-directory="Profile 2"
chromium --profile-directory="Profile 3"
chromium --profile-directory="Profile 4"
```

## Syncthing

Start syncthing with `systemctl enable --now syncthing@andreas`

Open syncthing in your Pixel 6 and the web interface of the new computer on localhost:8384.
On Pixel 6, add the new device - when asked for confirmation on the new device
select "introducer" ("Verteilergeraet") - this automatically connects with all
other devices Pixel 6 is synced.
Add the shared folders on Pixel 6 as normal.
(If the web ui cant be reached, look at `systemctl status syncthing@andreas` for
info on which port the ui runs).

## Google docker

```bash
gcloud init
gcloud auth configure-docker europe-west3-docker.pkg.dev
```

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).

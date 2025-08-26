## Manual Windows VM on Arch Linux with KVM

```bash
sudo pacman -S qemu-full libvirt virt-install virt-manager virt-viewer \
    edk2-ovmf swtpm qemu-img guestfs-tools libosinfo dnsmasq -d

yay -S tuned

wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso

for drv in qemu interface network nodedev nwfilter secret storage; do \
    sudo systemctl enable virt${drv}d.service; \
    sudo systemctl enable virt${drv}d{,-ro,-admin}.socket; \
  done

sudo reboot
```

Then run this - everything needs to pass, except the last one:
If not, see this: <https://sysguides.com/install-kvm-on-linux>

```bash
sudo virt-host-validate qemu
```

Then

```bash
sudo usermod -aG libvirt $USER
```

Download Windows 11 ISO from Microsoft: <https://www.microsoft.com/software-download/windows11>
Then follow this guide: <https://sysguides.com/install-a-windows-11-virtual-machine-on-kvm>

## Quickemu

This is the better way

Run the script `omarchy-install-virt-windows`

This installs a windows 11 VM to $HOME/windows-11.conf and $HOME/windows-11.

To start the VM:

```bash
cd $HOME
quickemu --vm windows-11.conf --display spice
```

To delete a VM:

```bash
cd $HOME
quickemu --vm windows-11.conf --delete-disk --delete-vm
```

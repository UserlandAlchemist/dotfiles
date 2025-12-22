# Debian 13 (Trixie) on ZFS - Installation Guide

**Target system:** Audacious (primary workstation)
**Configuration:** ZFS RAID1 encrypted root, systemd-boot UKI, Sway desktop, dual ESP with auto-sync

---

## System layout

- **Hostname:** audacious
- **Pool:** `rpool` (ZFS mirror, aes-256-gcm encryption, zstd compression)
- **Boot:** systemd-boot with Unified Kernel Images (UKI)
- **Disks:** 2× NVMe (nvme0n1, nvme1n1)
  - 512MB ESP on each drive (mirrored via efi-sync)
  - Remaining space for ZFS mirror
- **Desktop:** Sway (Wayland)
- **User:** alchemist

---

## 1) Boot Debian Live ISO

Become root and install bootstrap tools:

```sh
sudo -i
sed -i 's/main/main contrib non-free-firmware/' /etc/apt/sources.list
apt update
apt install -y debootstrap gdisk zfsutils-linux \
               systemd-boot systemd-ukify \
               dosfstools rsync git stow
```

---

## 2) Partition disks

```sh
sgdisk --zap-all /dev/nvme0n1
sgdisk -n1:1M:+512M -t1:EF00 -c1:"EFI System" /dev/nvme0n1
sgdisk -n2:0:0     -t2:BF01 -c2:"ZFS"         /dev/nvme0n1
mkfs.vfat -F32 /dev/nvme0n1p1

sgdisk --zap-all /dev/nvme1n1
sgdisk -n1:1M:+512M -t1:EF00 -c1:"EFI System" /dev/nvme1n1
sgdisk -n2:0:0     -t2:BF01 -c2:"ZFS"         /dev/nvme1n1
mkfs.vfat -F32 /dev/nvme1n1p1
```

---

## 3) Create ZFS pool

```sh
zpool create -o ashift=12 \
  -O compression=lz4 \
  -O atime=off -O relatime=on \
  -O acltype=posixacl -O xattr=sa \
  -O encryption=aes-256-gcm -O keyformat=passphrase \
  -O mountpoint=none \
  rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2
```

**Why:** `ashift=12` matches 4K sectors. `compression=lz4` chosen over default (off) for reduced write amplification and free space savings with negligible CPU overhead on NVMe. `encryption=aes-256-gcm` provides AEAD.

Create datasets:

```sh
zfs create -o mountpoint=none                 rpool/ROOT
zfs create -o mountpoint=/ -o canmount=noauto rpool/ROOT/debian
zfs create -o mountpoint=/home                rpool/HOME
zfs create -o mountpoint=/var                 rpool/VAR
zfs create -o mountpoint=/srv                 rpool/SRV
zfs mount rpool/ROOT/debian
```

---

## 4) Bootstrap Debian

```sh
debootstrap --arch=amd64 trixie /mnt http://deb.debian.org/debian
```

Bind mounts and chroot prep:

```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
cp /etc/resolv.conf /mnt/etc/resolv.conf
chroot /mnt /bin/bash
```

---

## 5) APT sources

```ini
# /etc/apt/sources.list
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
```

```sh
apt update
```

---

## 6) Base system

```sh
apt install -y linux-image-amd64 linux-headers-amd64 \
               initramfs-tools zfs-initramfs tasksel
tasksel install standard
```

---

## 7) System identity

```sh
echo audacious > /etc/hostname
cat > /etc/hosts <<'EOF'
127.0.0.1   localhost
127.0.1.1   audacious
EOF
apt install -y locales console-setup keyboard-configuration
dpkg-reconfigure locales console-setup keyboard-configuration
```

---

## 8) User and sudo

```sh
apt install -y sudo
useradd -m -s /bin/bash alchemist
passwd alchemist
usermod -aG sudo,audio,video,input,systemd-journal alchemist
```

---

## 9) Network

**Why systemd-networkd:** Consistent with systemd-boot, no NetworkManager complexity.

```sh
apt install -y systemd-networkd systemd-resolved
systemctl enable systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

DHCP wired config (replace `Name=` with actual NIC from `ip link`):

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=enp7s0

[Network]
DHCP=yes
```

**Note:** This will be overridden by `root-network-audacious` during dotfiles deployment.

---

## 10) Firmware

```sh
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
```

For AMD CPUs: `apt install -y amd64-microcode`

---

## 11) Initramfs + UKI

**Why initramfs-tools:** Reliable ZFS encrypted pool unlocking (multiple vdevs) before import.

```ini
# /etc/kernel/install.conf
layout=uki
initrd_generator=initramfs-tools
uki_generator=ukify
```

```ini
# /etc/kernel/uki.conf
[UKI]
Cmdline=@/etc/kernel/cmdline
```

```sh
echo "root=ZFS=rpool/ROOT/debian rw quiet splash" > /etc/kernel/cmdline
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

**Note:** systemd may auto-append `systemd.machine_id=<uuid>` to the kernel cmdline at runtime.

---

## 12) systemd-boot

```sh
bootctl install
```

```ini
# /boot/efi/loader/loader.conf
default @saved
timeout 3
console-mode auto
editor no
```

Set default entry:

```sh
bootctl set-default "$(bootctl list | awk '/\.efi/{print $2; exit}')"
```

---

## 13) Dual ESP setup

Add both ESPs to fstab. Get UUIDs from `blkid /dev/nvme0n1p1 /dev/nvme1n1p1`:

```ini
# /etc/fstab
UUID=<nvme0-or-nvme1-p1>   /boot/efi        vfat  umask=0077,shortname=winnt  0  1
UUID=<nvme0-or-nvme1-p1>   /boot/efi-backup vfat  umask=0077,shortname=winnt  0  1
```

**Note:** Either NVMe can be primary; efi-sync keeps them identical. Order doesn't matter.

**Note:** `efi-sync.path` will be enabled during dotfiles deployment.

---

## 14) Desktop packages

```sh
apt install -y sway swaybg swayidle swaylock waybar wofi mako-notifier xwayland \
               grim slurp wl-clipboard xdg-desktop-portal-wlr \
               mate-polkit firefox-esr fonts-jetbrains-mono fonts-dejavu \
               pipewire-audio wireplumber pavucontrol playerctl \
               curl git stow tree profile-sync-daemon hdparm emacs lf \
               borgbackup nfs-common wakeonlan zathura
```

Autologin to TTY1:

```ini
# /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin alchemist --noclear %I $TERM
```

---

## 15) Dotfiles deployment

**Goal:** Deploy modular per-host configuration. User packages to `$HOME`, system packages to `/`. Some directories must be real (not symlinks) to hold local secrets or runtime state.

```sh
su - alchemist
cd ~/dotfiles
```

### Create real directories for secrets

```sh
mkdir -p ~/.ssh ~/.config/psd ~/.config/borg
chmod 700 ~/.ssh ~/.config/borg
```

**Why:** SSH keys and Borg passphrase are local secrets, never committed. PSD writes runtime state that shouldn't touch the repo.

Remove default profile if present:

```sh
test -f ~/.profile && mv ~/.profile ~/.profile.bak
```

### Deploy user packages

```sh
stow profile-common bash-audacious bin-audacious emacs-audacious \
     fonts-audacious foot-audacious icons-audacious lf-audacious \
     mako-audacious psd-audacious sway-audacious wallpapers-audacious \
     waybar-audacious wofi-audacious zathura-audacious ssh-audacious \
     borg-user-audacious nas-audacious pipewire-audacious mimeapps-audacious
```

Create Borg passphrase:

```sh
editor ~/.config/borg/passphrase
chmod 600 ~/.config/borg/passphrase
```

Verify:

```sh
ls -l ~/.bashrc ~/.local/bin/idle-shutdown.sh ~/.config/sway/config  # should be symlinks
test -f ~/.config/borg/passphrase && echo "OK: Borg passphrase exists"
```

### Deploy system packages

```sh
sudo stow -t / root-power-audacious root-audacious-efisync \
             root-cachyos-audacious root-network-audacious \
             root-backup-audacious root-proaudio-audacious
sudo root-sudoers-audacious/install.sh
```

**Why install.sh:** Sudoers files require `root:root 0440` ownership, which stow can't set.

Enable services:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service usb-nosuspend.service efi-sync.path
sudo systemctl enable --now borg-backup.timer borg-check.timer borg-check-deep.timer
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo sysctl --system
```

Verify:

```sh
systemctl status powertop.service efi-sync.path
systemctl list-timers | grep borg
sysctl vm.swappiness  # should return 60
ip link show enp7s0   # should be managed by networkd
```

### Package reference

| Package | Scope | Purpose |
|---------|-------|---------|
| `profile-common` | user | Shell profile baseline (shared across hosts) |
| `bash-audacious` | user | Bash config, prompt, aliases, astute helpers (nas-open/close, ssh-astute) |
| `bin-audacious` | user | Scripts: idle-shutdown, audio switching, game-performance, astute-status |
| `emacs-audacious` | user | Editor config and custom theme |
| `sway-audacious` | user | Wayland compositor: keybinds, swayidle (20min → idle-shutdown) |
| `waybar-audacious` | user | Status bar (CPU, network, audio, time) |
| `wofi-audacious` | user | Application launcher |
| `mako-audacious` | user | Notification daemon |
| `foot-audacious` | user | Terminal emulator |
| `fonts-audacious` | user | Amiga Topaz + JetBrains Mono Nerd Font |
| `icons-audacious` | user | Amiga-inspired cursor theme |
| `wallpapers-audacious` | user | Desktop backgrounds |
| `lf-audacious` | user | File manager config |
| `zathura-audacious` | user | PDF viewer config |
| `psd-audacious` | user | Profile-sync-daemon (browser profile → tmpfs) |
| `ssh-audacious` | user | SSH client config (keys excluded, see §16) |
| `borg-user-audacious` | user | Backup inclusion/exclusion patterns |
| `nas-audacious` | user | Astute NAS wake-on-demand systemd user service |
| `pipewire-audacious` | user | Audio routing and pro-audio latency config |
| `mimeapps-audacious` | user | Default applications (PDF→zathura, http→firefox) |
| `ardour-audacious` | user | DAW config (optional) |
| `root-power-audacious` | system | Powertop tuning, udev autosuspend rules, SATA power policy |
| `root-audacious-efisync` | system | Dual ESP rsync (efi-sync.path watches /boot/efi/EFI/Linux/) |
| `root-cachyos-audacious` | system | Kernel/sysctl/I/O scheduler tuning (CachyOS-derived gaming optimizations) |
| `root-network-audacious` | system | systemd-networkd wired ethernet config with MAC-based link naming |
| `root-backup-audacious` | system | Borg systemd timers (backup daily, check weekly, deep-check monthly) |
| `root-sudoers-audacious` | system | Passwordless sudo for srv-astute.mount control (NAS mounting) |
| `root-proaudio-audacious` | system | Real-time audio kernel tuning (rtprio limits, threadirqs) |

---

## 16) NAS setup (Astute integration)

**Goal:** Audacious can wake Astute on-demand for NFS storage, with automatic sleep inhibitor to prevent Astute suspending while NAS is active.

### NFS mount

Add to fstab:

```sh
echo "astute:/srv/nas  /srv/astute  nfs4  _netdev,noatime,noauto  0  0" | sudo tee -a /etc/fstab
sudo mkdir -p /srv/astute
```

**Why noauto:** Mount controlled by systemd (srv-astute.mount) triggered by `nas-open` bash function.

### SSH key for NAS inhibitor

Generate dedicated SSH key for NAS control (no passphrase, restricted command):

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_astute_nas -C "audacious to astute NAS inhibit" -N ""
```

Copy public key to encrypted USB backup key for recovery.

**On Astute**, add to `~/.ssh/authorized_keys`:

```
command="/usr/local/libexec/astute-nas-inhibit.sh",no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAA...KEY... audacious to astute NAS inhibit
```

**Why forced command:** SSH key can only toggle the sleep inhibitor, nothing else.

### Verify NAS functions

**On Audacious:**

```sh
source ~/.bashrc.d/30-astute.sh
nas-open   # wakes astute, enables inhibitor, mounts /srv/astute, cd to mount
ls         # should show NAS contents
nas-close  # unmounts, disables inhibitor, allows astute to suspend
```

Check inhibitor on Astute:

```sh
ssh astute 'systemctl status nas-inhibit.service'
```

Should show active while NAS is open, inactive after close.

---

## 17) Python toolchain (optional)

```sh
curl -Ls https://astral.sh/uv/install.sh | sh
```

Installs `uv` and `uvx` to `~/.local/bin`. Verify: `uv --version`

---

## 18) Swap (optional)

For hibernation or low-memory scenarios:

```sh
zfs create -V 8G -b 4K -o compression=off -o logbias=throughput \
  -O sync=always -O primarycache=metadata -O secondarycache=none \
  rpool/swap
mkswap /dev/zvol/rpool/swap
echo "/dev/zvol/rpool/swap none swap defaults,pri=10 0 0" >> /etc/fstab
```

**Note:** With 32GB RAM + zram, disk swap is rarely needed. Swappiness set to 60 in root-cachyos-audacious.

---

## 19) ZFS hostid

Prevent import warnings:

```sh
zgenhostid -f $(hostid)
```

---

## 20) Finalize and reboot

```sh
exit  # leave chroot
umount -Rl /mnt
zpool export rpool
reboot
```

System should:
1. Prompt for ZFS passphrase at boot
2. Boot via systemd-boot UKI
3. Autologin to TTY1 as alchemist
4. Launch Sway automatically

Verify boot:

```sh
zpool status                # both nvme devices online
bootctl list                # UKI present and set as default
systemctl --failed          # should be empty
systemctl list-timers       # borg timers scheduled
```

---

## Troubleshooting

**Boot fails to find pool:**
- See [RECOVERY.audacious.md](RECOVERY.audacious.md) for ZFS import and chroot procedures

**EFI sync not working:**
- `systemctl status efi-sync.path efi-sync.service`
- `diff -r /boot/efi/EFI/Linux /boot/efi-backup/EFI/Linux` (should be identical)

**NAS mount fails:**
- Verify astute is reachable: `ping astute`
- Check NFS server: `ssh astute 'systemctl status nfs-server'`
- Check fstab entry matches astute export

**Borg backups not running:**
- `systemctl status borg-backup.timer`
- `journalctl -u borg-backup.service -n 50`
- Verify `~/.config/borg/passphrase` exists and is readable

---

## References

- [RECOVERY.audacious.md](RECOVERY.audacious.md) - Boot and ZFS recovery procedures
- [RESTORE.audacious.md](RESTORE.audacious.md) - Full system restore from Borg backups
- [installed-software.audacious.md](installed-software.audacious.md) - Complete package list
- [Debian ZFS documentation](https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/)

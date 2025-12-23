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

## §1 Boot Debian Live ISO

Prepare the live environment with tools needed for ZFS installation.

Steps:
1. Boot the Debian 13 (Trixie) Live ISO.
2. Become root:

```sh
sudo -i
```

3. Enable contrib and non-free-firmware:

```sh
sed -i 's/main/main contrib non-free-firmware/' /etc/apt/sources.list
apt update
```

4. Install bootstrap tools:

```sh
apt install -y debootstrap gdisk zfsutils-linux \
               systemd-boot systemd-ukify \
               dosfstools rsync git stow
```

Expected result: Live environment ready with ZFS and boot tooling.

---

## §2 Partition disks

Create EFI System Partitions and ZFS partitions on both NVMe drives.

Steps:
1. Partition first NVMe:

```sh
sgdisk --zap-all /dev/nvme0n1
sgdisk -n1:1M:+512M -t1:EF00 -c1:"EFI System" /dev/nvme0n1
sgdisk -n2:0:0     -t2:BF01 -c2:"ZFS"         /dev/nvme0n1
mkfs.vfat -F32 /dev/nvme0n1p1
```

2. Partition second NVMe:

```sh
sgdisk --zap-all /dev/nvme1n1
sgdisk -n1:1M:+512M -t1:EF00 -c1:"EFI System" /dev/nvme1n1
sgdisk -n2:0:0     -t2:BF01 -c2:"ZFS"         /dev/nvme1n1
mkfs.vfat -F32 /dev/nvme1n1p1
```

Expected result: Both NVMe drives have 512MB ESP and remaining space for ZFS.

---

## §3 Create ZFS pool

Create encrypted ZFS mirror pool with optimized settings.

Steps:
1. Create the pool:

```sh
zpool create -o ashift=12 \
  -O compression=lz4 \
  -O atime=off -O relatime=on \
  -O acltype=posixacl -O xattr=sa \
  -O encryption=aes-256-gcm -O keyformat=passphrase \
  -O mountpoint=none \
  rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2
```

**Why:** `ashift=12` matches 4K sectors. `compression=lz4` reduces write amplification with negligible CPU overhead. `encryption=aes-256-gcm` provides AEAD encryption.

2. Create datasets:

```sh
zfs create -o mountpoint=none                 rpool/ROOT
zfs create -o mountpoint=/ -o canmount=noauto rpool/ROOT/debian
zfs create -o mountpoint=/home                rpool/HOME
zfs create -o mountpoint=/var                 rpool/VAR
zfs create -o mountpoint=/srv                 rpool/SRV
zfs mount rpool/ROOT/debian
```

Expected result: Pool created and root dataset mounted at /mnt.

---

## §4 Bootstrap Debian

Install minimal Debian Trixie base system into ZFS.

Steps:
1. Run debootstrap:

```sh
debootstrap --arch=amd64 trixie /mnt http://deb.debian.org/debian
```

2. Prepare chroot environment:

```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

3. Enter chroot:

```sh
chroot /mnt /bin/bash
```

Expected result: Inside chroot with network access and both ESPs mounted.

---

## §5 Configure APT sources

Set up package repositories for Debian Trixie.

Steps:
1. Create sources.list:

```ini
# /etc/apt/sources.list
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
```

2. Update package index:

```sh
apt update
```

Expected result: APT configured with Trixie repositories.

---

## §6 Install base system

Install kernel, ZFS support, and standard utilities.

Steps:
1. Install essential packages:

```sh
apt install -y linux-image-amd64 linux-headers-amd64 \
               initramfs-tools zfs-initramfs tasksel
```

2. Install standard system utilities:

```sh
tasksel install standard
```

Expected result: Bootable kernel and ZFS initramfs support installed.

---

## §7 Configure system identity

Set hostname, hosts file, and locale configuration.

Steps:
1. Set hostname:

```sh
echo audacious > /etc/hostname
```

2. Configure hosts file:

```sh
cat > /etc/hosts <<'EOF'
127.0.0.1   localhost
127.0.1.1   audacious
EOF
```

3. Install and configure locales:

```sh
apt install -y locales console-setup keyboard-configuration
dpkg-reconfigure locales console-setup keyboard-configuration
```

Expected result: System identity configured with proper locale settings.

---

## §8 Create user and enable sudo

Create the primary user account with sudo access.

Steps:
1. Install sudo:

```sh
apt install -y sudo
```

2. Create user:

```sh
useradd -m -s /bin/bash alchemist
passwd alchemist
```

3. Add user to required groups:

```sh
usermod -aG sudo,audio,video,input,systemd-journal alchemist
```

Expected result: User `alchemist` can log in and use sudo.

---

## §9 Configure network

Set up systemd-networkd for wired ethernet connectivity.

**Why systemd-networkd:** Consistent with systemd-boot philosophy, avoids NetworkManager complexity.

Steps:
1. Install networking tools:

```sh
apt install -y systemd-networkd systemd-resolved
```

2. Enable services:

```sh
systemctl enable systemd-networkd systemd-resolved
```

3. Link resolved stub:

```sh
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

4. Create wired network configuration (replace `Name=` with actual interface from `ip link`):

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=enp7s0

[Network]
DHCP=yes
```

**Note:** This will be overridden by `root-network-audacious` during dotfiles deployment.

Expected result: DHCP networking configured for primary ethernet interface.

---

## §10 Install firmware

Install AMD graphics, Intel microcode, and network card firmware.

Steps:
1. Install firmware packages:

```sh
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
```

**Note:** For AMD CPUs, also install: `apt install -y amd64-microcode`

Expected result: GPU, CPU, and NIC firmware available for hardware initialization.

---

## §11 Configure initramfs and UKI

Set up initramfs-tools to generate Unified Kernel Images for ZFS encrypted pool unlock.

**Why initramfs-tools:** Provides reliable ZFS encrypted pool unlocking with multiple vdevs.

Steps:
1. Configure kernel install layout:

```ini
# /etc/kernel/install.conf
layout=uki
initrd_generator=initramfs-tools
uki_generator=ukify
```

2. Configure UKI generator:

```ini
# /etc/kernel/uki.conf
[UKI]
Cmdline=@/etc/kernel/cmdline
```

3. Set kernel command line:

```sh
echo "root=ZFS=rpool/ROOT/debian rw quiet splash" > /etc/kernel/cmdline
```

4. Generate initramfs and UKI:

```sh
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

**Note:** systemd may auto-append `systemd.machine_id=<uuid>` to cmdline at runtime.

Expected result: UKI generated at `/boot/efi/EFI/Linux/*.efi` with ZFS unlock support.

---

## §12 Install systemd-boot

Install systemd-boot bootloader to both EFI System Partitions.

Steps:
1. Install bootloader:

```sh
bootctl install
```

2. Configure loader:

```ini
# /boot/efi/loader/loader.conf
default @saved
timeout 3
console-mode auto
editor no
```

3. Set default boot entry:

```sh
bootctl set-default "$(bootctl list | awk '/\.efi/{print $2; exit}')"
```

Expected result: systemd-boot installed and configured with generated UKI as default.

---

## §13 Configure dual ESP

Add both EFI System Partitions to fstab for redundancy.

Steps:
1. Get ESP UUIDs:

```sh
blkid /dev/nvme0n1p1 /dev/nvme1n1p1
```

2. Add to fstab (replace UUIDs with actual values):

```ini
# /etc/fstab
UUID=<nvme0-or-nvme1-p1>   /boot/efi        vfat  umask=0077,shortname=winnt  0  1
UUID=<nvme0-or-nvme1-p1>   /boot/efi-backup vfat  umask=0077,shortname=winnt  0  1
```

**Note:** Either NVMe can be primary. `efi-sync.path` keeps them identical.
**Note:** `efi-sync.path` will be enabled during dotfiles deployment.

Expected result: Both ESPs configured in fstab for automatic mounting.

---

## §14 Add third-party repositories

Configure additional package sources for Jellyfin and Prism Launcher.

Steps:
1. Set up Jellyfin repository:

```sh
mkdir -p /usr/share/keyrings
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | \
  gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/jellyfin.gpg] https://repo.jellyfin.org/debian trixie main" \
  > /etc/apt/sources.list.d/jellyfin.list
```

2. Set up Prism Launcher repository:

**Note:** The keyring must be manually installed at `/usr/share/keyrings/prismlauncher-archive-keyring.gpg` (not owned by any package).

```sh
echo "deb [signed-by=/usr/share/keyrings/prismlauncher-archive-keyring.gpg] https://prism-launcher-for-debian.github.io/repo trixie main" \
  > /etc/apt/sources.list.d/prismlauncher.list
```

3. Update package metadata:

```sh
apt update
```

Expected result: Third-party repositories configured for Jellyfin and Prism Launcher packages.

---

## §15 Install desktop environment

Install Sway compositor and essential desktop packages.

Steps:
1. Install desktop packages:

```sh
apt install -y sway swaybg swayidle swaylock waybar wofi mako-notifier xwayland \
               grim slurp wl-clipboard xdg-desktop-portal-wlr \
               mate-polkit firefox-esr fonts-jetbrains-mono fonts-dejavu \
               pipewire-audio wireplumber pavucontrol playerctl \
               curl git stow tree profile-sync-daemon hdparm emacs lf \
               borgbackup nfs-common wakeonlan zathura
```

2. Configure autologin to TTY1:

```sh
mkdir -p /etc/systemd/system/getty@tty1.service.d
```

```ini
# /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin alchemist --noclear %I $TERM
```

Expected result: Sway desktop environment installed with autologin configured.

---

## §16 Deploy dotfiles

Deploy modular per-host configuration using GNU Stow.

**Goal:** User packages to `$HOME`, system packages to `/`. Real directories for secrets.

Steps:
1. Switch to user account:

```sh
su - alchemist
cd ~/dotfiles
```

2. Create real directories for secrets:

```sh
mkdir -p ~/.ssh ~/.config/psd ~/.config/borg
chmod 700 ~/.ssh ~/.config/borg
```

**Why:** SSH keys and Borg passphrase are local secrets never committed. PSD writes runtime state.

3. Remove default profile if present:

```sh
test -f ~/.profile && mv ~/.profile ~/.profile.bak
```

4. Deploy user packages:

```sh
stow profile-common bash-audacious bin-audacious emacs-audacious \
     fonts-audacious foot-audacious icons-audacious lf-audacious \
     mako-audacious psd-audacious sway-audacious wallpapers-audacious \
     waybar-audacious wofi-audacious zathura-audacious ssh-audacious \
     borg-user-audacious nas-audacious pipewire-audacious mimeapps-audacious
```

5. Create Borg passphrase:

```sh
editor ~/.config/borg/passphrase
chmod 600 ~/.config/borg/passphrase
```

6. Verify user deployment:

```sh
ls -l ~/.bashrc ~/.local/bin/idle-shutdown.sh ~/.config/sway/config  # should be symlinks
test -f ~/.config/borg/passphrase && echo "OK: Borg passphrase exists"
```

7. Deploy system packages:

```sh
sudo stow -t / root-power-audacious root-audacious-efisync \
             root-cachyos-audacious root-network-audacious \
             root-backup-audacious root-proaudio-audacious
sudo root-sudoers-audacious/install.sh
```

**Why install.sh:** Sudoers files require `root:root 0440` ownership which stow cannot set.

8. Enable services:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service usb-nosuspend.service efi-sync.path
sudo systemctl enable --now borg-backup.timer borg-check.timer borg-check-deep.timer
sudo systemctl enable --now zfs-trim-monthly@rpool.timer
sudo systemctl enable --now zfs-scrub-monthly@rpool.timer
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo sysctl --system
```

9. Verify system deployment:

```sh
systemctl status powertop.service efi-sync.path
systemctl list-timers | grep borg
systemctl list-timers | grep zfs-trim
systemctl list-timers | grep zfs-scrub
sysctl vm.swappiness  # should return 60
ip link show enp7s0   # should be managed by networkd
```

Expected result: All dotfiles deployed, services enabled, timers scheduled.

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

## §17 Configure NAS integration

Set up wake-on-demand NFS mounting with Astute NAS server and sleep inhibitor.

**Goal:** Audacious wakes Astute on-demand for storage, prevents Astute suspension during NAS use.

Steps:
1. Add NFS mount to fstab:

```sh
echo "astute:/srv/nas  /srv/astute  nfs4  _netdev,noatime,noauto  0  0" | sudo tee -a /etc/fstab
sudo mkdir -p /srv/astute
```

**Why noauto:** Mount controlled by systemd (`srv-astute.mount`) triggered via `nas-open` function.

2. Generate dedicated SSH key for NAS control:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_astute_nas -C "audacious-nas" -N ""
```

3. Copy public key to encrypted USB for recovery.

4. On Astute, add to `~/.ssh/authorized_keys`:

```
command="/usr/local/libexec/astute-nas-inhibit.sh",restrict ssh-ed25519 AAAA...KEY... audacious-nas
```

**Why forced command:** SSH key can only toggle sleep inhibitor, nothing else.

5. Test NAS functions:

```sh
source ~/.bashrc.d/50-nas-helpers.sh
nas-open   # wakes astute, enables inhibitor, mounts /srv/astute
ls /srv/astute
nas-close  # unmounts, disables inhibitor
```

6. Verify inhibitor on Astute:

```sh
ssh astute 'systemctl status nas-inhibit.service'
```

Expected result: NAS wake-on-demand working, inhibitor active during use, inactive after close.

---

## §18 Install Python toolchain

Install uv for modern Python package management.

Steps:
1. Install uv:

```sh
curl -Ls https://astral.sh/uv/install.sh | sh
```

2. Verify installation:

```sh
uv --version
```

Expected result: `uv` and `uvx` available in `~/.local/bin`.

---

## §19 Configure swap

Create ZFS swap volume for hibernation or low-memory scenarios.

Steps:
1. Create swap zvol:

```sh
zfs create -V 8G -b 4K -o compression=off -o logbias=throughput \
  -O sync=always -O primarycache=metadata -O secondarycache=none \
  rpool/swap
```

2. Format and enable swap:

```sh
mkswap /dev/zvol/rpool/swap
echo "/dev/zvol/rpool/swap none swap defaults,pri=10 0 0" >> /etc/fstab
```

**Note:** With 32GB RAM + zram, disk swap is rarely needed. Swappiness set to 60 in `root-cachyos-audacious`.

Expected result: 8GB swap volume available for low-memory conditions.

---

## §20 Set ZFS hostid

Prevent pool import warnings by setting consistent hostid.

Steps:
1. Generate hostid:

```sh
zgenhostid -f $(hostid)
```

Expected result: `/etc/hostid` created, prevents ZFS import warnings.

---

## §21 Finalize and reboot

Exit chroot, export pool, and boot into new system.

Steps:
1. Exit chroot:

```sh
exit
```

2. Unmount and export:

```sh
umount -Rl /mnt
zpool export rpool
```

3. Reboot:

```sh
reboot
```

4. After reboot, verify system:

```sh
zpool status                # both nvme devices online
bootctl list                # UKI present and set as default
systemctl --failed          # should be empty
systemctl list-timers       # borg timers scheduled
```

Expected result: System boots via systemd-boot UKI, prompts for ZFS passphrase, autologins to Sway.

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

# Debian 13 (Trixie) ZFS Root Install Guide

This guide installs Debian with:
- Root on **ZFS** (RAID1, encryption, compression, snapshots).
- **systemd-boot** with **UKI** (unified kernel image).
- Dual **EFI System Partitions (ESP)** with automatic syncing.
- Sway desktop + dotfiles.
- Includes **kernel, headers, initramfs-tools, zfs-initramfs, and tasksel standard** (what the Debian Installer normally provides).

---

## System assumptions

- Root pool is `rpool` (ZFS mirror with encryption).
- Two EFI partitions: `/dev/nvme0n1p1` (primary) and `/dev/nvme1n1p1` (backup).
- Boot managed by **systemd-boot** with **UKI (unified kernel image)**.

---

## 1) Boot into Debian Live ISO

Open a terminal, become root, enable contrib/non-free-firmware, and install tools:

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

Two identical NVMe drives, each with:
- 512M **ESP**
- Remaining space for **ZFS**

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

## 3) Create ZFS pool + datasets

```sh
zpool create -o ashift=12 \
  -O compression=zstd \
  -O atime=off -O relatime=on \
  -O acltype=posixacl -O xattr=sa \
  -O encryption=aes-256-gcm -O keyformat=passphrase \
  -O mountpoint=none \
  rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2
```

Datasets:

```sh
zfs create -o mountpoint=none                 rpool/ROOT
zfs create -o mountpoint=/ -o canmount=noauto rpool/ROOT/debian
zfs create -o mountpoint=/home                rpool/HOME
zfs create -o mountpoint=/var                 rpool/VAR
zfs create -o mountpoint=/srv                 rpool/SRV
```

Mount root:

```sh
zfs mount rpool/ROOT/debian
```

---

## 4) Bootstrap Debian into /mnt

```sh
debootstrap --arch=amd64 trixie /mnt http://deb.debian.org/debian
```

Bind mounts + mount ESPs + DNS:

```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

Chroot:

```sh
chroot /mnt /bin/bash
```

---

## 5) APT sources (inside chroot)

```ini
# /etc/apt/sources.list
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free-firmware

deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free-firmware

# Optional:
# deb http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
# deb-src http://deb.debian.org/debian trixie-backports main contrib non-free-firmware
```

```sh
apt update
```

---

## 6) Base system, kernel, initramfs, ZFS hooks, and “standard” task

Install what the Debian Installer would have pulled in:

```sh
apt install -y linux-image-amd64 linux-headers-amd64 \
               systemd-sysv initramfs-tools \
               zfs-initramfs tasksel
```

Install the “standard system utilities” task:

```sh
tasksel install standard
```

*(Brings in man-db, less, cron, logrotate, etc.)*

---

## 7) Hostname, hosts, locales, keyboard

```sh
echo audacious > /etc/hostname

cat > /etc/hosts <<'EOF'
127.0.0.1   localhost
127.0.1.1   audacious
EOF

apt install -y locales console-setup keyboard-configuration
dpkg-reconfigure locales
dpkg-reconfigure console-setup
dpkg-reconfigure keyboard-configuration
```

---

## 8) User + sudo

```sh
apt install -y sudo
useradd -m -s /bin/bash alchemist
passwd alchemist
usermod -aG sudo,audio,video,input,systemd-journal alchemist
```

---

## 9) Networking (systemd-networkd + resolved)

```sh
apt install -y systemd-networkd systemd-resolved
systemctl enable systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

DHCP for your wired NIC (edit `Name=` to match, e.g., `enp7s0`):

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=enp7s0

[Network]
DHCP=yes
```

---

## 10) Firmware + microcode (only what you need)

```sh
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
# If your CPU is AMD, use: apt install -y amd64-microcode
```

---

## 11) Initramfs + UKI (systemd-boot flow)

Config:

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

Kernel cmdline:

```sh
echo "root=ZFS=rpool/ROOT/debian rw quiet splash" > /etc/kernel/cmdline
```

Build initramfs + UKI:

```sh
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

---

## 12) Install and set up systemd-boot

```sh
bootctl install
```

Loader defaults:

```ini
# /boot/efi/loader/loader.conf
default @saved
timeout 3
console-mode auto
editor no
```

Make the latest UKI default:

```sh
bootctl set-default "$(bootctl list | awk '/\.efi/{print $2; exit}')"
```

Clean any stray live-ISO Type #1 entries in `/boot/efi/loader/entries/` that contain `boot=live` or `findiso=`.

---

## 13) Dual ESPs in fstab + auto-sync

```ini
# /etc/fstab
UUID=3F75-5F0D   /boot/efi        vfat  umask=0077,shortname=winnt  0  1
UUID=3F49-829B   /boot/efi-backup vfat  umask=0077,shortname=winnt  0  1
```

ESP sync units:

```ini
# /etc/systemd/system/efi-sync.service
[Unit]
Description=Sync primary ESP to backup ESP
Requires=boot-efi.mount boot-efi-backup.mount
After=boot-efi.mount boot-efi-backup.mount

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -a --delete /boot/efi/ /boot/efi-backup/
```

```ini
# /etc/systemd/system/efi-sync.path
[Unit]
Description=Trigger ESP sync when kernel-install updates UKIs

[Path]
PathChanged=/boot/efi/EFI/
Unit=efi-sync.service

[Install]
WantedBy=multi-user.target
```

Enable:

```sh
systemctl enable --now efi-sync.path
```

---

## 14) Sway desktop + tools

```sh
apt install -y sway swaybg swayidle swaylock waybar wofi mako-notifier xwayland \
               grim slurp wl-clipboard xdg-desktop-portal-wlr \
               mate-polkit firefox-esr fonts-jetbrains-mono fonts-dejavu \
               pipewire-audio wireplumber pavucontrol \
               curl usb.ids git stow tree profile-sync-daemon hdparm
```

Autologin to Sway:

```ini
# /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin alchemist --noclear %I $TERM
```

```sh
install -d -m 0755 /home/alchemist
chown alchemist:alchemist /home/alchemist

# Start sway on TTY1
su - alchemist -c 'printf "%s\n" '\''if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec sway; fi'\'' > ~/.bash_profile'
```

---
## 15) Dotfiles

Clone and apply configuration using GNU Stow.

    su - alchemist
    git clone https://github.com/UserlandAlchemist/dotfiles ~/dotfiles
    cd ~/dotfiles

### 15.1 User configuration

Use Stow to deploy user-level packages:

    stow bash bin emacs fonts foot lf mako sway waybar wofi zathura

These symlink dotfiles from `~/dotfiles` into the home directory (`~`). Stow automatically creates or replaces the appropriate symlinks.

Note:
- Some directories (like `wallpapers/`, `icons/`, and `ssh/`) are NOT stowed — see their individual README.md files for manual setup instructions.
- The `fonts/` and `icons/` stow packages install under `~/.local/share/`, preserving the standard XDG layout.
- `wallpapers/` provides wallpaper assets only. You manually link those into `~/Pictures/Wallpapers/`.

### 15.2 System configuration (optional, requires sudo)

System-level tuning packages can be applied selectively as needed:

    sudo stow -t / etc-cachyos etc-power etc-systemd etc-udev

Then reload the relevant subsystems:

    sudo sysctl --system
    sudo udevadm control --reload
    sudo udevadm trigger

These stow packages provide:
- `etc-cachyos`: kernel and sysctl tuning
- `etc-power`: power management and USB suspend rules
- `etc-systemd`: custom systemd units and timers (efi-sync, powertop, usb-nosuspend, etc.)
- `etc-udev`: device-specific tweaks

### 15.3 Initial adoption (one-time only)

If you're converting an already-running machine to use this dotfiles repo (i.e. "take ownership" of existing config files), run:

    stow --adopt bash bin ...

Then commit the adopted files:

    git add -A && git commit -m "adopt host configs"

This is not needed on a fresh install. It's only for migrating an existing host into this layout.

### 15.4 Post-stow verification

After applying dotfiles, verify the environment:

User services (Wayland session / desktop pieces):

    systemctl --user list-units | grep -E 'mako|waybar|swayidle'

System services (root-level units shipped in dotfiles):

    systemctl list-units | grep -E 'efi-sync|powertop|usb-nosuspend'

At this point:
- sway should autostart on TTY1 (see Section 14 for autologin config)
- notifications should work (`mako-notifier`)
- EFI sync should keep `/boot/efi` and `/boot/efi-backup` in sync
- power tuning should be applied

---

## 16) Swap (optional safety net)

Keep zram primary and add a small fallback ZFS zvol swap with lower priority:

```sh
zfs create -V 8G -b 4K -o compression=off -o logbias=throughput \
  -o sync=always -o primarycache=metadata -o secondarycache=none \
  rpool/swap
mkswap /dev/zvol/rpool/swap
echo "/dev/zvol/rpool/swap none swap defaults,pri=10 0 0" >> /etc/fstab
```

Ensure zram has higher priority (e.g., 100). Check with `swapon`.

---

## 17) Avoid ZFS hostid import warnings

```sh
zgenhostid -f $(hostid)
```

---

## 18) Finalize and reboot

```sh
exit
umount -Rl /mnt
zpool export rpool
reboot
```

You should get Plymouth unlock → systemd-boot → autologin → Sway.

---

## Appendix: sysctl notes (swappiness)

Debian’s documented default is **60**. If you ever see a different runtime value and want predictability, pin it:

```ini
# /etc/sysctl.d/99-gaming-desktop-settings.conf
# vm.swappiness = 100   # CachyOS assumes zram; aggressive swapping
vm.swappiness = 60       # Balanced for Debian desktop w/ zram; keep hot pages in RAM
```

Apply: `sudo sysctl --system`.

---

**See also:**
- [`RECOVERY.md`](RECOVERY.md) — system recovery procedure (referencing this install guide for rebuild steps)
- [`installed-software.md`](installed-software.md) — manually installed packages and rationale
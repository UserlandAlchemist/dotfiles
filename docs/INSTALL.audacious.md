# Debian 13 (Trixie) ZFS Root Install Guide

This guide installs Debian with:
- Root on **ZFS** (RAID1, encryption, compression, snapshots)
- **systemd-boot** with **UKI** (unified kernel image)
- Dual **EFI System Partitions (ESP)** with automatic syncing
- Sway desktop + dotfiles
- Includes **kernel, headers, initramfs-tools, zfs-initramfs, and tasksel standard** (equivalent to the Debian Installer's standard system)

---

## System assumptions

- Root pool is `rpool` (ZFS mirror with encryption)
- Two EFI partitions: `/dev/nvme0n1p1` (primary) and `/dev/nvme1n1p1` (backup)
- Boot managed by **systemd-boot** with **UKI (unified kernel image)**

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

Each NVMe drive:
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

## 3) Create ZFS pool and datasets

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

Bind mounts, ESPs, and DNS:

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
```

```sh
apt update
```

---

## 6) Base system, kernel, initramfs, and standard task

```sh
apt install -y linux-image-amd64 linux-headers-amd64 \
               systemd-sysv initramfs-tools \
               zfs-initramfs tasksel

tasksel install standard
```

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

DHCP config (replace `Name=` with your NIC, e.g. `enp7s0`):

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=enp7s0

[Network]
DHCP=yes
```

---

## 10) Firmware + microcode

```sh
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
# For AMD CPUs: apt install -y amd64-microcode
```

---

## 11) Initramfs + UKI setup

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

---

## 12) Install and configure systemd-boot

```sh
bootctl install
```

Loader config:

```ini
# /boot/efi/loader/loader.conf
default @saved
timeout 3
console-mode auto
editor no
```

Make latest UKI default:

```sh
bootctl set-default "$(bootctl list | awk '/\.efi/{print $2; exit}')"
```

---

## 13) Dual ESPs and auto-sync

```ini
# /etc/fstab
UUID=XXXX-YYYY   /boot/efi        vfat  umask=0077,shortname=winnt  0  1
UUID=AAAA-BBBB   /boot/efi-backup vfat  umask=0077,shortname=winnt  0  1
```

Enable the ESP sync units:

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
               curl usb.ids git stow tree profile-sync-daemon hdparm emacs
```

Autologin:

```ini
# /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin alchemist --noclear %I $TERM
```

---

## 15) Dotfiles setup

```sh
su - alchemist
cd ~/dotfiles
```

### 15.1 User configuration

Apply user-level configuration:

    stow bash bin emacs fonts foot lf mako sway waybar wofi zathura

These stow packages link into `$HOME` using XDG-compliant paths. Optional:
- `wallpapers/`, `icons/`, and `ssh/` include assets and configs to review manually.

---

### 15.2 System configuration (requires sudo)

Apply system-level stow packages selectively.

#### Power management

    sudo stow --target=/ etc-power
    sudo systemctl daemon-reload
    sudo systemctl enable --now powertop.service usb-nosuspend.service
    sudo udevadm control --reload-rules
    sudo udevadm trigger

#### EFI sync (dual ESPs)

    sudo stow --target=/ etc-systemd
    sudo systemctl daemon-reload
    sudo systemctl enable --now efi-sync.path

#### Kernel/sysctl tuning

    sudo stow --target=/ etc-cachyos
    sudo sysctl --system

#### BorgBackup timers

    sudo stow --target=/ backup-systemd
    sudo systemctl daemon-reload
    sudo systemctl enable --now \
        borg-backup.timer \
        borg-check.timer \
        borg-check-deep.timer

Ensure `borg-user/` is stowed for your user and contains `~/.config/borg/passphrase`.

---

### 15.3 Verification

Check services:

    systemctl list-units | grep -E 'efi-sync|powertop|usb-nosuspend|borg'

Confirm:
- EFI sync mirrors `/boot/efi` and `/boot/efi-backup`
- powertop and usb-nosuspend apply power tuning
- borg timers appear under:

      systemctl list-timers | grep borg

---

### 15.4 Post-stow checks

    systemctl --user list-units | grep -E 'mako|waybar|swayidle'

Ensure:
- Sway autostarts on TTY1
- mako notifications work
- EFI sync and power tuning are active

---

### 15.5 Install uv (Python toolchain manager)

```bash
curl -Ls https://astral.sh/uv/install.sh | sh
```

This installs `uv` and `uvx` to `~/.local/bin`. Confirm with `uv --version`.

---

## 16) Swap (optional)

```sh
zfs create -V 8G -b 4K -o compression=off -o logbias=throughput \
  -o sync=always -o primarycache=metadata -o secondarycache=none \
  rpool/swap
mkswap /dev/zvol/rpool/swap
echo "/dev/zvol/rpool/swap none swap defaults,pri=10 0 0" >> /etc/fstab
```

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

System should unlock, boot via systemd-boot, and autologin to Sway.

---

## Appendix: sysctl notes

```ini
# /etc/sysctl.d/99-gaming-desktop-settings.conf
vm.swappiness = 60
```

Apply with `sudo sysctl --system`.

---

**References:**
- [RECOVERY.md](RECOVERY.md)
- [installed-software.md](installed-software.md)


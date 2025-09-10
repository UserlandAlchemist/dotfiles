# Debian 13 (Trixie) ZFS Root Install Guide

This guide installs Debian with:
- Root on ZFS (RAID1, encryption, compression, snapshots).
- systemd-boot with UKI.
- Dual EFI System Partitions (ESP) with auto-sync.
- Sway desktop and dotfiles.

---

## 1. Boot into Debian Live ISO
```sh
sudo -i
sed -i 's/main/main contrib non-free-firmware/' /etc/apt/sources.list
apt update
apt install -y debootstrap gdisk zfs-dkms zfsutils-linux \
               systemd-boot systemd-ukify \
               dosfstools rsync git stow
```

---

## 2. Partition disks
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

## 3. Create ZFS pool
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
zfs create -o mountpoint=none                rpool/ROOT
zfs create -o mountpoint=/ -o canmount=noauto rpool/ROOT/debian
zfs create -o mountpoint=/home               rpool/HOME
zfs create -o mountpoint=/var                rpool/VAR
zfs create -o mountpoint=/srv                rpool/SRV
```

Mount root:
```sh
zfs mount rpool/ROOT/debian
```

---

## 4. Bootstrap Debian
```sh
debootstrap --arch=amd64 trixie /mnt http://deb.debian.org/debian
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

## 5. Base system config
Set hostname:
```sh
echo audacious > /etc/hostname
```

`/etc/hosts`:
```
127.0.0.1   localhost
127.0.1.1   audacious
```

Locales and keyboard:
```sh
apt install -y locales console-setup keyboard-configuration
dpkg-reconfigure locales
dpkg-reconfigure console-setup
dpkg-reconfigure keyboard-configuration
```

User + sudo:
```sh
apt install -y sudo
useradd -m -s /bin/bash alchemist
passwd alchemist
usermod -aG sudo alchemist
```

---

## 6. Networking
```sh
apt install -y systemd-networkd systemd-resolved
systemctl enable systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

`/etc/systemd/network/20-wired.network`:
```
[Match]
Name=enp7s0

[Network]
DHCP=yes
```

---

## 7. Firmware + microcode
```sh
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
```
*(swap `intel-microcode` → `amd64-microcode` if CPU is AMD)*

---

## 8. Initramfs + UKI
`/etc/kernel/install.conf`:
```
layout=uki
initrd_generator=initramfs-tools
uki_generator=ukify
```

`/etc/kernel/uki.conf`:
```
[UKI]
Cmdline=@/etc/kernel/cmdline
```

`/etc/kernel/cmdline`:
```
root=ZFS=rpool/ROOT/debian rw quiet splash
```

Rebuild:
```sh
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

---

## 9. systemd-boot
```sh
bootctl install
```

`/boot/efi/loader/loader.conf`:
```
default @saved
timeout 3
console-mode auto
editor no
```

Set default:
```sh
bootctl set-default "$(bootctl list | awk '/.efi/{print $2; exit}')"
```

---

## 10. Dual ESP sync
`/etc/fstab`:
```
UUID=3F75-5F0D   /boot/efi        vfat  umask=0077,shortname=winnt  0  1
UUID=3F49-829B   /boot/efi-backup vfat  umask=0077,shortname=winnt  0  1
```

`/etc/systemd/system/efi-sync.service`:
```
[Unit]
Description=Sync primary ESP to backup ESP
Requires=boot-efi.mount boot-efi-backup.mount
After=boot-efi.mount boot-efi-backup.mount

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -a --delete /boot/efi/ /boot/efi-backup/
```

`/etc/systemd/system/efi-sync.path`:
```
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

## 11. Userland stack
```sh
apt install -y sway swaybg swayidle swaylock waybar wofi mako xwayland \
               grim slurp wl-clipboard xdg-desktop-portal-wlr \
               mate-polkit firefox-esr fonts-jetbrains-mono fonts-dejavu \
               pipewire-audio wireplumber pavucontrol \
               curl usb.ids git stow tree profile-sync-daemon
```

Autologin:
`/etc/systemd/system/getty@tty1.service.d/override.conf`:
```
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin alchemist --noclear %I $TERM
```

`~/.bash_profile`:
```sh
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec sway
fi
```

---

## 12. Dotfiles
```sh
su - alchemist
git clone https://github.com/UserlandAlchemist/dotfiles ~/dotfiles
cd ~/dotfiles
stow --adopt bash bin emacs fonts foot icons mako sway wallpapers waybar wofi
git add -A && git commit -m "adopt host configs"
```

---

## 13. Final cleanup
Fix ZFS hostid:
```sh
zgenhostid -f $(hostid)
```

Exit and reboot:
```sh
exit
umount -Rl /mnt
zpool export rpool
reboot
```

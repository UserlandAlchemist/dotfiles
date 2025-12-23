# Debian 13 (Trixie) on ZFS - Recovery Guide

**Purpose:** Restore bootability for audacious (ZFS root, systemd-boot UKI).
**Scope:** ZFS import, chroot, initramfs/UKI rebuild, bootloader repair, service sanity.
**Not covered:** Borg or user data recovery (see `RESTORE.audacious.md`).

---

## §1 Boot live environment

Use a Debian 13 Live ISO to get a clean rescue shell.

Steps:
1. Boot the Debian 13 Live ISO.
2. Become root:

```sh
sudo -i
```

3. Install recovery tools:

```sh
apt update
apt install -y zfsutils-linux gdisk systemd-boot systemd-ukify \
  dosfstools rsync git stow
```

4. Verify disks and EFI partitions:

```sh
lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
```

Expected result: both NVMe disks and their EFI partitions are visible.

---

## §2 Import and mount ZFS pool

Import the encrypted ZFS root pool and mount datasets.

Steps:
1. Detect pools:

```sh
zpool import
```

2. Import the pool (encrypted, read-write):

```sh
zpool import -l rpool
```

3. Mount datasets:

```sh
zfs mount rpool/ROOT/debian
zfs mount -a
```

4. Verify mount layout:

```sh
mount | grep rpool
```

Expected result: `rpool/ROOT/debian` is mounted at `/mnt` and datasets are mounted.

---

## §3 Mount system for chroot

Prepare a full chroot with kernel, devices, and EFI mounts.

Steps:
1. Bind standard virtual filesystems:

```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
```

2. Mount EFI partitions:

```sh
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
```

3. Copy DNS resolver config:

```sh
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

4. Enter the chroot:

```sh
chroot /mnt /bin/bash
```

Expected result: a root shell inside the installed system.

---

## §4 Basic checks (inside chroot)

Confirm the system view is consistent before rebuilding boot assets.

Steps:
1. Check hostname and network:

```sh
hostname
systemctl status systemd-networkd systemd-resolved
```

2. Check ZFS health:

```sh
zpool status
zfs list
```

3. Confirm root mount:

```sh
mount | grep ' / '
```

4. Verify APT sources:

```sh
grep -v '^#' /etc/apt/sources.list
apt update
```

Expected result: ZFS pool is healthy and APT metadata refreshes.

---

## §5 Rebuild initramfs and UKI

Use this for kernel or initramfs boot failures.

Steps:
1. Confirm kernel and UKI config files:

```sh
uname -r
cat /etc/kernel/cmdline
cat /etc/kernel/install.conf
cat /etc/kernel/uki.conf
```

2. Rebuild initramfs and UKI:

```sh
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

3. Verify UKI output:

```sh
ls -lh /boot/efi/EFI/Linux/*.efi
```

Expected result: a fresh UKI exists in `/boot/efi/EFI/Linux/`.

---

## §6 Repair systemd-boot and ESP sync

Use this if EFI entries are missing or corrupted.

Steps:
1. Reinstall systemd-boot:

```sh
bootctl install
```

2. Verify loader configuration:

```sh
cat /boot/efi/loader/loader.conf
```

Expected minimal contents:

```
default @saved
timeout 3
console-mode auto
editor no
```

3. List EFI entries and verify UKI:

```sh
bootctl list
```

4. Set latest UKI as default:

```sh
bootctl set-default "$(bootctl list | awk '/\\.efi/{print $2; exit}')"
```

5. Verify ESP sync:

```sh
diff -rq /boot/efi /boot/efi-backup || echo "ESP copies differ!"
```

If out of sync:

```sh
systemctl restart efi-sync.path
rsync -aHAXv /boot/efi/ /boot/efi-backup/
```

Expected result: both ESPs contain identical UKIs.

---

## §7 Restore services from dotfiles

Reapply stowed system configs and restart critical services.

Steps:
1. Restow system packages:

```sh
cd /home/alchemist/dotfiles
sudo stow -t / root-power-audacious root-efisync-audacious \
  root-cachyos-audacious root-network-audacious \
  root-backup-audacious root-proaudio-audacious
sudo root-sudoers-audacious/install.sh
```

2. Reload systemd and enable services:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service usb-nosuspend.service efi-sync.path
sudo systemctl enable --now borg-backup.timer borg-check.timer borg-check-deep.timer
sudo systemctl enable --now zfs-trim-monthly@rpool.timer
sudo systemctl enable --now zfs-scrub-monthly@rpool.timer
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo sysctl --system
```

3. Verify services:

```sh
systemctl list-units | grep -E 'powertop|usb-nosuspend|efi-sync|borg'
```

Expected result: core services are active with no failures.

---

## §8 Exit, unmount, reboot

Leave the chroot and cleanly unmount before rebooting.

Steps:
1. Exit chroot:

```sh
exit
```

2. Unmount and export pool:

```sh
umount -Rl /mnt
zpool export rpool
```

3. Reboot:

```sh
reboot
```

Expected result: system prompts for ZFS passphrase and boots.

---

## §9 Optional repairs

Use these only when the standard flow fails.

Steps:
1. Import pool with altroot:

```sh
zpool import -f -l -o altroot=/mnt rpool
```

2. Scrub a degraded pool:

```sh
zpool status
zpool scrub rpool
```

3. Refresh bootloader:

```sh
bootctl update
```

Expected result: pool imports and bootloader metadata is current.

---

## §10 Post-recovery checks

Confirm the system is stable after boot.

Steps:
1. Verify ZFS and services:

```sh
zpool status
systemctl list-units | grep -E 'efi-sync|powertop|borg'
```

Expected result: ZFS is healthy and timers are active.

---

## References

- `RESTORE.audacious.md` for Borg restores

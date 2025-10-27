# RECOVERY.md — Debian 13 (Trixie) ZFS + systemd-boot Emergency Checklist

> **Purpose:** Get `audacious` booting again after something breaks.  
> Focus: ZFS import, chroot, UKI + bootloader rebuild, and system service sanity.  
> Not for Borg or user data recovery — see `RESTORE.md` for that.

---

## 🧭 Quick Reference — Symptoms → Actions

| Symptom | Action |
|----------|--------|
| System drops to initramfs shell | Go to §2 (Import ZFS pool manually) |
| ZFS pool not found or degraded | Go to §2 (Import and scrub pool) |
| Boots to blank screen or kernel panic | Go to §5 (Rebuild initramfs + UKI) |
| systemd-boot missing or EFI errors | Go to §6 (Reinstall bootloader + re-sync ESPs) |
| Power/EFI sync services not running | Go to §7 (Restow configs and restart services) |

---

## 1️⃣ Boot Environment Setup

1. Boot from the **Debian 13 Live ISO**.
2. Open a terminal and become root:

```bash
sudo -i
```

3. Install tools:

```bash
apt update
apt install -y zfsutils-linux gdisk systemd-boot systemd-ukify dosfstools rsync git stow
```

4. Verify both disks and EFI partitions:

```bash
lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
```

---

## 2️⃣ Import and Mount ZFS Pool

1. Check ZFS devices:

```bash
zpool import
```

2. Import pool (read-write, encrypted):

```bash
zpool import -l rpool
```

> If it says "no pools available", confirm with `ls /dev/disk/by-id` that both drives exist.

3. Mount datasets:

```bash
zfs mount rpool/ROOT/debian
zfs mount -a
```

4. Verify mount layout:

```bash
mount | grep rpool
```

---

## 3️⃣ Mount System for chroot

1. Mount standard virtual filesystems:

```bash
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
```

2. Mount EFI partitions:

```bash
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
```

3. Copy DNS resolution:

```bash
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

4. Enter the chroot:

```bash
chroot /mnt /bin/bash
```

---

## 4️⃣ Basic System Checks (inside chroot)

1. Confirm hostname and network:

```bash
echo $(hostname)
systemctl status systemd-networkd systemd-resolved
```

2. Check ZFS and mount health:

```bash
zpool status
zfs list
```

3. Check root filesystem integrity:

```bash
mount | grep ' / '
```

4. Ensure APT sources are valid:

```bash
grep -v '^#' /etc/apt/sources.list
apt update
```

---

## 5️⃣ Rebuild initramfs and UKI

> Use this when kernel updates break boot, or you see initramfs errors.

1. Confirm kernel version:

```bash
uname -r
```

2. Ensure kernel config files exist:

```bash
cat /etc/kernel/cmdline
cat /etc/kernel/install.conf
cat /etc/kernel/uki.conf
```

3. Rebuild initramfs + UKI:

```bash
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

4. Verify UKI is present:

```bash
ls -lh /boot/efi/EFI/Linux/*.efi
```

---

## 6️⃣ Reinstall or Repair systemd-boot

> Use when EFI boot entry or loader files are missing or corrupted.

1. Reinstall systemd-boot:

```bash
bootctl install
```

2. Check loader config:

```bash
cat /boot/efi/loader/loader.conf
```

Expected minimal contents:

```
default @saved
timeout 3
console-mode auto
editor no
```

3. List EFI entries and verify UKI presence:

```bash
bootctl list
```

4. Set latest UKI as default:

```bash
bootctl set-default "$(bootctl list | awk '/\.efi/{print $2; exit}')"
```

5. Confirm both ESPs are synced:

```bash
diff -rq /boot/efi /boot/efi-backup || echo "ESP copies differ!"
```

If out of sync:

```bash
systemctl restart efi-sync.path
rsync -aHAXv /boot/efi/ /boot/efi-backup/
```

---

## 7️⃣ Verify Power and System Services

> If power management or sync services stopped working after recovery.

1. Restow configs:

```bash
cd /home/alchemist/dotfiles
sudo stow --target=/ etc-power-audacious
sudo stow --target=/ etc-systemd-audacious
sudo stow --target=/ etc-cachyos-audacious
sudo stow --target=/ backup-systemd-audacious
```

2. Reload systemd and enable services:

```bash
systemctl daemon-reload
systemctl enable --now powertop.service usb-nosuspend.service efi-sync.path \
    borg-backup.timer borg-check.timer borg-check-deep.timer
```

3. Reload udev rules:

```bash
udevadm control --reload-rules
udevadm trigger
```

4. Confirm services:

```bash
systemctl list-units | grep -E 'powertop|usb-nosuspend|efi-sync|borg'
```

---

## 8️⃣ Exit, Unmount, and Reboot

1. Exit chroot:

```bash
exit
```

2. Unmount cleanly:

```bash
umount -Rl /mnt
zpool export rpool
```

3. Reboot:

```bash
reboot
```

---

## 🧰 Optional: Repair ZFS or Boot Issues

If ZFS won't import:

```bash
zpool import -f -l -o altroot=/mnt rpool
```

If the pool is degraded:

```bash
zpool status
zpool scrub rpool
```

If systemd-boot fails to find entries:

```bash
bootctl update
```

---

## ✅ Post-Recovery Checklist

After boot:

```bash
zpool status
systemctl list-units | grep -E 'efi-sync|powertop|borg'
```

If all active and no errors — recovery complete.

---

**Next:** Restore Borg backups and verify user data — see [`RESTORE.md`](RESTORE.md).


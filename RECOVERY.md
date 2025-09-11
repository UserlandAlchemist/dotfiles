# Debian ZFS Root Recovery Guide

This guide assumes:
- You booted from a **Debian 13 (Trixie) Live ISO**.
- Root pool is called `rpool`.
- Two EFI partitions: `/dev/nvme0n1p1` (primary) and `/dev/nvme1n1p1` (backup).

---

## 1) Install required packages in the live ISO

```sh
sudo -i
sed -i 's/main/main contrib non-free-firmware/' /etc/apt/sources.list
apt update
apt install -y debootstrap gdisk zfs-dkms zfsutils-linux \
               build-essential dkms linux-headers-$(uname -r) \
               systemd-boot systemd-ukify \
               dosfstools rsync
```

---

## 2) Import ZFS pool

```sh
modprobe zfs
zpool import -f -R /mnt rpool
zfs mount rpool/ROOT/debian
zfs mount -a
```

Check:

```sh
zfs list -o name,mountpoint,mounted
```

Root should be at `/mnt`.

---

## 3) Mount system dirs + ESPs

```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

---

## 4) Chroot into system

```sh
chroot /mnt /bin/bash
```

---

## 5) Fix APT inside chroot

Ensure proper sources:

```ini
# /etc/apt/sources.list
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free-firmware

deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
```

Update + fix broken packages if needed:

```sh
apt update
apt --fix-broken install
```

---

## 6) Kernel + ZFS tooling

Reinstall the kernel, headers, initramfs, and ZFS support:

```sh
apt install --reinstall -y linux-image-amd64 linux-headers-amd64 \
                          initramfs-tools zfs-initramfs
```

Regenerate initramfs + UKI:

```sh
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

---

## 7) Reinstall systemd-boot if needed

```sh
bootctl install
bootctl list
```

- Ensure only your UKI entry remains (Type #2 `.efi`).  
- If old “live” entries are still present in `/boot/efi/loader/entries/`, delete them.

---

## 8) Verify ESP sync service

Ensure `efi-sync.service` and `efi-sync.path` exist in `/etc/systemd/system`.

```sh
systemctl enable --now efi-sync.path
```

---

## 9) Fix networking (if broken)

```sh
systemctl enable systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

Check your `/etc/systemd/network/20-wired.network` for correct NIC name.

---

## 10) Firmware + microcode

Reinstall if missing:

```sh
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
# Or amd64-microcode if AMD CPU
```

---

## 11) Hostid

Avoid ZFS import warnings:

```sh
zgenhostid -f $(hostid)
```

---

## 12) Swap check

Ensure zram is primary, zvol swap secondary:

```sh
swapon
```

You should see:
```
/dev/zram0   ... PRIO=100
/dev/zd0     ... PRIO=10
```

---

## 13) Exit + reboot

```sh
exit
umount -Rl /mnt
zpool export rpool
reboot
```

---

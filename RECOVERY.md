# Debian ZFS Root Recovery Cheatsheet

Use this if the system drops to BusyBox, fails to import the pool, or needs firmware/initramfs repair.

---

## 1. Boot live ISO, get root, install ZFS
```sh
sudo -i
sed -i 's/main/main contrib non-free-firmware/' /etc/apt/sources.list
apt update
apt install -y zfs-dkms zfsutils-linux
```

---

## 2. Import and mount pool
```sh
zpool import -f -R /mnt rpool
zfs load-key -a
zfs mount -a
```

Check mounts:
```sh
zfs list -o name,mountpoint,mounted
```

---

## 3. Bind mounts + ESPs
```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
mount /dev/nvme0n1p1 /mnt/boot/efi
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
rm -f /mnt/etc/resolv.conf
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

---

## 4. Enter chroot
```sh
chroot /mnt /bin/bash
```

---

## 5. Inside chroot
Update firmware if needed:
```sh
apt update
apt install -y firmware-amd-graphics intel-microcode firmware-realtek
```

Rebuild initramfs + UKI:
```sh
update-initramfs -u -k all
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

Fix hostid mismatch:
```sh
zgenhostid -f $(hostid)
```

---

## 6. Exit + reboot
```sh
exit
umount -Rl /mnt
zpool export rpool
reboot
```

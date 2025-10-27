# ZFS Root Recovery and Boot Repair

This guide assumes the system was originally installed using the procedure in `INSTALL.md`.

Use this when:
- the system no longer boots,
- systemd-boot or the UKI entry is broken,
- `initramfs` / UKI needs to be rebuilt, or
- you need to chroot into the existing system for repair.

This does **not** recreate datasets, reinstall packages, or perform a full reinstall.

---

## System assumptions

- Debian 13 (trixie)
- Root on **ZFS** with native encryption (you will be prompted for the passphrase at import)
- ZFS pool name: **`rpool`**
- Two EFI partitions:
  - `/dev/nvme0n1p1` → primary ESP
  - `/dev/nvme1n1p1` → backup ESP
- The ESPs are normally kept in sync (via `efi-sync.service` or manual rsync)
- Boot managed by **systemd-boot**
- The kernel is delivered as a **UKI** (`.efi` file) under `EFI/Linux/`

---

## 1. Boot into a live environment

Boot a Debian Live ISO (or other rescue system with ZFS support).

If the live ISO is missing tools like `zfsutils-linux`, `systemd-boot`, `systemd-ukify`, etc., follow `INSTALL.md` sections 1–5 for:
- enabling contrib/non-free-firmware in APT,
- installing required packages into the live environment,
- confirming networking.

Quick sanity check before proceeding:

```bash
ping -c3 deb.debian.org
```

---

## 2. Import the ZFS pool and enter the chroot

Import and mount the ZFS pool safely under `/mnt` (critical: the `-R /mnt` remaps mountpoints under /mnt instead of stomping the live ISO’s root):

```bash
zpool import -f -R /mnt rpool
zfs mount -a
```

Now replicate the mount + chroot prep from `INSTALL.md` sections 3–4:
- mount `/dev/nvme0n1p1` to `/mnt/boot/efi`
- mount `/dev/nvme1n1p1` to `/mnt/boot/efi-backup`
- bind-mount `/dev`, `/proc`, `/sys`
- copy `resolv.conf`

Then:

```bash
chroot /mnt /bin/bash
```

At this point you are “inside” your installed system.

---

## 3. Repair the bootloader (systemd-boot)

Check systemd-boot health:

```bash
bootctl status
```

If it’s missing/damaged on the primary ESP:

```bash
bootctl install
```

## 4. Rebuild initramfs and regenerate the UKI

Rebuild initramfs for all installed kernels:

```bash
update-initramfs -u -k all
```

Reinstall the UKI for the currently running kernel (this uses `kernel-install` + `ukify` to generate a new `.efi` under `EFI/Linux/`):

```bash
kernel-install add "$(uname -r)" /boot/vmlinuz-$(uname -r)
```

Make the rebuilt UKI the default boot entry:

```bash
bootctl set-default "$(bootctl list | awk '/\.efi/{print $2; exit}')"
```

---

## 5. Sync the backup EFI partition

If you maintain a second ESP (on `/dev/nvme1n1p1`), resync it from the primary:

```bash
systemctl start efi-sync.service
```

If you want to confirm or do it manually:

```bash
rsync -a --delete /boot/efi/ /boot/efi-backup/
```

You can also dry-run first with `-n`.

---

## 6. Optional maintenance

Reset your user password if needed:

```bash
passwd alchemist
```

Sanity-check time and networking before reboot:

```bash
timedatectl status
ping -c3 8.8.8.8
```

---

## 7. Clean exit and reboot

```bash
exit
umount -Rl /mnt
zpool export rpool
reboot
```

---

## See also

- `INSTALL.md` — full installation reference (partitioning, ZFS datasets, kernel/UKI generation, dual ESP setup, sway environment)
- `installed-software.md` — manually installed packages and rationale

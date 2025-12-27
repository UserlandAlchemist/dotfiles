# Debian 13 (Trixie) on ZFS - Recovery Guide

**Purpose:** Restore bootability and recover from hardware failures on audacious (ZFS root, systemd-boot UKI).

**Scope:** Boot recovery, ZFS repair, drive replacement, bootloader repair, service restoration.

**Not covered:** Borg data recovery (see `RESTORE.audacious.md`).

---

## Recovery Scenarios

This guide covers:

1. **Boot failures** — System won't boot, need to repair initramfs/UKI/bootloader (§1-§8)
2. **Single drive failed** — One NVMe in mirror is dead/failing (§9.2)
3. **Pool degraded** — ZFS reports DEGRADED status (§9.2)
4. **Both drives failed** — Complete data loss, restore from Borg (§9.3 → RESTORE.audacious.md)
5. **Pool import issues** — Can't import pool normally (§9.4)

**Quick decision tree:**
- System won't boot → Follow §1-§8 (standard recovery)
- `zpool status` shows DEGRADED → See §9.1 (diagnose) then §9.2 (repair/replace)
- Pool won't import → See §9.4 (import troubleshooting)
- Both drives dead → See §9.3 (links to RESTORE.audacious.md)

---

## Standard Boot Recovery Flow

Use this when the system won't boot but drives are physically healthy.

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

**If drive is missing:** See §9.2 for drive replacement procedure.

---

## §2 Import and mount ZFS pool

Import the encrypted ZFS root pool and mount datasets.

Steps:
1. Detect pools:

```sh
zpool import
```

Expected output: shows `rpool` available to import.

**If pool not detected:** Check §9.1 (diagnose pool health).

2. Import the pool (encrypted, read-write):

```sh
zpool import -l rpool
```

You'll be prompted for the ZFS passphrase.

3. Check pool health immediately after import:

```sh
zpool status
```

**If pool shows DEGRADED:** See §9.1 then §9.2 for drive replacement.

4. Mount datasets:

```sh
zfs mount rpool/ROOT/debian
zfs mount -a
```

5. Verify mount layout:

```sh
mount | grep rpool
```

Expected result: `rpool/ROOT/debian` is mounted at `/rpool/ROOT/debian` and other datasets mounted under it.

**Note:** ZFS doesn't automatically mount to `/mnt`. We'll handle that in §3.

---

## §3 Mount system for chroot

Prepare a full chroot environment at `/mnt` with kernel, devices, and EFI mounts.

Steps:
1. Bind-mount the ZFS root to /mnt:

```sh
mount --bind /rpool/ROOT/debian /mnt
```

2. Bind standard virtual filesystems:

```sh
mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys
```

3. Mount EFI partitions:

```sh
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir -p /mnt/boot/efi-backup
mount /dev/nvme1n1p1 /mnt/boot/efi-backup
```

**Note:** If one drive failed, only mount the working ESP. See §9.2 for replacing failed drive.

4. Copy DNS resolver config:

```sh
cp /etc/resolv.conf /mnt/etc/resolv.conf
```

5. Enter the chroot:

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
ip addr show
ping -c 3 1.1.1.1
```

2. Check ZFS health:

```sh
zpool status
zfs list
```

3. Confirm root mount:

```sh
mount | grep ' / '
df -h /
```

4. Verify APT sources:

```sh
grep -v '^#' /etc/apt/sources.list /etc/apt/sources.list.d/*.sources 2>/dev/null
apt update
```

Expected result: ZFS pool is healthy, network works, APT metadata refreshes.

**If pool shows DEGRADED:** Note this, continue with boot repair, then see §9.2 after system boots.

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

Verify `/etc/kernel/cmdline` contains ZFS root parameters:
```
root=ZFS=rpool/ROOT/debian ro quiet
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

Expected result: a fresh UKI exists in `/boot/efi/EFI/Linux/` with recent timestamp.

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

If missing, create it manually with those contents.

3. List EFI entries and verify UKI:

```sh
bootctl list
```

4. Set latest UKI as default:

```sh
bootctl set-default "$(bootctl list | awk '/\\.efi/{print $2; exit}')"
```

5. Verify ESP sync (if both drives working):

```sh
diff -rq /boot/efi /boot/efi-backup || echo "ESP copies differ!"
```

If out of sync:

```sh
rsync -aHAXv --delete /boot/efi/ /boot/efi-backup/
```

Expected result: both ESPs contain identical UKIs.

**If one drive failed:** Skip backup ESP for now, will be synced after drive replacement (§9.2).

---

## §7 Restore services from dotfiles

Reapply system configs via install scripts and restart critical services.

Steps:
1. Verify dotfiles repository exists:

```sh
ls -la /home/alchemist/dotfiles
```

**If missing:** Clone from GitHub or restore from Borg (see RESTORE.audacious.md).

2. Install system packages:

```sh
cd /home/alchemist/dotfiles
root-power-audacious/install.sh
root-efisync-audacious/install.sh
root-cachyos-audacious/install.sh
root-network-audacious/install.sh
root-backup-audacious/install.sh
root-proaudio-audacious/install.sh
root-sudoers-audacious/install.sh
```

3. Reload systemd and enable services:

Use the enablement block from `/home/alchemist/dotfiles/docs/audacious/INSTALL.audacious.md` §16 step 8.

4. Verify services:

```sh
systemctl --failed
systemctl list-timers | grep -E 'borg|zfs'
```

Expected result: no failed units, timers are active.

---

## §8 Exit, unmount, reboot

Leave the chroot and cleanly unmount before rebooting.

Steps:
1. Exit chroot:

```sh
exit
```

2. Unmount filesystems in reverse order:

```sh
umount /mnt/boot/efi-backup
umount /mnt/boot/efi
umount -Rl /mnt
```

3. Export pool:

```sh
zpool export rpool
```

Expected output: "exported rpool"

4. Remove live ISO and reboot:

```sh
reboot
```

Expected result: system prompts for ZFS passphrase and boots to login.

---

## Hardware Failure Recovery

Use these procedures when drives fail or pool is degraded.

---

## §9.1 Diagnose Pool Health

Before attempting repairs, understand what failed.

Steps:
1. Check detailed pool status:

```sh
zpool status -v
```

Look for:
- **State:** ONLINE (healthy), DEGRADED (one drive failed), FAULTED/UNAVAIL (can't import)
- **Errors:** Read/write/checksum errors indicate failing hardware
- **Device status:** Each vdev shows ONLINE, DEGRADED, FAULTED, OFFLINE, UNAVAIL

2. Check SMART status of physical drives:

```sh
smartctl -a /dev/nvme0n1
smartctl -a /dev/nvme1n1
```

Look for:
- **Reallocated sectors** — Drive is failing
- **Pending sectors** — Drive will fail soon
- **Temperature** — Overheating can cause errors
- **Power-on hours** — Drive age

3. Identify which physical drive corresponds to ZFS device:

```sh
lsblk -o NAME,SERIAL,MODEL,SIZE
zpool status -P
```

`zpool status -P` shows full `/dev/disk/by-id/` paths mapping to physical drives.

**Decision matrix:**

| Pool State | One Drive Status | Other Drive Status | Action |
|------------|------------------|-------------------|---------|
| DEGRADED | UNAVAIL/FAULTED | ONLINE | §9.2: Replace failed drive |
| DEGRADED | ONLINE with errors | ONLINE | §9.2.1: Scrub first, may recover |
| FAULTED | UNAVAIL/FAULTED | UNAVAIL/FAULTED | §9.3: Both failed, restore from Borg |
| Won't import | N/A | N/A | §9.4: Import troubleshooting |

---

## §9.2 Single Drive Failed (Degraded Pool)

One NVMe in the mirror has failed. ZFS continues operating on the remaining drive.

### §9.2.1 Temporary Operation (Running Degraded)

If waiting for replacement drive to arrive, you can operate degraded temporarily.

**Risks:**
- No redundancy — if second drive fails, all data is lost
- Performance may be reduced
- Should replace ASAP

Steps:
1. Import pool if not already imported:

```sh
zpool import -l rpool
```

2. Verify pool is functional:

```sh
zpool status
zfs list
```

3. Attempt scrub to see if errors are transient:

```sh
zpool scrub rpool
```

Monitor scrub progress:

```sh
watch zpool status
```

If scrub completes with no errors and drive returns to ONLINE: problem may have been transient (loose cable, power glitch).

If scrub cannot complete or drive remains UNAVAIL/FAULTED: drive needs replacement (§9.2.2).

4. Monitor health while degraded:

```sh
zpool status -v
smartctl -a /dev/nvme0n1
smartctl -a /dev/nvme1n1
```

**Important:** Back up critical data immediately. Run manual Borg backup:

```sh
sudo systemctl start borg-backup.service
journalctl -u borg-backup.service -f
```

### §9.2.2 Drive Replacement (Permanent Fix)

Replace failed drive and rebuild mirror.

**Prerequisites:**
- Replacement NVMe drive (same size or larger)
- Anti-static precautions
- Pool is imported and operational on remaining drive

**Steps:**

#### 1. Physical Drive Replacement

1. Shut down system:

```sh
shutdown -h now
```

2. Power off completely, unplug power.

3. Remove failed NVMe drive (note which slot: primary/secondary).

4. Install replacement NVMe drive in same slot.

5. Boot Debian Live ISO (don't try to boot from degraded pool yet).

#### 2. Partition New Drive

The new drive needs identical partitioning to the working drive.

Steps:
1. Become root in live environment:

```sh
sudo -i
apt update
apt install -y zfsutils-linux gdisk systemd-boot dosfstools
```

2. Identify drives:

```sh
lsblk -e7 -o NAME,SIZE,SERIAL,MODEL
```

Example output:
```
NAME        SIZE SERIAL           MODEL
nvme0n1     1.8T ABC123           Samsung 970
├─nvme0n1p1 512M                  (ESP)
└─nvme0n1p2 1.8T                  (ZFS)
nvme1n1     1.8T XYZ789           Samsung 970  ← NEW DRIVE
```

3. Copy partition table from working drive to new drive:

**DANGER:** Double-check device names. Wrong device = data loss.

```sh
sgdisk --replicate=/dev/nvme1n1 /dev/nvme0n1
sgdisk --randomize-guids /dev/nvme1n1
```

`--randomize-guids` generates new UUIDs for the partitions (required for GPT).

4. Verify partition table:

```sh
gdisk -l /dev/nvme1n1
```

Expected: Two partitions matching working drive:
- nvme1n1p1: EFI System Partition (512M, type EF00)
- nvme1n1p2: Solaris root (remaining space, type BF00)

5. Format ESP:

```sh
mkfs.fat -F32 -n EFI /dev/nvme1n1p1
```

#### 3. Replace Drive in ZFS Pool

Steps:
1. Import pool with failed device:

```sh
zpool import -l rpool
```

2. Check pool status to identify failed device path:

```sh
zpool status -P
```

Look for device marked UNAVAIL or FAULTED. Note the `/dev/disk/by-id/` path.

Example output:
```
  pool: rpool
 state: DEGRADED
  scan: scrub repaired 0B in 1h23m
config:

  NAME                                STATE     READ WRITE CKSUM
  rpool                               DEGRADED     0     0     0
    mirror-0                          DEGRADED     0     0     0
      nvme-Samsung_970_ABC123-part2   ONLINE       0     0     0
      nvme-Samsung_970_OLD456-part2   UNAVAIL      0     0     0  ← FAILED
```

3. Replace failed device with new device:

```sh
zpool replace rpool /dev/disk/by-id/nvme-Samsung_970_OLD456-part2 \
                     /dev/disk/by-id/nvme-Samsung_970_XYZ789-part2
```

**Use by-id paths** for stability across reboots.

Expected output: "Make sure to wait until resilver is done before rebooting."

4. Monitor resilver progress:

```sh
watch zpool status
```

Resilver will show progress:
```
  scan: resilver in progress since Mon Dec 23 12:00:00 2025
        1.2T scanned at 2.5G/s, 800G copied at 1.8G/s, 400G to go
        0h15m remaining
```

**Do not reboot** until resilver completes (status shows "resilver complete").

Time depends on pool size:
- 1TB pool: ~30-60 minutes
- 2TB pool: ~1-2 hours

5. Verify resilver completion:

```sh
zpool status
```

Expected:
```
  scan: resilver completed on Mon Dec 23 13:15:00 2025
config:

  NAME                                STATE     READ WRITE CKSUM
  rpool                               ONLINE       0     0     0
    mirror-0                          ONLINE       0     0     0
      nvme-Samsung_970_ABC123-part2   ONLINE       0     0     0
      nvme-Samsung_970_XYZ789-part2   ONLINE       0     0     0  ← NEW
```

Pool state: ONLINE (no longer DEGRADED).

#### 4. Sync ESP to New Drive

The new drive's ESP is empty. Need to copy bootloader and UKIs.

Steps:
1. Mount both ESPs:

```sh
mkdir -p /mnt/efi-primary /mnt/efi-secondary
mount /dev/nvme0n1p1 /mnt/efi-primary
mount /dev/nvme1n1p1 /mnt/efi-secondary
```

2. Sync primary ESP to new drive's ESP:

```sh
rsync -aHAXv --delete /mnt/efi-primary/ /mnt/efi-secondary/
```

3. Verify contents match:

```sh
diff -rq /mnt/efi-primary /mnt/efi-secondary
```

Expected: No differences reported.

4. Unmount ESPs:

```sh
umount /mnt/efi-primary /mnt/efi-secondary
```

#### 5. Test Boot from New Drive

Verify the new drive can boot independently (in case other drive fails later).

Steps:
1. Export pool and reboot:

```sh
zpool export rpool
reboot
```

2. In BIOS/UEFI:
   - Change boot order to boot from NEW drive first
   - Or use boot menu (F8/F12) to select new drive's EFI entry

3. System should boot normally:
   - ZFS passphrase prompt appears
   - System boots to login

4. After successful boot, verify pool health:

```sh
zpool status
```

Expected: Both drives ONLINE, no errors.

5. Restore original boot order in BIOS if desired (both drives should work).

#### 6. Re-enable ESP Auto-Sync

The `efi-sync.path` systemd unit keeps ESPs synchronized.

Steps:
1. Verify service is running:

```sh
systemctl status efi-sync.path
```

2. Test manual sync:

```sh
touch /boot/efi/EFI/Linux/test-sync
sleep 5
ls /boot/efi-backup/EFI/Linux/test-sync
```

Expected: Test file appears in backup ESP within 5 seconds.

3. Clean up test file:

```sh
rm /boot/efi/EFI/Linux/test-sync /boot/efi-backup/EFI/Linux/test-sync
```

**Drive replacement complete.** Pool is back to full redundancy.

---

## §9.3 Both Drives Failed (Complete Data Loss)

If both NVMe drives failed or pool cannot be recovered, restore from Borg backup.

**Procedure:**
1. Follow `INSTALL.audacious.md` to create fresh ZFS-on-root installation
2. Follow `RESTORE.audacious.md` to recover data from Borg backup

**Prerequisites:**
- Astute (Borg repository server) must be accessible
- Blue USB key with SSH keys and Borg passphrase
- Or: Bitwarden access to retrieve passphrase

**Note:** This is a full rebuild. Expect 4-6 hours for complete recovery.

---

## §9.4 Pool Import Troubleshooting

If `zpool import` doesn't show the pool or import fails.

### §9.4.1 Force Import

If pool was not cleanly exported (system crashed):

```sh
zpool import -f -l rpool
```

The `-f` flag forces import despite warnings.

### §9.4.2 Import with Altroot

If pool imports but won't mount to `/`:

```sh
zpool import -f -l -o altroot=/mnt rpool
```

This imports pool with all mounts relative to `/mnt`.

### §9.4.3 Pool Not Visible

If `zpool import` shows no pools:

1. Check if drives are detected:

```sh
lsblk -f
ls -la /dev/disk/by-id/ | grep nvme
```

2. Scan specific devices:

```sh
zpool import -d /dev/disk/by-id
```

3. If pool shows with different name or hostid mismatch:

```sh
zpool import -f -l -N rpool
```

`-N` prevents automatic mounting, allowing you to mount manually.

### §9.4.4 Encryption Key Issues

If pool won't unlock (wrong passphrase or key lost):

**If passphrase is correct but still fails:**

Check if pool expects key file instead:

```sh
zpool import -l rpool
# If prompts for key file instead of passphrase:
zfs load-key -L file:///path/to/key rpool/ROOT/debian
```

**If passphrase is lost:**

Data is irrecoverable from this pool. Restore from Borg backup (§9.3).

---

## §10 Post-Recovery Verification

Confirm the system is stable after recovery or drive replacement.

Steps:
1. Verify ZFS health:

```sh
zpool status -v
zpool list
zfs list
```

Expected:
- State: ONLINE
- No errors in READ/WRITE/CKSUM columns
- Both drives showing ONLINE

2. Verify services:

```sh
systemctl --failed
systemctl list-timers | grep -E 'borg|zfs|efi'
```

Expected: No failed units, all timers active.

3. Test ESP sync:

```sh
touch /boot/efi/EFI/Linux/post-recovery-test
sleep 5
ls -la /boot/efi-backup/EFI/Linux/ | grep post-recovery-test
rm /boot/efi/EFI/Linux/post-recovery-test
```

Expected: File syncs within 5 seconds via efi-sync.path.

4. Test NAS integration (if Astute is available):

```sh
nas-open
ls /srv/astute
nas-close
```

Expected: Mounts successfully, no errors.

5. Trigger manual backup:

```sh
sudo systemctl start borg-backup.service
sleep 10
journalctl -u borg-backup.service -n 50
```

Expected: Backup succeeds, new archive created.

6. Check for system updates:

```sh
apt update
apt list --upgradable
```

7. Review system logs for anomalies:

```sh
journalctl -p err -b
dmesg | grep -i error
```

Expected: No critical errors related to ZFS or boot.

**If all checks pass:** System is fully recovered and stable.

---

## Maintenance After Recovery

1. **Update recovery documentation** if you discovered gaps during recovery
2. **Test recovery USB/Blue USB** to ensure keys and passphrases are current
3. **Schedule ZFS scrub** if not done during recovery:

```sh
zpool scrub rpool
```

4. **Monitor pool health** for a few days:

```sh
zpool status
smartctl -a /dev/nvme0n1
smartctl -a /dev/nvme1n1
```

---

## References

- `INSTALL.audacious.md` — Fresh installation from scratch
- `RESTORE.audacious.md` — Borg backup restoration
- `INSTALL.audacious.md` — What differs from stock Debian
- OpenZFS documentation: https://openzfs.github.io/openzfs-docs/

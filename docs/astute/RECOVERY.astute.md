# Astute Recovery Guide

Complete disaster recovery procedures for the Astute NAS/backup server.

**System architecture:**
- ext4 root on NVMe (/dev/nvme0n1)
- ZFS mirror pool "ironwolf" on /dev/sdb + /dev/sdc (encrypted, data only)
- SATA SSD /dev/sda (swap + ZFS cache)
- GRUB bootloader
- NFS server, Borg repository, Jellyfin media server

---

## Recovery Scenarios

1. **Boot failures** — System won't boot, GRUB errors (§1-§5)
2. **Single drive failed** — One IronWolf in mirror dead (§7.2)
3. **Pool degraded** — ZFS DEGRADED status (§7.2)
4. **Both drives failed** — Complete data loss, restore from backups (§7.3)
5. **Pool import issues** — Can't import ironwolf pool (§7.4)
6. **NFS broken** — Clients can't mount /srv/nas (§9)

**Quick decision tree:**
- System won't boot → Follow §1-§5
- `zpool status ironwolf` shows DEGRADED → See §7.1 then §7.2
- Pool won't import → See §7.4
- Both drives dead → See §7.3
- NFS not working → See §9

---

## §1 Boot from Debian Live ISO

Use for boot failures, GRUB corruption, or root filesystem issues.

Steps:
1. Boot Debian 13 (Trixie) Live ISO (USB or network boot)
2. Choose "Live system (amd64)" from boot menu
3. Wait for desktop environment to load
4. Open terminal

Expected result: Live environment with root access via `sudo`.

---

## §2 Mount Root Filesystem

Mount the ext4 root to inspect or repair.

Steps:
1. Identify the NVMe device:

```sh
lsblk
```

Look for device with two partitions (~512M EFI + large ext4).

2. Mount root filesystem:

```sh
sudo mkdir -p /mnt/root
sudo mount /dev/nvme0n1p2 /mnt/root
```

**Use correct partition number** (likely p2, but verify with `lsblk`).

3. Verify mount:

```sh
ls /mnt/root
```

Expected result: Standard Linux directory tree (bin, etc, home, usr, var, srv).

---

## §3 Check Root Filesystem Integrity

Run fsck if boot failed due to filesystem corruption.

**DANGER:** Never run fsck on a mounted filesystem. Unmount first.

Steps:
1. If mounted, unmount:

```sh
sudo umount /mnt/root
```

2. Check filesystem:

```sh
sudo fsck.ext4 -f /dev/nvme0n1p2
```

Use `-y` to auto-repair (use with caution):

```sh
sudo fsck.ext4 -fy /dev/nvme0n1p2
```

3. Remount after repair:

```sh
sudo mount /dev/nvme0n1p2 /mnt/root
```

Expected result: fsck reports clean filesystem or repairs errors.

---

## §4 Chroot into Installed System

Enter installed system to repair GRUB or modify system configuration.

Steps:
1. Mount root filesystem (§2)

2. Mount EFI partition:

```sh
sudo mount /dev/nvme0n1p1 /mnt/root/boot/efi
```

3. Bind-mount essential system directories:

```sh
sudo mount --bind /dev  /mnt/root/dev
sudo mount --bind /proc /mnt/root/proc
sudo mount --bind /sys  /mnt/root/sys
```

4. Chroot:

```sh
sudo chroot /mnt/root /bin/bash
```

5. Verify environment:

```sh
ls /boot/efi/EFI
```

Expected result: You are now operating inside the installed system. Commands affect the installed system, not the live environment.

---

## §5 Reinstall GRUB

If system won't boot due to GRUB corruption.

Steps:
1. Chroot into system (§4)

2. Reinstall GRUB to NVMe:

```sh
grub-install /dev/nvme0n1
```

3. Regenerate GRUB configuration:

```sh
update-grub
```

4. Verify GRUB files exist:

```sh
ls /boot/efi/EFI/debian/
```

Should see `grubx64.efi` and related files.

5. Exit chroot and reboot:

```sh
exit
sudo umount -R /mnt/root
sudo reboot
```

Expected result: System boots normally.

---

## §6 Post-Boot ZFS Import

If system boots but ZFS pool won't auto-import.

Steps:
1. List available pools:

```sh
sudo zpool import
```

2. If `ironwolf` appears, import it:

```sh
sudo zpool import -f ironwolf
```

Use `-N` to import without mounting datasets:

```sh
sudo zpool import -f -N ironwolf
```

3. Load encryption keys (if encrypted):

```sh
sudo zfs load-key -a
```

Enter passphrase when prompted.

4. Mount datasets:

```sh
sudo zfs mount -a
```

5. Verify mounts:

```sh
zfs list
mount | grep /srv
```

Expected result: `ironwolf` pool is ONLINE, datasets mounted at /srv/nas and /srv/backups.

---

## §7 ZFS Pool Recovery

### §7.1 Diagnose Pool Health

Check pool state before taking action.

Steps:
1. Check pool status:

```sh
sudo zpool status ironwolf
```

2. Check pool state and drive status:

```sh
sudo zpool list ironwolf
```

**Decision matrix:**

| Pool State | One Drive Status | Other Drive Status | Action |
|------------|------------------|-------------------|---------|
| DEGRADED | UNAVAIL/FAULTED | ONLINE | §7.2: Replace failed drive |
| DEGRADED | ONLINE with errors | ONLINE | Run scrub first: `sudo zpool scrub ironwolf` |
| FAULTED | UNAVAIL/FAULTED | UNAVAIL/FAULTED | §7.3: Both failed, restore from client backups |
| Won't import | N/A | N/A | §7.4: Import troubleshooting |

3. Check SMART status on both drives:

```sh
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62F68T
```

Look for:
- Reallocated_Sector_Ct (should be 0)
- Current_Pending_Sector (should be 0)
- Offline_Uncorrectable (should be 0)
- SMART overall-health self-assessment: PASSED

Expected result: Clear understanding of pool state and which drive(s) failed.

---

### §7.2 Single Drive Failed

One IronWolf drive dead, pool DEGRADED but data intact.

#### §7.2.1 Temporary Operation on Degraded Pool

**You can continue using a DEGRADED pool** while waiting for replacement drive.

Steps:
1. Verify pool is readable:

```sh
zfs list
ls /srv/nas
```

2. Check degraded device:

```sh
sudo zpool status ironwolf
```

Note the FAULTED/UNAVAIL device name.

3. Continue normal operations:
   - NFS exports still work
   - Borg backups still work (slower, no redundancy)
   - Jellyfin still serves media

**Risks while degraded:**
- **NO REDUNDANCY:** Second drive failure = complete data loss
- **Slower reads:** All data read from single drive
- **Replace ASAP:** Order replacement immediately

Expected result: System remains functional on single drive.

---

#### §7.2.2 Drive Replacement (Permanent Fix)

Replace failed drive and resilver mirror.

**Before starting:**
- Identify failed drive with `sudo zpool status ironwolf`
- Note physical drive location (top or bottom bay)
- Purchase identical or larger IronWolf drive
- Backup critical data if possible (pool is vulnerable)

Steps:

#### 1. Physical Drive Replacement

1. Shut down system:

```sh
sudo systemctl poweroff
```

2. Power off completely, unplug power
3. Remove failed IronWolf drive (note which bay: /dev/sdb or /dev/sdc)
4. Install replacement drive in same bay
5. Reconnect power and boot

#### 2. Identify New Drive

1. After boot, list drives:

```sh
lsblk
sudo zpool status ironwolf
```

2. Find the new drive by-id path:

```sh
ls -l /dev/disk/by-id/ | grep ata-ST4000VN006
```

You should see:
- One old drive (still in pool, ONLINE)
- One new drive (not in pool, no partitions)

Example output:
```
ata-ST4000VN006-3CW104_ZW62ETJT -> ../../sdb    # old, still working
ata-ST4000VN006-3CW104_NEW123456 -> ../../sdc  # new, blank
```

3. Note the new drive's by-id path for next step.

#### 3. Replace Drive in ZFS Pool

**CRITICAL:** Use stable by-id paths, not /dev/sdX (which can change).

Find old (failed) device in pool:

```sh
sudo zpool status ironwolf
```

Look for device marked FAULTED or UNAVAIL, note its full path.

Replace drive in pool:

```sh
sudo zpool replace ironwolf \
  /dev/disk/by-id/ata-ST4000VN006-3CW104_OLDFAILED \
  /dev/disk/by-id/ata-ST4000VN006-3CW104_NEW123456
```

**Replace OLD and NEW paths** with actual values from `ls -l /dev/disk/by-id/`.

ZFS will automatically partition the new drive and start resilvering.

#### 4. Monitor Resilver Progress

Resilver copies all data from working drive to new drive.

```sh
watch sudo zpool status ironwolf
```

**Resilver time estimates:**
- 4TB pool, 50% full, 7200 RPM drives: **4-8 hours**
- 4TB pool, 80% full: **8-12 hours**
- Depends on data amount and drive speed

You can continue using the pool during resilver (slower performance).

Expected output during resilver:
```
  pool: ironwolf
 state: DEGRADED
status: One or more devices is currently being resilvered.
...
  scan: resilver in progress since Mon Dec 23 14:30:00 2025
        1.2T scanned at 150M/s, 800G issued at 100M/s
        800G resilvered, 65.32% done, 01:15:23 to go
```

#### 5. Verify Resilver Completion

After resilver completes:

```sh
sudo zpool status ironwolf
```

Expected output:
```
  pool: ironwolf
 state: ONLINE
  scan: resilvered 1.5T in 6h23m with 0 errors on Mon Dec 23 20:53:23 2025
```

Both drives should show ONLINE status.

#### 6. Scrub After Replacement

Verify data integrity after resilver:

```sh
sudo zpool scrub ironwolf
```

Monitor scrub:

```sh
watch sudo zpool status ironwolf
```

Expected result: Scrub completes with 0 errors, pool state ONLINE, both drives healthy.

---

#### §7.2.3 Post-Replacement Verification

Confirm pool health and performance.

Steps:
1. List all datasets:

```sh
zfs list
```

2. Check space usage:

```sh
zpool list ironwolf
```

3. Test read performance:

```sh
sudo dd if=/srv/nas/test-file of=/dev/null bs=1M count=1000
```

4. Test NFS mount from client (Audacious):

```sh
ssh audacious "nas-open && ls /srv/astute && nas-close"
```

5. Check Borg repository:

```sh
sudo borg list /srv/backups/audacious-borg
```

6. Enable weekly scrubs:

```sh
sudo systemctl enable --now zfs-scrub-weekly@ironwolf.timer
```

Expected result: Pool performs normally, all services accessible.

---

### §7.3 Both Drives Failed (Complete Data Loss)

If both IronWolf drives died simultaneously, pool cannot be imported.

**Data recovery options:**
1. **NO local backups exist** — Astute stores backups FROM clients, but doesn't back up itself
2. **Client data** may be recoverable if Audacious has recent Borg backups
3. **Media files** may be replaceable from original sources

Steps for clean rebuild:

#### 1. Replace Both Drives

1. Power off system
2. Install two new IronWolf drives
3. Boot system

#### 2. Recreate ZFS Pool

**DANGER:** This destroys all data. Verify no recovery options first.

```sh
sudo zpool create -f ironwolf mirror \
  /dev/disk/by-id/ata-ST4000VN006-3CW104_NEW1 \
  /dev/disk/by-id/ata-ST4000VN006-3CW104_NEW2
```

Enable compression and create datasets:

```sh
sudo zfs set compression=lz4 ironwolf
sudo zfs create -o mountpoint=/srv/nas ironwolf/nas
sudo zfs create -o mountpoint=/srv/backups ironwolf/backups
```

#### 3. Set Up Encryption (Optional)

If original pool was encrypted, recreate with encryption:

```sh
sudo zpool create -f ironwolf mirror \
  /dev/disk/by-id/ata-ST4000VN006-3CW104_NEW1 \
  /dev/disk/by-id/ata-ST4000VN006-3CW104_NEW2

sudo zfs create -o encryption=on -o keyformat=passphrase \
  -o mountpoint=/srv/nas ironwolf/nas

sudo zfs create -o mountpoint=/srv/backups ironwolf/backups
```

#### 4. Restore Data

**From client Borg backups** (if Audacious has backups of its own data):
- Audacious can restore its own data from recent backups
- This doesn't restore Astute's data (media, etc.)

**Manual restoration:**
- Re-download media files
- Reconfigure Jellyfin library
- Client systems will need to restart Borg backups (new repository)

Expected result: Clean pool ready for data, but all previous data lost.

---

### §7.4 Pool Import Troubleshooting

If `sudo zpool import` doesn't show the pool.

Steps:
1. Scan specific device paths:

```sh
sudo zpool import -d /dev
sudo zpool import -d /dev/disk/by-id
```

2. Try importing with original name:

```sh
sudo zpool import -f ironwolf
```

3. List pools with different names:

```sh
sudo zpool import | grep pool:
```

If pool appears with different name:

```sh
sudo zpool import OLD_NAME ironwolf
```

4. Check if drives are visible:

```sh
lsblk
ls -l /dev/disk/by-id/ | grep ST4000
```

5. Load ZFS module manually (if not loaded):

```sh
sudo modprobe zfs
```

6. Check dmesg for drive errors:

```sh
dmesg | grep -i "sd[bc]"
dmesg | grep -i zfs
```

7. If pool still won't import and both drives are healthy:

```sh
sudo zdb -e -p /dev/disk/by-id ironwolf
```

This is a low-level pool inspection tool (advanced).

Expected result: Pool imports successfully, or error message indicates next troubleshooting step.

---

## §8 Cache Device Recovery

If SATA SSD (/dev/sda) fails, pool loses cache but data remains intact.

Steps:
1. Check pool status:

```sh
sudo zpool status ironwolf
```

If cache device shows UNAVAIL/FAULTED:

2. Remove failed cache device:

```sh
sudo zpool remove ironwolf /dev/sda2
```

3. Replace SATA SSD physically (if failed)

4. Recreate swap on new SSD:

```sh
sudo mkswap /dev/sda1
sudo swapon /dev/sda1
```

Update /etc/fstab:

```sh
sudo blkid /dev/sda1
```

Add to /etc/fstab:
```
UUID=<uuid-from-blkid>  none  swap  sw  0  0
```

5. Re-add cache device:

```sh
sudo zpool add ironwolf cache /dev/sda2
```

Expected result: Cache device operational, pool performance restored.

---

## §9 NFS Export Recovery

If NFS exports are broken after recovery.

Steps:
1. Verify ZFS datasets are mounted:

```sh
mount | grep /srv/nas
```

If not mounted, import pool and mount datasets (§6).

2. Check NFS server is running:

```sh
sudo systemctl status nfs-server
```

If not running:

```sh
sudo systemctl start nfs-server
```

3. Verify exports file:

```sh
cat /etc/exports
```

Should contain:
```
/srv/nas  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

If missing, add it:

```sh
echo "/srv/nas  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
```

4. Reload exports:

```sh
sudo exportfs -ra
sudo exportfs -v
```

5. Test from client (Audacious):

```sh
ssh audacious "nas-open && ls /srv/astute && nas-close"
```

Expected result: NFS exports visible and mountable from clients.

---

## §10 Service Restoration After Recovery

Restore services from dotfiles after clean install or recovery.

Steps:
1. Clone dotfiles:

```sh
cd ~
git clone git@github.com:alchemist/dotfiles.git
cd dotfiles
```

2. Deploy user packages:

```sh
stow profile-common bash-astute bin-astute nas-astute
```

3. Deploy system packages:

```sh
sudo root-power-astute/install.sh
```

4. Reload systemd and enable services:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service
sudo systemctl enable --now astute-idle-suspend.timer
sudo systemctl enable --now nas-inhibit.service
```

5. Verify services:

```sh
systemctl --user status nas-inhibit.service
systemctl status astute-idle-suspend.timer
systemctl list-timers
```

6. Test NAS wake from client:

```sh
ssh audacious "nas-open"
```

From Astute:

```sh
systemd-inhibit --list
```

Should show nas-inhibit blocking sleep.

7. Close NAS:

```sh
ssh audacious "nas-close"
```

Expected result: All dotfile-managed services operational.

---

## §11 Borg Repository Recovery

Restore Borg repository service after recovery.

Steps:
1. Verify borg user exists:

```sh
id borg
```

If not, create:

```sh
sudo adduser --system --home /srv/backups --shell /bin/sh --group borg
```

2. Set up SSH directory:

```sh
sudo mkdir -p /srv/backups/.ssh
sudo chmod 700 /srv/backups/.ssh
```

3. Add client public key from encrypted USB:

Mount USB:
```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

Add key:
```sh
sudo tee /srv/backups/.ssh/authorized_keys >/dev/null <<EOF
command="borg serve --restrict-to-path /srv/backups",restrict $(cat /mnt/keyusb/audacious-backup.pub)
EOF
sudo chmod 600 /srv/backups/.ssh/authorized_keys
sudo chown -R borg:borg /srv/backups/.ssh
```

4. Test from client:

```sh
ssh audacious "borg list borg@astute:/srv/backups/audacious-borg"
```

Expected result: Client can list Borg repository.

---

## §12 Post-Recovery Checklist

Verify all systems operational after recovery.

- [ ] System boots normally
- [ ] `zpool status ironwolf` shows ONLINE
- [ ] All ZFS datasets mounted at /srv/nas and /srv/backups
- [ ] `sudo exportfs -v` shows /srv/nas exported
- [ ] NFS mount works from Audacious: `nas-open && ls /srv/astute`
- [ ] Borg client can list repository: `borg list borg@astute:/srv/backups/audacious-borg`
- [ ] nas-inhibit.service works when client connects
- [ ] astute-idle-suspend.timer allows system to suspend when idle
- [ ] Jellyfin serves media (optional)
- [ ] apt-cacher-ng responds (optional)
- [ ] Weekly ZFS scrub timer enabled: `systemctl list-timers | grep scrub`
- [ ] SMART monitoring enabled: `systemctl status smartmontools`

---

## §13 Prevention and Monitoring

Reduce risk of future failures.

### SMART Monitoring

Enable email alerts for drive issues:

```sh
sudo apt install smartmontools
sudo systemctl enable --now smartmontools
```

Check drive health weekly:

```sh
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62F68T
```

### Weekly Scrubs

Verify ZFS scrub timer is active:

```sh
systemctl status zfs-scrub-weekly@ironwolf.timer
systemctl list-timers | grep scrub
```

### Drive Age Tracking

IronWolf drives have 3-year warranty. Track installation date:

```sh
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT | grep "Power_On_Hours"
```

Convert hours to years:
- 8760 hours = 1 year
- 26280 hours = 3 years (replacement recommended)

### Backup Validation

Monthly verification that Audacious backups are working:

```sh
sudo borg list /srv/backups/audacious-borg
```

Most recent archive should be within last 24 hours.

---

## Appendix A: Astute Hardware Reference

**System configuration:**
- **Hostname:** astute
- **Role:** NAS, backup server, media server
- **CPU:** Intel i5-7500
- **RAM:** 8 GB
- **System disk:** NVMe (/dev/nvme0n1, ext4 root)
- **Cache/swap:** SATA SSD (/dev/sda, 32GB swap + ZFS cache)
- **Data pool:** 2× IronWolf 4TB (/dev/sdb, /dev/sdc, ZFS mirror)
- **Network:** 1 GbE at 192.168.1.154
- **MAC:** `40:8d:5c:c7:ae:66`
- **OOB:** GL.iNet Comet at 192.168.1.126

**Drive by-id paths** (stable across reboots):
```
/dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT -> ../../sdb
/dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62F68T -> ../../sdc
```

**ZFS pool layout:**
```
ironwolf (mirror)
├── /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT
└── /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62F68T
├── cache: /dev/sda2
└── datasets:
    ├── ironwolf/nas → /srv/nas (NFS export)
    └── ironwolf/backups → /srv/backups (Borg repository)
```

---

## Appendix B: Common Error Messages

### "pool: ironwolf, state: DEGRADED"

**Cause:** One drive failed or disconnected
**Action:** See §7.1 (diagnose), then §7.2 (replace drive)

### "cannot import 'ironwolf': no such pool available"

**Cause:** Pool not visible to ZFS
**Action:** See §7.4 (import troubleshooting)

### "mountpoint ... busy"

**Cause:** Dataset can't mount because directory is in use
**Action:**
```sh
sudo lsof /srv/nas  # find processes using mountpoint
sudo fuser -k /srv/nas  # kill them (use with caution)
sudo zfs mount ironwolf/nas
```

### "GRUB error: no such partition"

**Cause:** GRUB can't find boot partition
**Action:** See §5 (reinstall GRUB from live environment)

### "Key load error"

**Cause:** Wrong ZFS encryption passphrase
**Action:**
```sh
sudo zfs unload-key ironwolf/nas
sudo zfs load-key ironwolf/nas
```
Enter correct passphrase.

---

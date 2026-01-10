# Disaster Recovery Guide

Complete disaster recovery procedures for the Wolfpack. OS and infrastructure
repair steps live in per-host install/recovery docs.

**Last Updated:** 2026-01-09

**Current Hardware:** The Secrets USB is currently a blue SanDisk 32GB USB
drive. The Trusted Copy is maintained by a trusted person off-site.

---

## Threat Scenarios

### Scenario 1: House Fire / Flood

- **Lost:** Audacious, Astute, Secrets USB, cold storage HDD
- **Survives:** BorgBase off-site, trusted person's USB copy, Google Drive
  bundle
- **RTO:** 1-3 days
- **RPO:** 24 hours (last BorgBase backup)

### Scenario 2: Single System Failure

- **Lost:** Audacious OR Astute (hardware failure, theft)
- **Survives:** Other system, local Borg backups, Secrets USB
- **RTO:** 4-8 hours
- **RPO:** 6 hours (last local Borg backup)

### Scenario 3: Ransomware

- **Encrypted:** Audacious and/or Astute filesystems
- **Survives:** BorgBase off-site (append-only access), Secrets USB (offline),
  cold storage (offline)
- **RTO:** 4-8 hours (restore from BorgBase)
- **RPO:** 24 hours (last BorgBase backup)

---

## Recovery Kit Locations

### Primary: Secrets USB (On-Site, Encrypted)

- **Location:** Home, with cold storage drive
- **Encryption:** LUKS (AES256)
- **Update Frequency:** As secrets change
- **Access:** cryptsetup + mount
- **Risk:** Destroyed in same disaster as Audacious/Astute

### Secondary: Trusted Person USB (Off-Site, Encrypted)

- **Location:** Trusted person, visits every ~6 months
- **Content:** Full copy of Secrets USB
- **Update Frequency:** Every 6 months during visit
- **Risk:** 6-month staleness, relies on trusted person

### Tertiary: Google Drive Bundle (Cloud, Encrypted)

- **Location:** Google Drive (external provider)
- **Encryption:** GPG AES256 symmetric
- **Update Frequency:** When secrets change, minimum quarterly
- **Access:** GPG passphrase (memorized or in wallet)
- **Risk:** Only as secure as GPG passphrase

### Quaternary: Bitwarden (Optional)

- **Location:** Bitwarden cloud (external provider)
- **Content:** Individual secrets as secure notes
- **Access:** Bitwarden master password
- **Risk:** Single point of failure if Bitwarden account lost

For detailed procedures on maintaining recovery kits, see
`docs/recovery-kit-maintenance.md`.

---

## Recovery Procedures

### Prerequisites

Have these before proceeding:

1. Secrets USB (LUKS) and passphrase
2. SSH keys and Borg passphrase (stored on Secrets USB)
3. BorgBase credentials and repo keys (stored on Secrets USB)
4. A working machine with internet access

   If the Secrets USB is unavailable, use the trusted person USB or the Google
Drive recovery bundle.

**Note:** If the issue is a single drive failure in a ZFS pool, follow the host
recovery doc first. Data restore only applies once access to backups is
required.

**If no secrets are available:** You cannot decrypt Borg or mount encrypted
pools. Options are limited to rebuilding from scratch and re-issuing
credentials. Treat this as a total data loss scenario, rebuild hosts cleanly,
rotate all keys, and recreate recovery media immediately after rebuild.

---

## §1 Restore Secrets

Required for any data loss beyond a single drive.

Steps:

1. Unlock and mount the Secrets USB:

   ```sh
   lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
   sudo cryptsetup open /dev/sdX1 keyusb
   sudo mkdir -p /mnt/keyusb
   sudo mount /dev/mapper/keyusb /mnt/keyusb
   ```

2. Restore SSH keys and config:

   ```sh
   mkdir -p ~/.ssh
   cp -a /mnt/keyusb/ssh-backup/* ~/.ssh/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/*
   chmod 644 ~/.ssh/*.pub 2>/dev/null || true
   ```

3. Restore Borg passphrase and patterns:

   ```sh
   mkdir -p ~/.config/borg
   cp /mnt/keyusb/borg/passphrase ~/.config/borg/
   cp /mnt/keyusb/borg/patterns ~/.config/borg/
   chmod 600 ~/.config/borg/passphrase ~/.config/borg/patterns
   ```

4. If restoring from BorgBase, keep the USB mounted and continue to §1.1.
   Otherwise, unmount:

   ```sh
   sudo umount /mnt/keyusb
   sudo cryptsetup close keyusb
   ```

   Expected result: SSH and Borg material restored locally.

---

## §1.1 BorgBase Access Prep

Only needed if restoring from offsite backups. Assumes the Secrets USB is
mounted at `/mnt/keyusb`. If not, re-open and mount it as in §1 step 1.

Steps:

1. Copy BorgBase credentials from the Secrets USB:

   ```sh
   sudo install -d -m 0700 /root/.ssh /root/.config/borg-offsite
   sudo cp /mnt/keyusb/ssh-backup/borgbase-offsite-audacious /root/.ssh/borgbase-offsite-audacious
   sudo cp /mnt/keyusb/ssh-backup/borgbase-offsite-astute /root/.ssh/borgbase-offsite-astute
   sudo cp /mnt/keyusb/borg/audacious-home.passphrase /root/.config/borg-offsite/
   sudo cp /mnt/keyusb/borg/astute-critical.passphrase /root/.config/borg-offsite/
   sudo chmod 600 /root/.ssh/borgbase-offsite-audacious \
     /root/.ssh/borgbase-offsite-astute \
     /root/.config/borg-offsite/*.passphrase
   ```

2. Set environment variables for offsite commands:

   ```sh
   export BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes"
   ```

   Expected result: BorgBase repo access works from the recovery host.

---

## §2 Recover from Cold Storage

Use when you need specific files and the cold storage drive is available.

Steps:

1. Unlock and mount cold storage:

   ```sh
   sudo cryptsetup open /dev/sdX1 coldstorage
   sudo mkdir -p /mnt/cold-storage
   sudo mount /dev/mapper/coldstorage /mnt/cold-storage
   ```

2. Locate snapshots and copy required files:

   ```sh
   ls -la /mnt/cold-storage/backups/audacious/snapshots/
   cp -a /mnt/cold-storage/backups/audacious/snapshots/<date>/path/to/file ~/restored/
   ```

3. Unmount and close:

   ```sh
   sudo umount /mnt/cold-storage
   sudo cryptsetup close coldstorage
   ```

For full details, see `cold-storage-audacious/README.md`.

---

## §3 Restore Audacious from Astute

Use when Astute is online and the local Borg repository is intact (primary
restore path).

Steps:

1. Confirm access:

   ```sh
   ssh backup@astute
   borg list backup@astute:/mnt/backup/borg/audacious
   ```

2. Restore the latest archive (staged restore):

   ```sh
   sudo mkdir -p /restore
   sudo chown $USER:$USER /restore
   borg extract --numeric-owner --destination /restore \
     backup@astute:/mnt/backup/borg/audacious::$(borg list --last 1 --short backup@astute:/mnt/backup/borg/audacious)
   ```

3. Move into place after inspection:

   ```sh
   sudo rsync -aHAXv /restore/home/alchemist/ /home/alchemist/
   sudo chown -R alchemist:alchemist /home/alchemist
   ```

   Expected result: Audacious home data restored from Astute.

---

## §4 Restore from BorgBase

Use when Astute is unavailable or destroyed, and you must pull from offsite.

Steps:

1. Restore Audacious home data from BorgBase:

   ```sh
   export BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes"
   export BORG_PASSCOMMAND="cat /root/.config/borg-offsite/audacious-home.passphrase"
   borg_repo="ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo"

   sudo borg list "$borg_repo"
   sudo borg extract "${borg_repo}::audacious-home-YYYY-MM-DD" \
     home/alchemist
   ```

2. Restore Astute critical data (if rebuilding Astute):

   ```sh
   export BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-astute -T -o IdentitiesOnly=yes"
   export BORG_PASSCOMMAND="cat /root/.config/borg-offsite/astute-critical.passphrase"
   borg_repo="ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo"

   sudo borg list "$borg_repo"
   sudo borg extract "${borg_repo}::astute-critical-YYYY-MM-DD" \
     srv/nas/lucii \
     srv/nas/bitwarden-exports
   ```

   Expected result: Data recovered from offsite to a staging host or rebuilt
   Astute.

---

## §5 Post-Restore Checks

Steps:

1. Verify ZFS health:

   ```sh
   zpool status
   ```

2. Verify backups are running:

   ```sh
   systemctl list-timers | grep borg
   ```

   Expected result: Pools are healthy and backup timers are active.

---

## Recovery Workflows

### Catastrophic Loss (Fire/Flood)

Primary path:

1. Restore secrets (§1 and §1.1)
2. Rebuild Astute (`docs/astute/install-astute.md`)
3. Restore Astute data from BorgBase (§4 step 2)
4. Rebuild Audacious (`docs/audacious/install-audacious.md`)
5. Restore Audacious data from Astute (§3)
6. Post-restore checks (§5)

### Single System Loss (Hardware Failure)

**Audacious lost:**

1. Reinstall Audacious (`docs/audacious/install-audacious.md`)
2. Restore secrets (§1)
3. Restore data from Astute (§3)
4. Post-restore checks (§5)

**Astute lost:**

1. Rebuild Astute (`docs/astute/install-astute.md`)
2. Restore secrets (§1 and §1.1)
3. Restore data from BorgBase (§4 step 2)
4. Post-restore checks (§5)

### Ransomware Attack

Immediate actions:

1. Disconnect systems from the network
2. Preserve evidence (do not reboot)
3. Identify pre-infection backups

Recovery path:

1. Rebuild from clean install (host install docs)
2. Restore secrets (§1 and §1.1 if needed)
3. Restore data from clean backups (§3 or §4)
4. Rotate credentials and re-issue keys (see recovery kit maintenance doc)
5. Post-restore checks (§5)

---

## Testing Recovery Procedures

### Annual Recovery Drill

1. Restore secrets on a test machine (§1)
2. Verify BorgBase access and list archives (§4)
3. Perform a small restore and verify integrity
4. Record time taken and update RTO/RPO estimates

### Quarterly Verification

1. Run `scripts/verify-secrets-usb.sh`
2. Verify BorgBase archives exist and use append-only access
3. Verify Google Drive bundle is present and recent
4. Confirm GPG passphrase recall

---

# Data Restore Guide

Restore data for the Wolfpack in a single place. This document assumes OS and infrastructure recovery are handled in the per-host install/recovery docs.

---

## Scope and intent

Use this guide when:
- You need files from cold storage.
- Audacious is down but Astute backups are available.
- Astute is down and offsite backups are required.
- A full-loss event requires rebuilding from new hardware and the Secrets USB.

If the issue is a **single drive failure** in a pool, follow the host recovery doc first. Data restore only applies once access to backups is required.

---

## Recovery materials checklist

Have these before proceeding:
1. Secrets USB (LUKS) and passphrase.
2. SSH keys and Borg passphrase (stored on Secrets USB).
3. BorgBase credentials and repo keys (stored on Secrets USB).
4. A working machine with internet access.

If the Secrets USB is unavailable, use the trusted person USB or the Google Drive recovery bundle, then follow the same steps below.

---

## §1 Restore secrets (required for any data loss beyond a single drive)

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

4. If you will restore from BorgBase, keep the USB mounted and continue to §1.1.

5. Unmount and close:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup close keyusb
```

Expected result: SSH and Borg material restored locally.

---

## §1.1 BorgBase access prep (only if restoring from offsite)

Assumes the Secrets USB is mounted at `/mnt/keyusb`. If not, re-open and mount it as in §1 step 1.

Steps:
1. Copy BorgBase credentials from the Secrets USB:

```sh
sudo install -d -m 0700 /root/.ssh /root/.config/borg-offsite
sudo cp /mnt/keyusb/ssh-backup/borgbase_offsite /root/.ssh/
sudo cp /mnt/keyusb/borg/audacious-home.passphrase /root/.config/borg-offsite/
sudo cp /mnt/keyusb/borg/astute-critical.passphrase /root/.config/borg-offsite/
sudo chmod 600 /root/.ssh/borgbase_offsite /root/.config/borg-offsite/*.passphrase
```

2. Use `BORG_RSH` and `BORG_PASSCOMMAND` in offsite commands if needed:

```sh
export BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes"
```

Expected result: BorgBase repo access works from the recovery host.

---

## §2 Recover from cold storage (Audacious)

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

## §3 Restore Audacious data from Astute (primary path)

Use when Astute is online and the local Borg repository is intact.

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

## §4 Restore from BorgBase (Astute down)

Use when Astute is unavailable or destroyed, and you must pull from offsite.

Steps:
1. Restore the Audacious Borg repo directory from BorgBase:

```sh
sudo borg extract \
  ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo::audacious-home-YYYY-MM-DD \
  srv/backups/audacious-borg
```

2. Restore Audacious data from the recovered repo:

```sh
export BORG_REPO=/srv/backups/audacious-borg
export BORG_PASSCOMMAND="cat /root/.config/borg/passphrase"

borg list "$BORG_REPO"
borg extract "$BORG_REPO"::audacious-YYYY-MM-DD \
  home/alchemist
```

3. Restore Astute critical data (if rebuilding Astute):

```sh
sudo borg extract \
  ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo::astute-critical-YYYY-MM-DD \
  srv/nas/lucii \
  srv/nas/bitwarden-exports
```

Expected result: data recovered from offsite to a staging host or rebuilt Astute.

---

## §5 Full-loss recovery (house fire or total site loss)

Use when all local hardware is gone and you are starting from scratch.

Steps:
1. Acquire a temporary machine and internet access.
2. Retrieve the recovery bundle:
   - Trusted person USB, or
   - Google Drive bundle (GPG encrypted).
3. Follow the bundle instructions to restore secrets and BorgBase credentials.
4. Rebuild Astute first using `docs/astute/install-astute.md`.
5. Restore data from BorgBase using §4.
6. Rebuild Audacious using `docs/audacious/install-audacious.md`.
7. Restore Audacious data using §3 (from the rebuilt Astute repo).

Expected result: both hosts rebuilt with data restored from offsite.

---

## §6 Post-restore checks

Steps:
1. Verify ZFS health:

```sh
zpool status
```

2. Verify backups are running:

```sh
systemctl list-timers | grep borg
```

Expected result: pools are healthy and backup timers are active.

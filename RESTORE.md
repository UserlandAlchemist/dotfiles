# RESTORE.md — Borg Backup Recovery (audacious ↔ astute)

> **Purpose:** Fully restore system and user data to `audacious` from backups hosted on `astute`.  
> Assumes you’ve completed `RECOVERY.md` and now have a clean, bootable system.  
> Focus: verifying SSH + Borg setup, unlocking keys, mounting archives, and restoring data safely.

---

## 1️⃣ Reinstall Required Packages

```bash
sudo apt update
sudo apt install -y borgbackup openssh-client git stow
```

> Installs Borg and supporting tools for restoration.

---

## 2️⃣ Retrieve or Recreate Borg Configuration

1. Ensure your Borg configuration directory exists:

```bash
mkdir -p ~/.config/borg
```

2. Restore from dotfiles if present:

```bash
cd ~/dotfiles
stow --target=$HOME borg-user
```

This restores `~/.config/borg/passphrase` and `~/.config/borg/patterns`.

> These files define the backup decryption key and inclusion/exclusion rules.

3. If your passphrase file is lost, **stop here**. Without it, Borg archives are cryptographically inaccessible.

To verify that your key file exists and has the right permissions:

```bash
ls -l ~/.config/borg/passphrase
chmod 600 ~/.config/borg/passphrase
```

---

## 3️⃣ Confirm Access to Backup Host

1. Check SSH access to the backup host `astute`:

```bash
ssh backup@astute
```

If you cannot connect, verify your `.ssh/config` and ensure the proper key is restored or re-added:

```bash
cat ~/.ssh/config
chmod 600 ~/.ssh/config
```

2. Test Borg connectivity:

```bash
borg list backup@astute:/mnt/backup/borg/audacious
```

> You should see a list of available archives with timestamps.  
> If you see `Repository not found`, check your repository path or key file.

---

## 4️⃣ Mount and Inspect an Archive (Optional Pre-Restore)

You can mount a Borg archive to verify contents before performing a full restore:

```bash
mkdir -p ~/borg-mount
borg mount backup@astute:/mnt/backup/borg/audacious::<archive-name> ~/borg-mount
ls ~/borg-mount
```

> Inspect files, confirm structure, then unmount:

```bash
borg umount ~/borg-mount
```

---

## 5️⃣ Perform Full Restore

1. Create restore target:

```bash
sudo mkdir -p /restore
sudo chown $USER:$USER /restore
```

2. Restore from latest archive:

```bash
borg extract --numeric-owner backup@astute:/mnt/backup/borg/audacious::$(borg list --last 1 --short backup@astute:/mnt/backup/borg/audacious)
```

> `--numeric-owner` ensures correct UID/GID even if `/etc/passwd` differs from the backup source.

3. Restore specific paths if needed:

```bash
borg extract backup@astute:/mnt/backup/borg/audacious::2025-10-27T03:00 -- home/alchemist .config
```

4. Verify restored files:

```bash
ls -lah /restore/home/alchemist
```

---

## 6️⃣ Restore System Configuration (if missing)

If `/etc` or system files were part of the Borg archive, restore them carefully:

```bash
sudo rsync -aHAXv /restore/etc/ /etc/
```

Then restow configs:

```bash
cd ~/dotfiles
sudo stow --target=/ etc-systemd
sudo stow --target=/ etc-power
```

Reload services:

```bash
sudo systemctl daemon-reload
sudo systemctl restart efi-sync.path powertop.service usb-nosuspend.service
```

---

## 7️⃣ Validate Restore Integrity

Run a quick integrity check of the restored data:

```bash
borg check --verify-data backup@astute:/mnt/backup/borg/audacious
```

> This ensures the repository and archive data are not corrupted.

Then verify locally restored files:

```bash
find /restore -type f | wc -l
zpool status
```

---

## 8️⃣ Clean Up and Return to Normal Operation

Unmount and remove restore directory if no longer needed:

```bash
sudo rm -rf /restore
```

Confirm all services active:

```bash
systemctl list-units | grep -E 'borg|efi-sync|powertop'
```

Reboot to confirm clean boot:

```bash
sudo reboot
```

---

## ✅ Post-Restore Checklist

After reboot:

- Verify SSH access to `astute` still works.
- Check Borg timer jobs:

```bash
systemctl list-timers | grep borg
```

- Ensure restored data matches expected layout (`~/dotfiles`, `~/Documents`, etc.).
- Optionally trigger a manual backup to confirm repository health:

```bash
sudo systemctl start borg-backup.service
journalctl -u borg-backup.service -n 20
```

If backup completes without errors — system restoration is successful.


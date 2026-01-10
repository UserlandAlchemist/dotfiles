# cold-storage-audacious

Monthly cold storage snapshots with manual reminder timer.

**Device:** 931.5GB external HDD (/dev/sda1)
**UUID:** 21462e69-569e-4dad-9ab0-88a3b7c8919c
**Encryption:** LUKS
**Mount point:** /mnt/cold-storage
**Retention:** 12 monthly snapshots

---

## Layout

Snapshots live on the cold storage mount:

```text
/mnt/cold-storage/backups/audacious/
├── latest/              # current mirror
└── snapshots/YYYY-MM/   # monthly snapshots (hard-link based)
```

---

## Monthly Backup Procedure

### 1. Connect and Identify Drive

Connect external HDD to Audacious. Verify device:

```bash
lsblk
```

Expected: /dev/sda (931.5G disk) with /dev/sda1 partition.

### 2. Unlock LUKS Encryption

```bash
sudo cryptsetup luksOpen /dev/sda1 coldstorage
```

Enter cold storage passphrase when prompted (stored in password manager).

### 3. Mount Drive

```bash
sudo mkdir -p /mnt/cold-storage
sudo mount /dev/mapper/coldstorage /mnt/cold-storage
```

Verify mount:

```bash
findmnt /mnt/cold-storage
ls -la /mnt/cold-storage/backups/audacious/
```

### 4. Run Backup Script

```bash
cold-storage-backup.sh
```

Expected result: New `snapshots/YYYY-MM` directory created, `latest` mirror updated.

Verify:

```bash
ls -la /mnt/cold-storage/backups/audacious/snapshots/
```

### 5. Unmount and Lock

```bash
sudo umount /mnt/cold-storage
sudo cryptsetup luksClose coldstorage
```

Verify closure:

```bash
ls /dev/mapper/coldstorage 2>&1
```

Expected: "No such file or directory"

Physically disconnect external HDD.

---

## Reminder Timer

Enable monthly reminder that notifies you to run backup:

```bash
systemctl --user daemon-reload
systemctl --user enable --now cold-storage-reminder.timer
systemctl --user list-timers | grep cold-storage
```

The reminder fires on the 1st of each month. Run backup procedure when notified.

---

## Backup Script Details

**Sources backed up:**

- /home/alchemist/personal
- /home/alchemist/projects
- /home/alchemist/Documents
- /home/alchemist/Pictures
- /home/alchemist/Music
- /home/alchemist/Videos
- /home/alchemist/dotfiles

**Excluded:**

- Downloads/
- .cache/
- .local/share/Trash/
- node_modules/
- .venv/
- target/ (Rust)
- __pycache__/

**Method:** rsync with --link-dest for deduplication (unchanged files
hardlinked to previous snapshot).

**Retention:** Keeps 12 most recent monthly snapshots, auto-prunes older.

---

## Restore from Cold Storage

### List Available Snapshots

```bash
# Mount drive first (steps 2-3 above)
ls -1 /mnt/cold-storage/backups/audacious/snapshots/
```

### Restore Specific Files

From monthly snapshot:

```bash
cp -a /mnt/cold-storage/backups/audacious/snapshots/2026-01/path/to/file ~/restored/
```

From latest mirror:

```bash
rsync -av /mnt/cold-storage/backups/audacious/latest/dotfiles/ ~/dotfiles-restored/
```

---

## Troubleshooting

**Drive not detected (no /dev/sda):**

- Check USB cable connection
- Try different USB port
- Wait 5 seconds for kernel detection
- Check: `dmesg | tail -20`

**"Device or resource busy" when unmounting:**

1. Find processes: `lsof /mnt/cold-storage`
2. Close applications
3. Force unmount if safe: `sudo umount -l /mnt/cold-storage`

**Wrong LUKS passphrase or won't unlock:**

- Verify passphrase in password manager (case-sensitive)
- Check device: `sudo cryptsetup luksDump /dev/sda1`
- If corruption suspected, DO NOT FORMAT - seek data recovery

**Backup script fails "not mounted":**

- Mount drive first (steps 2-3)
- Verify: `findmnt /mnt/cold-storage`

**Snapshot not created:**

- Check disk space: `df -h /mnt/cold-storage`
- Verify write permissions: `touch /mnt/cold-storage/test && rm /mnt/cold-storage/test`

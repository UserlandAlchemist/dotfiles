# RESTORE.md

> Full disaster recovery procedure for Audacious  
> (restoring `/home/alchemist` from Borg backups on Astute)

---

## 1. Reinstall Debian and base environment

Follow `INSTALL.md` **through Section 14** to reach a functioning system with:
- ZFS root (`rpool`)
- Network access
- `alchemist` user with `sudo`
- SSH client tools (`openssh-client`)
- Dotfiles repo cloned to `~/dotfiles`

Do **not** stow configs yet.

---

## 2. Install BorgBackup

```bash
sudo apt install -y borgbackup
```

Create Borg config directories:

```bash
mkdir -p ~/.config/borg/security
```

Restore or recreate the passphrase file:

```bash
nano ~/.config/borg/passphrase
chmod 600 ~/.config/borg/passphrase
```

> Retrieve the passphrase from **Bitwarden**  
> (stored as “Borg passphrase – Audacious”).  
> This file is required to access the repository.

If your dotfiles repo is already restored, you may instead:

```bash
stow borg-user
```

---

## 3. Restore SSH keys and access to Astute

Your Borg repository lives at  
`ssh://alchemist@astute:/srv/borg/audacious`.

### 3.1 Retrieve keys from encrypted USB

1. Plug in the **blue USB key** (`/dev/sdb`, ≈ 29 GB).  
2. Open and mount it:

   ```bash
   sudo cryptsetup open /dev/sdb secure-usb
   sudo mount /dev/mapper/secure-usb /mnt/secure-usb
   ls /mnt/secure-usb/ssh-backup
   ```

3. Copy your keys back:

   ```bash
   mkdir -p ~/.ssh
   cp -a /mnt/secure-usb/ssh-backup/* ~/.ssh/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/audacious-backup ~/.ssh/id_alchemist
   ```

4. Close the USB drive once done:

   ```bash
   sudo umount /mnt/secure-usb
   sudo cryptsetup close secure-usb
   ```

### 3.2 Test connectivity

```bash
ssh alchemist@astute
```

You should connect without a password.  
If prompted about authenticity, verify the fingerprint before accepting.

---

## 4. Verify the Borg repository

Confirm access:

```bash
borg list ssh://alchemist@astute:/srv/borg/audacious
```

Expected output:

```
audacious-2025-10-26T12:00:05 Sat, 2025-10-26 12:00:05 [hash] ...
```

If it fails, check:
- Network connectivity (`ping astute`)
- SSH setup
- Correct passphrase permissions

---

## 5. Restore your home directory

Create a restore directory:

```bash
mkdir ~/restore
cd ~/restore
```

Extract the most recent archive:

```bash
borg extract --numeric-owner ssh://alchemist@astute:/srv/borg/audacious::latest
```

This recreates `/home/alchemist` within `./home/alchemist`.

To restore directly in place:

```bash
cd /
sudo borg extract --numeric-owner ssh://alchemist@astute:/srv/borg/audacious::latest home/alchemist
```

Fix ownerships:

```bash
sudo chown -R alchemist:alchemist /home/alchemist
```

---

## 6. Re-stow dotfiles and re-enable backup services

```bash
cd ~/dotfiles
stow bash bin emacs fonts foot lf mako sway waybar wofi zathura borg-user
sudo stow -t / backup-systemd
sudo systemctl enable --now borg-backup.timer borg-check.timer
```

Confirm timers:

```bash
systemctl list-timers | grep borg
```

---

## 7. Verify operation

- Log out/in to ensure desktop and shell configs load.  
- Trigger a manual backup:

  ```bash
  sudo systemctl start borg-backup.service
  journalctl -u borg-backup.service -n 20
  ```

---

## 8. Reference details

| Component | Setting |
|------------|----------|
| **Repository** | `ssh://alchemist@astute:/srv/borg/audacious` |
| **Scope** | `/home/alchemist` only |
| **Backup schedule** | 00:00 · 06:00 · 12:00 · 18:00 (local) – *no catch-up on boot* |
| **Integrity check** | Sunday 04:30 – *catches up if missed* |
| **Passphrase** | Stored in Bitwarden (“Borg passphrase – Audacious”) |
| **SSH keys** | On encrypted USB (`audacious-backup`, `id_alchemist`) |
| **Repository key export** | `audacious-borg-repokey-export.txt` on encrypted USB |
| **Restoration test** | `borg extract --dry-run ssh://alchemist@astute:/srv/borg/audacious::latest` |

---

## Appendix A — Encrypted USB key (blue drive)

The blue USB stick (`/dev/sdb`, ≈ 29 GB) stores offline credentials.

### A.1 Initialize (first-time setup)

```bash
sudo apt install -y cryptsetup
sudo cryptsetup luksFormat /dev/sdb
sudo cryptsetup open /dev/sdb secure-usb
sudo mkfs.ext4 -L SECUREKEYS /dev/mapper/secure-usb
sudo mkdir -p /mnt/secure-usb
sudo mount /dev/mapper/secure-usb /mnt/secure-usb
```

### A.2 Copy credentials

```bash
sudo mkdir -p /mnt/secure-usb/ssh-backup
sudo cp -a ~/.ssh/audacious-backup ~/.ssh/audacious-backup.pub /mnt/secure-usb/ssh-backup/
sudo cp -a ~/.ssh/id_alchemist ~/.ssh/id_alchemist.pub /mnt/secure-usb/ssh-backup/
sudo cp ~/.ssh/config ~/.ssh/known_hosts /mnt/secure-usb/ssh-backup/
sudo cp ~/.config/borg/passphrase /mnt/secure-usb/
sudo cp ~/audacious-borg-repokey-export.txt /mnt/secure-usb/
sudo chmod 600 /mnt/secure-usb/ssh-backup/audacious-backup /mnt/secure-usb/ssh-backup/id_alchemist
sudo chmod 600 /mnt/secure-usb/audacious-borg-repokey-export.txt
```

Optional extras:
```bash
sudo cp -a ~/.config/borg/security /mnt/secure-usb/borg-security
sudo cp -a ~/.gnupg /mnt/secure-usb/gnupg 2>/dev/null || true
sudo cp ~/dotfiles/RESTORE.md ~/dotfiles/RECOVERY.md /mnt/secure-usb/
sudo zpool status > ~/zfs-status.txt && sudo zpool get all > ~/zfs-properties.txt
sudo cp ~/zfs-*.txt /mnt/secure-usb/
```

Then:

```bash
sudo umount /mnt/secure-usb
sudo cryptsetup close secure-usb
```
---

**End of RESTORE.md**

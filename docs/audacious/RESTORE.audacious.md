# RESTORE.audacious.md — Full disaster recovery for Audacious

> Goal: Restore `/home/alchemist` and system services on `audacious`
> using Borg backups stored on `astute`.
> Assumes:
> - You can boot `audacious` (see RECOVERY.audacious.md first)
> - You have physical access to the blue encrypted USB key
> - You can reach `astute` over the network

---

## 1️⃣ Base system prerequisites

Before you continue, you should already have (from INSTALL.audacious.md, up through Sway + dotfiles clone):
- ZFS root (`rpool`) imported and mounted
- Working network
- User `alchemist` with sudo
- `~/dotfiles` cloned (but stow may not be re-run yet)
- SSH client tools (`openssh-client`)

If you do NOT have that, stop and run through RECOVERY first.

---

## 2️⃣ Install required packages

```bash
sudo apt update
sudo apt install -y borgbackup openssh-client git stow rsync cryptsetup
```

This gives you:
- BorgBackup (to pull archives)
- SSH (to talk to astute)
- stow (to reapply configs)
- rsync (for selective restore)
- cryptsetup (to unlock the blue USB key)

---

## 3️⃣ Restore Borg credentials

Borg needs its passphrase and patterns to decrypt and extract.

1. Ensure the config dir exists:

```bash
mkdir -p ~/.config/borg
```

2. If dotfiles are already present, restore per-host borg config:

```bash
cd ~/dotfiles
stow --target=$HOME borg-user-audacious
```

That should give you:
- `~/.config/borg/passphrase`
- `~/.config/borg/patterns`

3. Lock down permissions:

```bash
chmod 600 ~/.config/borg/passphrase
```

If for some reason `borg-user-audacious` is not available yet,
you can manually recreate `~/.config/borg/passphrase` from Bitwarden
(“Borg passphrase – Audacious”), then `chmod 600` it.

---

## 4️⃣ Restore SSH keys from the blue encrypted USB key

You cannot reach the Borg repo on `astute` until you have working SSH keys.

Your keys, SSH config, Borg repo export key, and other secrets are stored on the
encrypted blue USB key (~29GB). We’re going to unlock it, mount it, copy the keys,
fix permissions, and close it again.

1. Identify the USB device:

```bash
lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
```

Assume it shows up as `/dev/sdb`.

2. Unlock the LUKS volume and mount it:

```bash
sudo cryptsetup open /dev/sdb secure-usb
sudo mkdir -p /mnt/secure-usb
sudo mount /dev/mapper/secure-usb /mnt/secure-usb
ls /mnt/secure-usb/ssh-backup
```

`ssh-backup/` should contain keys like `audacious-backup`, `id_alchemist`,
their `.pub` counterparts, `config`, etc.
The USB may also contain:
- `audacious-borg-repokey-export.txt`
- a copy of `~/.config/borg/passphrase`
- copies of these recovery docs

3. Restore SSH material:

```bash
mkdir -p ~/.ssh
cp -a /mnt/secure-usb/ssh-backup/* ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

That enforces permissions so OpenSSH doesn’t refuse to use the keys.

4. (Optional but recommended) restore Borg repo key export:

```bash
cp /mnt/secure-usb/audacious-borg-repokey-export.txt ~/
chmod 600 ~/audacious-borg-repokey-export.txt
```

5. Cleanly detach the USB:

```bash
sudo umount /mnt/secure-usb
sudo cryptsetup close secure-usb
```

At this point you should have:
- valid SSH keys in `~/.ssh`
- `~/.ssh/config` with host entries
- Borg passphrase in `~/.config/borg/passphrase`

---

## 5️⃣ Confirm connectivity to astute and Borg repo

1. Test SSH:

```bash
ssh backup@astute
```

You should get in without a password prompt.
If you’re asked about host authenticity, confirm the fingerprint
before accepting.

If SSH complains about permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
chmod 600 ~/.ssh/config
```

2. List the Borg archives:

```bash
borg list backup@astute:/mnt/backup/borg/audacious
```

You should see timestamped archives.
If you get `Repository not found` or permission denied, check:
- You used `backup@astute`, not `alchemist@astute`
- The repo path is `/mnt/backup/borg/audacious`
- The Borg passphrase file exists and is chmod 600

---

## 6️⃣ Inspect an archive (optional sanity check)

You can mount an archive read-only before extracting:

```bash
mkdir -p ~/borg-mount
borg mount backup@astute:/mnt/backup/borg/audacious::<archive-name> ~/borg-mount
ls ~/borg-mount
borg umount ~/borg-mount
```

This lets you browse what you’re about to restore.

---

## 7️⃣ Restore data

You have two patterns: staged restore or in-place restore.

### 7.1 Staged restore (safe / inspect first)

```bash
sudo mkdir -p /restore
sudo chown $USER:$USER /restore

borg extract --numeric-owner --destination /restore \
    backup@astute:/mnt/backup/borg/audacious::$(borg list --last 1 --short backup@astute:/mnt/backup/borg/audacious)
```

After this, `/restore/home/alchemist` should exist.

You can inspect it first:

```bash
ls -lah /restore/home/alchemist
```

### 7.2 Direct in-place restore (fast)

```bash
sudo borg extract --numeric-owner \
    backup@astute:/mnt/backup/borg/audacious::$(borg list --last 1 --short backup@astute:/mnt/backup/borg/audacious) \
    home/alchemist
```

Then fix ownership:

```bash
sudo chown -R alchemist:alchemist /home/alchemist
```

### 7.3 Selective restore of only certain paths

```bash
borg extract backup@astute:/mnt/backup/borg/audacious::<archive-name> \
    home/alchemist/Documents \
    home/alchemist/.config
```

Replace `<archive-name>` with the timestamp you want.

---

## 8️⃣ Restore system configuration and services

If `/etc` or system units are damaged, reapply them.

1. If you used `/restore` and it contains `/etc`, sync it:

```bash
sudo rsync -aHAXv /restore/etc/ /etc/
```

2. Re-stow host-level configs for Audacious:

```bash
cd ~/dotfiles
sudo stow --target=/ etc-systemd-audacious
sudo stow --target=/ etc-power-audacious
sudo stow --target=/ etc-cachyos-audacious
sudo stow --target=/ backup-systemd-audacious
```

These restore:
- power tuning (`powertop.service`, `usb-nosuspend.service`)
- EFI sync for dual ESPs (`efi-sync.path`)
- kernel/sysctl/scheduler tuning
- borg backup/check timers

3. Reload/enable services:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now \
    powertop.service \
    usb-nosuspend.service \
    efi-sync.path \
    borg-backup.timer \
    borg-check.timer \
    borg-check-deep.timer
```

4. Reload udev rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

5. Confirm timers:

```bash
systemctl list-timers | grep borg
```

You should see:
- regular backup timers (multiple times/day)
- integrity check timers (daily/weekly deep check)

---

## 9️⃣ Final checks

1. Check ZFS health:

```bash
zpool status
```

2. Check critical services:

```bash
systemctl list-units | grep -E 'efi-sync|powertop|usb-nosuspend|borg'
```

3. Log out and log back in on TTY1:
   - sway should autostart
   - waybar should be visible
   - mako should display notifications
   - power tuning should be applied
   - EFI sync should be active

4. Trigger a manual backup to prove end-to-end:

```bash
sudo systemctl start borg-backup.service
journalctl -u borg-backup.service -n 20
```

If the manual backup succeeds and timers are scheduled, recovery is complete.

---

## 🔐 Appendix A — Blue USB recovery key

The blue USB stick (~29 GB) is an encrypted LUKS volume that stores:
- SSH keys (e.g. `audacious-backup`, `id_alchemist`)
- `~/.ssh/config` and `known_hosts`
- Borg passphrase
- exported Borg repository key (`audacious-borg-repokey-export.txt`)
- copies of these recovery docs
- optional snapshots of `~/.config/borg/security` and `~/.gnupg`

### A.1 Unlock + mount

```bash
sudo cryptsetup open /dev/sdb secure-usb
sudo mkdir -p /mnt/secure-usb
sudo mount /dev/mapper/secure-usb /mnt/secure-usb
```

### A.2 Re-seal

After copying what you need:

```bash
sudo umount /mnt/secure-usb
sudo cryptsetup close secure-usb
```

Keep this drive physically safe. It is effectively root-of-trust for both SSH access to `astute` and Borg decryption.
# Debian 13 (Trixie) on ZFS - Borg Restore Guide

**Purpose:** Restore audacious user data and services from Borg backups on astute.
**Prereqs:** System boots (see `RECOVERY.audacious.md`) and network is up.
**Secrets:** Blue encrypted USB key contains SSH keys and Borg material.

---

## §1 Pre-restore prerequisites

Confirm baseline system access before pulling backups.

Steps:
1. Verify you can log in as `alchemist`.
2. Ensure `~/dotfiles` is cloned.
3. Confirm network connectivity to astute.

Expected result: login, repo access, and network are ready.

---

## §2 Install required packages

Install the tools needed for Borg and USB unlock.

Steps:
1. Install packages:

```sh
sudo apt update
sudo apt install -y borgbackup openssh-client git stow rsync cryptsetup
```

Expected result: Borg, SSH, stow, rsync, and cryptsetup are available.

---

## §3 Restore Borg credentials

Borg needs the passphrase and patterns to decrypt and extract.

Steps:
1. Ensure the config directory exists:

```sh
mkdir -p ~/.config/borg
```

2. If dotfiles are present, stow Borg config:

```sh
cd ~/dotfiles
stow --target=$HOME borg-user-audacious
```

3. Lock down permissions:

```sh
chmod 600 ~/.config/borg/passphrase
```

If `borg-user-audacious` is not available, recreate `~/.config/borg/passphrase`
from the blue USB or Bitwarden, then `chmod 600` it.

Expected result: passphrase and patterns exist with correct permissions.

---

## §4 Restore SSH keys from the blue USB

Unlock the USB key to recover SSH material and Borg repo exports.

Steps:
1. Identify the USB device:

```sh
lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
```

2. Unlock and mount (example uses `/dev/sdb`):

```sh
sudo cryptsetup open /dev/sdb secure-usb
sudo mkdir -p /mnt/secure-usb
sudo mount /dev/mapper/secure-usb /mnt/secure-usb
ls /mnt/secure-usb/ssh-backup
```

3. Restore SSH material:

```sh
mkdir -p ~/.ssh
cp -a /mnt/secure-usb/ssh-backup/* ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

4. Restore Borg repo key export (optional):

```sh
cp /mnt/secure-usb/audacious-borg-repokey-export.txt ~/
chmod 600 ~/audacious-borg-repokey-export.txt
```

5. Unmount and close:

```sh
sudo umount /mnt/secure-usb
sudo cryptsetup close secure-usb
```

Expected result: SSH keys are in `~/.ssh` and the USB is closed.

---

## §5 Verify access to astute

Confirm SSH and repository access before extracting.

Steps:
1. Test SSH:

```sh
ssh backup@astute
```

2. Fix permissions if prompted:

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
chmod 600 ~/.ssh/config
```

3. List Borg archives:

```sh
borg list backup@astute:/mnt/backup/borg/audacious
```

Expected result: archives list successfully without password prompts.

---

## §6 Inspect an archive (optional)

Mount an archive read-only before extraction.

Steps:
1. Mount:

```sh
mkdir -p ~/borg-mount
borg mount backup@astute:/mnt/backup/borg/audacious::<archive-name> ~/borg-mount
```

2. Browse and unmount:

```sh
ls ~/borg-mount
borg umount ~/borg-mount
```

Expected result: archive contents are visible and unmounted cleanly.

---

## §7 Restore data

Choose a restore mode based on how much you want to inspect first.

### §7.1 Staged restore (inspect first)

Steps:
1. Extract to `/restore`:

```sh
sudo mkdir -p /restore
sudo chown $USER:$USER /restore
borg extract --numeric-owner --destination /restore \
  backup@astute:/mnt/backup/borg/audacious::$(borg list --last 1 --short backup@astute:/mnt/backup/borg/audacious)
```

2. Inspect:

```sh
ls -lah /restore/home/alchemist
```

Expected result: restored data exists under `/restore/home/alchemist`.

### §7.2 Direct in-place restore

Steps:
1. Extract into `/home`:

```sh
sudo borg extract --numeric-owner \
  backup@astute:/mnt/backup/borg/audacious::$(borg list --last 1 --short backup@astute:/mnt/backup/borg/audacious) \
  home/alchemist
```

2. Fix ownership:

```sh
sudo chown -R alchemist:alchemist /home/alchemist
```

Expected result: user data is restored in place with correct ownership.

### §7.3 Selective restore

Steps:
1. Extract specific paths:

```sh
borg extract backup@astute:/mnt/backup/borg/audacious::<archive-name> \
  home/alchemist/Documents \
  home/alchemist/.config
```

Expected result: selected paths are restored from the chosen archive.

---

## §8 Restore system services

Reapply system configs if `/etc` or units were damaged.

Steps:
1. If `/restore` contains `/etc`, sync it:

```sh
sudo rsync -aHAXv /restore/etc/ /etc/
```

2. Restow system packages:

```sh
cd ~/dotfiles
sudo stow -t / root-power-audacious root-audacious-efisync \
  root-cachyos-audacious root-network-audacious \
  root-backup-audacious root-proaudio-audacious
sudo root-sudoers-audacious/install.sh
```

3. Reload and enable services:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service usb-nosuspend.service efi-sync.path
sudo systemctl enable --now borg-backup.timer borg-check.timer borg-check-deep.timer
sudo systemctl enable --now zfs-trim-monthly@rpool.timer
sudo systemctl enable --now zfs-scrub-monthly@rpool.timer
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo sysctl --system
```

4. Confirm timers:

```sh
systemctl list-timers | grep borg
```

Expected result: systemd timers are active and configs are in place.

---

## §9 Final validation

Confirm health and backup functionality after restore.

Steps:
1. Check ZFS health:

```sh
zpool status
```

2. Check critical services:

```sh
systemctl list-units | grep -E 'efi-sync|powertop|usb-nosuspend|borg'
```

3. Trigger a manual backup:

```sh
sudo systemctl start borg-backup.service
journalctl -u borg-backup.service -n 20
```

Expected result: ZFS is healthy and a manual backup completes.

---

## Appendix A: Blue USB contents

The blue USB key stores:
- SSH keys (`audacious-backup`, `id_alchemist`)
- `~/.ssh/config` and `known_hosts`
- Borg passphrase
- Borg repo key export (`audacious-borg-repokey-export.txt`)
- Copies of recovery docs


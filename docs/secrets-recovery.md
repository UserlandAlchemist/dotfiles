# Secrets Recovery Guide

Emergency restore of secrets required to access hosts and backups. Creation and maintenance live in `docs/secrets-maintenance.md`.

---

## Preconditions

- Working system with sudo access
- Secrets USB (or trusted copy / recovery bundle)
- Network access for GitHub and BorgBase

---

## §1 Restore secrets (primary path)

Steps:
1. Install required packages:

```sh
sudo apt update
sudo apt install -y cryptsetup git
```

2. Mount the Secrets USB:

```sh
lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mkdir -p /mnt/keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

3. Read the quick-start file:

```sh
cat /mnt/keyusb/QUICK-START.txt
```

4. Restore SSH keys and config:

```sh
mkdir -p ~/.ssh
cp -a /mnt/keyusb/ssh-backup/* ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

5. Restore Borg passphrase and patterns:

```sh
mkdir -p ~/.config/borg
cp /mnt/keyusb/borg/passphrase ~/.config/borg/
cp /mnt/keyusb/borg/patterns ~/.config/borg/
chmod 600 ~/.config/borg/passphrase ~/.config/borg/patterns
```

6. Restore API tokens (if applicable):

```sh
mkdir -p ~/.config/jellyfin
cp /mnt/keyusb/tokens/jellyfin/api.token ~/.config/jellyfin/ 2>/dev/null || true
```

7. Restore BorgBase credentials if offsite recovery is required:

```sh
sudo install -d -m 0700 /root/.ssh /root/.config/borg-offsite
sudo cp /mnt/keyusb/ssh-backup/borgbase_offsite /root/.ssh/
sudo cp /mnt/keyusb/borg/audacious-home.passphrase /root/.config/borg-offsite/
sudo cp /mnt/keyusb/borg/astute-critical.passphrase /root/.config/borg-offsite/
sudo chmod 600 /root/.ssh/borgbase_offsite /root/.config/borg-offsite/*.passphrase
```

8. Unmount and close:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: SSH access and Borg credentials restored, ready to install and restore data.

---

## §2 If the Secrets USB is unavailable

Use the trusted person USB or Google Drive bundle to recreate the Secrets USB contents, then follow §1.
See `docs/secrets-maintenance.md` for bundle preparation and Trusted USB procedures.

---

## §3 Next steps

1. Rebuild hosts: `docs/audacious/install.audacious.md` and `docs/astute/install.astute.md`
2. Restore data: `docs/data-restore.md`

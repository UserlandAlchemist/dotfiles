# Secrets Maintenance Guide

Create, update, and verify the Secrets USB and trusted copies. Emergency restore steps live in `docs/secrets-recovery.md`.

---

## Quick Tasks

### Trusted person USB quick update

Use when a trusted person is on-site and you need a fresh copy quickly.

Steps:
1. Mount the Secrets USB (primary):

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mkdir -p /mnt/keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Mount the trusted person USB:

```sh
sudo cryptsetup luksOpen /dev/sdY1 trustedusb
sudo mkdir -p /mnt/trustedusb
sudo mount /dev/mapper/trustedusb /mnt/trustedusb
```

3. Copy everything:

```sh
rsync -aHAXv /mnt/keyusb/ /mnt/trustedusb/
sync
```

4. Unmount both:

```sh
sudo umount /mnt/keyusb /mnt/trustedusb
sudo cryptsetup luksClose keyusb
sudo cryptsetup luksClose trustedusb
```

Expected result: trusted person USB contains a fresh copy of the Secrets USB.

---

## §1 Create encrypted USB

Initial setup of Secrets USB with LUKS encryption.

Prerequisites:
- USB flash drive (8GB minimum, 16GB+ recommended)
- Strong passphrase (25+ characters, stored in password manager)

**DANGER:** This will erase all data on the USB drive. Verify device name carefully.

Steps:
1. Identify device:

```sh
lsblk
```

2. Verify device:

```sh
sudo fdisk -l /dev/sdX
```

3. Unmount if auto-mounted:

```sh
sudo umount /dev/sdX1 2>/dev/null || true
```

4. Create GPT and partition:

```sh
sudo parted /dev/sdX mklabel gpt
sudo parted /dev/sdX mkpart primary 1MiB 100%
```

5. Encrypt and format:

```sh
sudo cryptsetup luksFormat /dev/sdX1
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mkfs.ext4 -L "BLUE_USB_RECOVERY" /dev/mapper/keyusb
```

6. Create directory structure:

```sh
sudo mkdir -p /mnt/keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
sudo mkdir -p /mnt/keyusb/{ssh-backup,borg,pgp,docs,tokens}
sudo chown -R $(id -u):$(id -g) /mnt/keyusb
```

7. Write a marker:

```sh
echo "Secrets USB Recovery - Created $(date)" > /mnt/keyusb/README.txt
```

Expected result: encrypted USB mounted and ready for population.

---

## §2 Populate Secrets USB

### §2.1 SSH Keys

```sh
cp ~/.ssh/id_alchemist /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_alchemist.pub /mnt/keyusb/ssh-backup/
cp ~/.ssh/audacious-backup /mnt/keyusb/ssh-backup/
cp ~/.ssh/audacious-backup.pub /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_ed25519_astute_nas /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_ed25519_astute_nas.pub /mnt/keyusb/ssh-backup/
cp -L ~/.ssh/config /mnt/keyusb/ssh-backup/
```

Document passphrases:

```sh
cat > /mnt/keyusb/ssh-backup/PASSPHRASES.txt <<EOF
id_alchemist passphrase: [ENTER MAIN SSH KEY PASSPHRASE HERE]

Date created: $(date +%Y-%m-%d)
Host: $(hostname)
User: $(whoami)

Public key fingerprints for verification:
$(ssh-keygen -lf ~/.ssh/id_alchemist.pub)
$(ssh-keygen -lf ~/.ssh/audacious-backup.pub)
$(ssh-keygen -lf ~/.ssh/id_ed25519_astute_nas.pub)
EOF
```

### §2.2 Borg passphrase and patterns

```sh
cp ~/.config/borg/passphrase /mnt/keyusb/borg/
cp -L ~/.config/borg/patterns /mnt/keyusb/borg/patterns
borg key export borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

### §2.3 BorgBase keys and credentials

Use `docs/offsite-backup.md` to export BorgBase repo keys and copy the SSH key and passphrases to:
- `/mnt/keyusb/ssh-backup/borgbase_offsite`
- `/mnt/keyusb/borg/audacious-home-key.txt`
- `/mnt/keyusb/borg/astute-critical-key.txt`
- `/mnt/keyusb/borg/audacious-home.passphrase`
- `/mnt/keyusb/borg/astute-critical.passphrase`

### §2.4 PGP keys

```sh
gpg --armor --export alchemist@userlandlab.org > /mnt/keyusb/pgp/alchemist_public.asc
gpg --armor --export-secret-keys alchemist@userlandlab.org > /mnt/keyusb/pgp/alchemist_private.asc
gpg --output /mnt/keyusb/pgp/alchemist_revocation.asc --gen-revoke alchemist@userlandlab.org

gpg --armor --export private@example.invalid > /mnt/keyusb/pgp/private_public.asc
gpg --armor --export-secret-keys private@example.invalid > /mnt/keyusb/pgp/private_private.asc
gpg --output /mnt/keyusb/pgp/private_revocation.asc --gen-revoke private@example.invalid
```

```sh
chmod 600 /mnt/keyusb/pgp/*_private.asc /mnt/keyusb/pgp/*_revocation.asc
chmod 644 /mnt/keyusb/pgp/*_public.asc
```

### §2.5 API tokens

```sh
if [ -f ~/.config/jellyfin/api.token ]; then
  cp ~/.config/jellyfin/api.token /mnt/keyusb/tokens/
fi

cat > /mnt/keyusb/tokens/README.txt <<EOF
API Tokens and Credentials
==========================

jellyfin/api.token - Jellyfin server API access (idle-shutdown.sh remote playback check)
EOF
```

### §2.6 Recovery documentation copies

```sh
mkdir -p /mnt/keyusb/docs
cp ~/dotfiles/docs/secrets-recovery.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/secrets-maintenance.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/data-restore.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/audacious/install-audacious.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/audacious/recovery-audacious.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/astute/install-astute.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/astute/recovery-astute.md /mnt/keyusb/docs/
```

### §2.7 Recovery quick-start

```sh
cat > /mnt/keyusb/QUICK-START.txt <<'EOF'
SECRETS USB RECOVERY QUICK-START
=================================

1. MOUNT THIS USB:
   sudo cryptsetup luksOpen /dev/sdX1 keyusb
   sudo mount /dev/mapper/keyusb /mnt/keyusb

2. RESTORE SSH KEYS:
   mkdir -p ~/.ssh
   cp /mnt/keyusb/ssh-backup/id_alchemist ~/.ssh/
   cp /mnt/keyusb/ssh-backup/audacious-backup ~/.ssh/
   cp /mnt/keyusb/ssh-backup/id_ed25519_astute_nas ~/.ssh/
   cp /mnt/keyusb/ssh-backup/config ~/.ssh/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_* ~/.ssh/audacious-backup
   chmod 644 ~/.ssh/config

3. RESTORE BORG PASSPHRASE:
   mkdir -p ~/.config/borg
   cp /mnt/keyusb/borg/passphrase ~/.config/borg/
   cp /mnt/keyusb/borg/patterns ~/.config/borg/
   chmod 600 ~/.config/borg/passphrase ~/.config/borg/patterns

4. RESTORE API TOKENS:
   mkdir -p ~/.config/jellyfin
   cp /mnt/keyusb/tokens/jellyfin/api.token ~/.config/jellyfin/ 2>/dev/null || true

5. CLONE DOTFILES:
   cd ~
   git clone git@github.com:UserlandAlchemist/dotfiles.git

6. NEXT:
   - Install: docs/audacious/install-audacious.md or docs/astute/install-astute.md
   - Restore data: docs/data-restore.md
EOF
```

---

### §2.8 Recovery bundle (Google Drive)

Create an encrypted bundle for off-site access when the Secrets USB is unavailable.

Prereq: Secrets USB mounted at `/mnt/keyusb`.

Steps:
1. Run the bundle script:

```sh
scripts/create-gdrive-recovery-bundle.sh
```

2. Upload the generated `.gpg` file to Google Drive (path is printed by the script).

Expected result: encrypted recovery bundle stored off-site.

---

## §3 Update cadence

Update the Secrets USB when:
- SSH keys rotate
- Borg passphrases change
- BorgBase credentials change
- Tokens are added or updated
- Recovery docs change substantially
 - Google Drive bundle needs refresh

Steps:
1. Mount the Secrets USB.
2. Update relevant files.
3. Record update in `/mnt/keyusb/README.txt`.
4. Unmount and close.

---

## §4 Verification

Run quarterly or before major travel.

Steps:
1. Mount the Secrets USB.
2. Verify file list and spot-check reads:

```sh
ls -la /mnt/keyusb
cat /mnt/keyusb/QUICK-START.txt
```

3. Record verification:

```sh
echo "Verified: $(date) - All secrets present and readable" >> /mnt/keyusb/README.txt
sync
```

4. Unmount and close.

---

## §5 Troubleshooting

### "No key available with this passphrase"

1. Verify the device name with `sudo fdisk -l /dev/sdX`.
2. Retry the passphrase.
3. If lost, regenerate secrets and create a new USB.

### "cannot mount: wrong fs type"

1. Confirm `cryptsetup luksOpen` succeeded.
2. Mount `/dev/mapper/keyusb`.

### Read-only or permission errors

```sh
sudo umount /mnt/keyusb
sudo e2fsck -f /dev/mapper/keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

---

## Appendix A: Secrets USB File Structure

```
/mnt/keyusb/
├── README.txt
├── QUICK-START.txt
├── ssh-backup/
│   ├── id_alchemist
│   ├── id_alchemist.pub
│   ├── audacious-backup
│   ├── audacious-backup.pub
│   ├── id_ed25519_astute_nas
│   ├── id_ed25519_astute_nas.pub
│   ├── borgbase_offsite
│   ├── config
│   └── PASSPHRASES.txt
├── borg/
│   ├── passphrase
│   ├── patterns
│   ├── repo-key-export.txt
│   ├── audacious-home-key.txt
│   ├── audacious-home.passphrase
│   ├── astute-critical-key.txt
│   └── astute-critical.passphrase
├── pgp/
│   ├── alchemist_public.asc
│   ├── alchemist_private.asc
│   ├── alchemist_revocation.asc
│   ├── private_public.asc
│   ├── private_private.asc
│   └── private_revocation.asc
├── tokens/
│   ├── jellyfin/
│   │   └── api.token
│   └── README.txt
└── docs/
    ├── secrets-recovery.md
    ├── secrets-maintenance.md
    ├── data-restore.md
    ├── install-audacious.md
    ├── recovery-audacious.md
    ├── install-astute.md
    └── recovery-astute.md
```

# Secrets Recovery Guide

Complete procedures for creating, maintaining, and recovering from the Secrets USB encrypted backup.

**Purpose:** The Secrets USB contains all secrets needed to recover the Wolfpack after catastrophic failure: SSH keys, Borg passphrases, API tokens, and recovery documentation.

**Current Hardware:** The Secrets USB is currently a blue SanDisk 32GB USB drive.

---

## Overview

**What is the Secrets USB:**
- LUKS-encrypted USB flash drive
- Contains all secrets not committed to git
- Required for complete system recovery
- Kept physically secure (encrypted at rest)

**Security model:**
- Encrypted with strong passphrase (stored in password manager)
- Physical security: Kept in secure location
- Updated when secrets change
- Tested periodically to ensure recoverability

**Recovery scenarios:**
- Hardware failure requiring reinstall
- Lost/corrupted home directory
- SSH key rotation
- New host provisioning

---

## §1 Create Encrypted USB

Initial setup of Secrets USB with LUKS encryption.

Prerequisites:
- USB flash drive (8GB minimum, 16GB+ recommended)
- Strong passphrase (25+ characters, stored in password manager)

**DANGER:** This will erase all data on the USB drive. Verify device name carefully.

Steps:
1. Insert USB drive and identify device:

```sh
lsblk
```

Look for USB device (e.g., /dev/sdb, /dev/sdc). Verify by size and type.

2. **VERIFY DEVICE NAME** before continuing:

```sh
sudo fdisk -l /dev/sdX
```

Replace `sdX` with actual device. Confirm size and vendor match USB drive.

3. Unmount if auto-mounted:

```sh
sudo umount /dev/sdX1 2>/dev/null || true
```

4. Create new GPT partition table:

```sh
sudo parted /dev/sdX mklabel gpt
```

5. Create single partition:

```sh
sudo parted /dev/sdX mkpart primary 1MiB 100%
```

6. Set up LUKS encryption:

```sh
sudo cryptsetup luksFormat /dev/sdX1
```

**Enter strong passphrase** when prompted (25+ characters).

Confirm with uppercase `YES`.

7. Open encrypted device:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
```

Enter passphrase.

8. Create ext4 filesystem:

```sh
sudo mkfs.ext4 -L "BLUE_USB_RECOVERY" /dev/mapper/keyusb
```

9. Mount and set up directory structure:

```sh
sudo mkdir -p /mnt/keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
sudo mkdir -p /mnt/keyusb/{ssh-backup,borg,pgp,docs,tokens}
```

10. Set ownership to your user:

```sh
sudo chown -R $(id -u):$(id -g) /mnt/keyusb
```

11. Test write access:

```sh
echo "Secrets USB Recovery - Created $(date)" > /mnt/keyusb/README.txt
cat /mnt/keyusb/README.txt
```

Expected result: Encrypted USB ready for secrets storage.

---

## §2 Initial Population

Populate Secrets USB with all secrets and recovery documentation.

Prerequisites:
- Secrets USB created and mounted at /mnt/keyusb (§1)
- All SSH keys generated (§2.0)
- Borg repository initialized with passphrase

Steps:

### §2.1 SSH Keys

Copy all private SSH keys and config:

```sh
cp ~/.ssh/id_alchemist /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_alchemist.pub /mnt/keyusb/ssh-backup/
cp ~/.ssh/audacious-backup /mnt/keyusb/ssh-backup/
cp ~/.ssh/audacious-backup.pub /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_ed25519_astute_nas /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_ed25519_astute_nas.pub /mnt/keyusb/ssh-backup/
# Use -L to dereference symlinked config.
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

Edit the file and fill in the passphrase:

```sh
nano /mnt/keyusb/ssh-backup/PASSPHRASES.txt
```

---

### §2.2 Borg Backup Passphrase

Copy Borg passphrase and repository keys:

```sh
cp ~/.config/borg/passphrase /mnt/keyusb/borg/
cp -L ~/.config/borg/patterns /mnt/keyusb/borg/patterns
```

Export repository key:

```sh
borg key export borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

Off-site BorgBase repo keys (export on Astute, then copy to Secrets USB):

```sh
# On Astute (as root)
install -d -m 0700 /root/tmp-borg-keys

# Export audacious-home repo key
BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
BORG_PASSCOMMAND="cat /root/.config/borg-offsite/audacious-home.passphrase" \
  borg key export ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo \
  /root/tmp-borg-keys/audacious-home-key.txt

# Export astute-critical repo key
BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
BORG_PASSCOMMAND="cat /root/.config/borg-offsite/astute-critical.passphrase" \
  borg key export ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo \
  /root/tmp-borg-keys/astute-critical-key.txt

# Copy to Audacious (from Astute)
scp /root/tmp-borg-keys/*.txt alchemist@audacious:~/

# On Audacious: Copy to Secrets USB
cp ~/audacious-home-key.txt /mnt/keyusb/borg/
cp ~/astute-critical-key.txt /mnt/keyusb/borg/
rm ~/audacious-home-key.txt ~/astute-critical-key.txt

# Clean up on Astute
rm -rf /root/tmp-borg-keys
```

**IMPORTANT:** These keys must be exported and stored on Secrets USB. Without them, off-site backups are unrecoverable if passphrases are lost.

BorgBase SSH key and passphrases (copy from Astute to Secrets USB):

```sh
# On Astute (as root), copy BorgBase credentials to tmp
install -d -m 0700 /root/tmp-borgbase-creds
cp /root/.ssh/borgbase_offsite /root/tmp-borgbase-creds/
cp /root/.config/borg-offsite/audacious-home.passphrase /root/tmp-borgbase-creds/
cp /root/.config/borg-offsite/astute-critical.passphrase /root/tmp-borgbase-creds/
chmod 600 /root/tmp-borgbase-creds/*

# Transfer to Audacious
scp /root/tmp-borgbase-creds/* alchemist@audacious:~/

# On Audacious: Copy to Secrets USB
cp ~/borgbase_offsite /mnt/keyusb/ssh-backup/
cp ~/audacious-home.passphrase /mnt/keyusb/borg/
cp ~/astute-critical.passphrase /mnt/keyusb/borg/
chmod 600 /mnt/keyusb/ssh-backup/borgbase_offsite
chmod 600 /mnt/keyusb/borg/*.passphrase
rm ~/borgbase_offsite ~/audacious-home.passphrase ~/astute-critical.passphrase

# Clean up on Astute
rm -rf /root/tmp-borgbase-creds
```

**CRITICAL:** Without the BorgBase SSH key and passphrases on Secrets USB, you cannot access off-site backups if Astute is destroyed.

Document repository details:

```sh
cat > /mnt/keyusb/borg/REPOSITORY-INFO.txt <<EOF
Borg Repository Information
===========================

Repository location: borg@astute:/srv/backups/audacious-borg
Encryption: repokey-blake2
Compression: lz4

SSH key: ~/.ssh/audacious-backup (no passphrase, forced command)
Repository passphrase: See passphrase file in this directory

Last backup: $(date)
Last check: $(date)

Restore command:
  borg extract borg@astute:/srv/backups/audacious-borg::[archive-name] /path/to/restore

List archives:
  borg list borg@astute:/srv/backups/audacious-borg
EOF
```

---

### §2.3 PGP Keys (Identity Recovery)

Export PGP keys, including revocation certificates, for both identities:

```sh
gpg --armor --export alchemist@userlandlab.org > /mnt/keyusb/pgp/alchemist_public.asc
gpg --armor --export-secret-keys alchemist@userlandlab.org > /mnt/keyusb/pgp/alchemist_private.asc
gpg --output /mnt/keyusb/pgp/alchemist_revocation.asc --gen-revoke alchemist@userlandlab.org

gpg --armor --export private@example.invalid > /mnt/keyusb/pgp/private_public.asc
gpg --armor --export-secret-keys private@example.invalid > /mnt/keyusb/pgp/private_private.asc
gpg --output /mnt/keyusb/pgp/private_revocation.asc --gen-revoke private@example.invalid
```

Lock down permissions:

```sh
chmod 600 /mnt/keyusb/pgp/*_private.asc /mnt/keyusb/pgp/*_revocation.asc
chmod 644 /mnt/keyusb/pgp/*_public.asc
```

---

### §2.4 API Tokens

Copy any API tokens or service credentials:

```sh
# Jellyfin API token (if exists)
if [ -f ~/.config/jellyfin/api.token ]; then
  cp ~/.config/jellyfin/api.token /mnt/keyusb/tokens/
fi

# Document what each token is for
cat > /mnt/keyusb/tokens/README.txt <<EOF
API Tokens and Credentials
==========================

jellyfin/api.token - Jellyfin server API access (for idle-shutdown.sh remote playback check)

Add other tokens here as needed.
EOF
```

---

### §2.5 Recovery Documentation

Copy essential recovery docs (optional but recommended):

```sh
mkdir -p /mnt/keyusb/docs

# Key recovery procedures
cp ~/dotfiles/docs/secrets-recovery.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/audacious/install.audacious.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/audacious/recovery.audacious.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/astute/install.astute.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/astute/recovery.astute.md /mnt/keyusb/docs/
```

---

### §2.6 Recovery Quick-Start

Create quick-start guide for disaster recovery:

```sh
cat > /mnt/keyusb/QUICK-START.txt <<'EOF'
SECRETS USB RECOVERY QUICK-START
=================================

This USB contains all secrets needed to recover the Wolfpack.

RECOVERY PROCEDURE:
===================

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
   chmod 600 ~/.config/borg/passphrase
   chmod 600 ~/.config/borg/patterns

4. RESTORE API TOKENS:
   mkdir -p ~/.config/jellyfin
   cp /mnt/keyusb/tokens/jellyfin/api.token ~/.config/jellyfin/ 2>/dev/null || true

5. CLONE DOTFILES:
   cd ~
   git clone git@github.com:UserlandAlchemist/dotfiles.git

6. FOLLOW INSTALL DOCS:
   See /mnt/keyusb/docs/install.audacious.md and /mnt/keyusb/docs/install.astute.md
   See /mnt/keyusb/docs/recovery.audacious.md and /mnt/keyusb/docs/recovery.astute.md

PASSPHRASES:
============

SSH key (id_alchemist): See ssh-backup/PASSPHRASES.txt
Borg repository: See borg/passphrase file (patterns in borg/patterns)
PGP keys: See pgp/ (public, private, revocation)
Secrets USB encryption: [You know this - it unlocked this USB]

IMPORTANT:
==========

After recovery, update this USB if any secrets changed!
See docs/secrets-recovery.md §3 for maintenance procedures.

Last updated: $(date)
Host: $(hostname)
EOF
```

---

### §2.7 Set Permissions and Sync

Protect all secrets with restrictive permissions:

```sh
chmod 600 /mnt/keyusb/ssh-backup/*
chmod 600 /mnt/keyusb/borg/*
chmod 600 /mnt/keyusb/pgp/*_private.asc /mnt/keyusb/pgp/*_revocation.asc
chmod 644 /mnt/keyusb/pgp/*_public.asc
chmod 600 /mnt/keyusb/tokens/* 2>/dev/null || true
chmod 644 /mnt/keyusb/README.txt
chmod 644 /mnt/keyusb/QUICK-START.txt
```

Sync to ensure all data is written:

```sh
sync
```

Expected result: Secrets USB fully populated with all secrets and recovery docs.

---

## §3 Maintenance

Update Secrets USB when secrets change.

### §3.1 When to Update

Update Secrets USB whenever:
- SSH keys rotated or added
- Borg repository passphrase changed
- PGP keys rotated
- New API tokens created
- Recovery procedures updated
- After major system changes

**Frequency:** At minimum, verify quarterly that USB is still readable.

---

### §3.2 Update Procedure

Steps:
1. Mount Secrets USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Update specific secrets:

**SSH keys changed:**
```sh
cp ~/.ssh/id_alchemist /mnt/keyusb/ssh-backup/
cp ~/.ssh/id_alchemist.pub /mnt/keyusb/ssh-backup/
# Update SSH client config if changed.
cp -L ~/.ssh/config /mnt/keyusb/ssh-backup/
# Update PASSPHRASES.txt if passphrase changed
nano /mnt/keyusb/ssh-backup/PASSPHRASES.txt
```

**Borg passphrase changed:**
```sh
cp ~/.config/borg/passphrase /mnt/keyusb/borg/
cp -L ~/.config/borg/patterns /mnt/keyusb/borg/patterns
borg key export borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

**API tokens changed:**
```sh
cp ~/.config/jellyfin/api.token /mnt/keyusb/tokens/jellyfin/
```

**Recovery docs updated:**
```sh
cp ~/dotfiles/docs/secrets-recovery.md /mnt/keyusb/docs/
# ... other docs as needed
```

**PGP keys rotated:**
```sh
gpg --armor --export alchemist@userlandlab.org > /mnt/keyusb/pgp/alchemist_public.asc
gpg --armor --export-secret-keys alchemist@userlandlab.org > /mnt/keyusb/pgp/alchemist_private.asc
gpg --output /mnt/keyusb/pgp/alchemist_revocation.asc --gen-revoke alchemist@userlandlab.org

gpg --armor --export private@example.invalid > /mnt/keyusb/pgp/private_public.asc
gpg --armor --export-secret-keys private@example.invalid > /mnt/keyusb/pgp/private_private.asc
gpg --output /mnt/keyusb/pgp/private_revocation.asc --gen-revoke private@example.invalid
```

3. Update timestamp:

```sh
echo "Last updated: $(date) on $(hostname) by $(whoami)" >> /mnt/keyusb/README.txt
```

4. Sync and unmount:

```sh
sync
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: Secrets USB contains latest secrets.

---

### §3.3 Verification Testing

Periodically verify Secrets USB is readable and complete.

**Quarterly verification procedure:**

Steps:
1. Mount Secrets USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Verify directory structure exists:

```sh
ls -la /mnt/keyusb
```

Should see: `ssh-backup/`, `borg/`, `pgp/`, `docs/`, `tokens/`, `README.txt`, `QUICK-START.txt`

3. Verify SSH keys present:

```sh
ls -l /mnt/keyusb/ssh-backup/
```

Should see all private keys, public keys, config, PASSPHRASES.txt

4. Verify Borg materials:

```sh
ls -l /mnt/keyusb/borg/
```

Should include `passphrase`, `patterns`, and `repo-key-export.txt`.

5. Verify PGP materials:

```sh
ls -l /mnt/keyusb/pgp/
```

Should include public, private, and revocation files for each identity.

6. Verify fingerprints match:

```sh
ssh-keygen -lf /mnt/keyusb/ssh-backup/id_alchemist.pub
ssh-keygen -lf ~/.ssh/id_alchemist.pub
```

Should match exactly.

7. Test read random file:

```sh
cat /mnt/keyusb/QUICK-START.txt
```

Should display without errors.

8. Record verification:

```sh
echo "Verified: $(date) - All secrets present and readable" >> /mnt/keyusb/README.txt
sync
```

9. Unmount:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: Confidence that Secrets USB will work in recovery scenario.

---

## §4 Recovery Procedures

Use Secrets USB to restore secrets after system reinstall or failure.

### §4.1 Full System Recovery

After clean install of Audacious or Astute.

Prerequisites:
- Fresh Debian install with sudo access
- Secrets USB and encryption passphrase
- Network access

Steps:
1. Install required packages:

```sh
sudo apt update
sudo apt install -y cryptsetup git
```

2. Mount Secrets USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mkdir -p /mnt/keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

3. Read quick-start guide:

```sh
cat /mnt/keyusb/QUICK-START.txt
```

4. Restore SSH keys:

```sh
mkdir -p ~/.ssh
cp /mnt/keyusb/ssh-backup/id_alchemist ~/.ssh/
cp /mnt/keyusb/ssh-backup/audacious-backup ~/.ssh/
cp /mnt/keyusb/ssh-backup/id_ed25519_astute_nas ~/.ssh/
cp /mnt/keyusb/ssh-backup/config ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/audacious-backup
chmod 644 ~/.ssh/config
```

5. Verify SSH key passphrase:

```sh
ssh-keygen -y -f ~/.ssh/id_alchemist
```

Enter passphrase from `/mnt/keyusb/ssh-backup/PASSPHRASES.txt`

6. Start SSH agent and add key:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_alchemist
```

7. Clone dotfiles:

```sh
cd ~
git clone git@github.com:UserlandAlchemist/dotfiles.git
```

8. Restore Borg passphrase:

```sh
mkdir -p ~/.config/borg
cp /mnt/keyusb/borg/passphrase ~/.config/borg/
chmod 600 ~/.config/borg/passphrase
cp /mnt/keyusb/borg/patterns ~/.config/borg/
chmod 600 ~/.config/borg/patterns
```

9. Restore API tokens (if applicable):

```sh
mkdir -p ~/.config/jellyfin
cp /mnt/keyusb/tokens/jellyfin/api.token ~/.config/jellyfin/ 2>/dev/null || true
```

10. Unmount Secrets USB:

```sh
sync
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

11. Continue with installation:

Follow `docs/audacious/install.audacious.md` or `docs/astute/install.astute.md`.
Stow and system install steps are in `README.md` (Quick Start).
Service verification steps are in the relevant package READMEs (for example:
`root-backup-audacious/README.md`, `root-network-audacious/README.md`,
`root-power-astute/README.md`) and the per-host install docs.

Expected result: All secrets restored, ready to deploy dotfiles and restore data.

---

### §4.2 Hardware Replacement (Audacious)

Use this when rebuilding Audacious from scratch on new hardware.

References:
1. Base install and verification: `docs/audacious/install.audacious.md`
2. Secrets restore: §4.1 in this document
3. Dotfiles stow + system install: `README.md` (Quick Start)
4. Data restore: `docs/audacious/restore.audacious.md`
5. Recovery checks: `docs/audacious/recovery.audacious.md`
6. Service verification: package READMEs (for example `root-backup-audacious/README.md`,
   `root-network-audacious/README.md`)

Expected result: Audacious fully rebuilt with secrets and data restored.

---

### §4.3 Hardware Replacement (Astute)

Use this when rebuilding Astute from scratch on new hardware.

References:
1. Base install and verification: `docs/astute/install.astute.md`
2. Secrets restore: §4.1 in this document
3. Dotfiles stow + system install: `README.md` (Quick Start)
4. Storage import/recovery: `docs/astute/recovery.astute.md`
5. Service verification: package READMEs (for example `root-power-astute/README.md`,
   `root-backup-audacious/README.md`)

Expected result: Astute fully rebuilt with secrets and storage restored.

---

### §4.4 Partial Recovery (SSH Keys Only)

Restore just SSH keys after home directory corruption.

Steps:
1. Mount Secrets USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Backup current SSH directory (if exists):

```sh
mv ~/.ssh ~/.ssh.backup.$(date +%Y%m%d)
```

3. Restore SSH keys:

```sh
mkdir -p ~/.ssh
cp /mnt/keyusb/ssh-backup/id_alchemist ~/.ssh/
cp /mnt/keyusb/ssh-backup/audacious-backup ~/.ssh/
cp /mnt/keyusb/ssh-backup/id_ed25519_astute_nas ~/.ssh/
cp /mnt/keyusb/ssh-backup/config ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/audacious-backup
chmod 644 ~/.ssh/config
```

4. Test SSH access:

```sh
ssh -T git@github.com
ssh astute 'echo "SSH to Astute works"'
```

5. Unmount Secrets USB:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: SSH keys restored and functional.

---

### §4.5 Borg Repository Recovery

Restore Borg access after losing passphrase or repository key.

Steps:
1. Mount Secrets USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Restore Borg passphrase:

```sh
mkdir -p ~/.config/borg
cp /mnt/keyusb/borg/passphrase ~/.config/borg/
chmod 600 ~/.config/borg/passphrase
cp /mnt/keyusb/borg/patterns ~/.config/borg/
chmod 600 ~/.config/borg/patterns
```

3. Import repository key (if needed):

```sh
borg key import borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

4. Test Borg access:

```sh
borg list borg@astute:/srv/backups/audacious-borg
```

5. Unmount Secrets USB:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: Borg repository accessible again.

---

### §4.6 PGP Key Import (Identity Recovery)

Restore PGP keys after system loss or migration.

Steps:
1. Mount Secrets USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Import keys:

```sh
gpg --import /mnt/keyusb/pgp/alchemist_public.asc
gpg --import /mnt/keyusb/pgp/alchemist_private.asc
gpg --import /mnt/keyusb/pgp/private_public.asc
gpg --import /mnt/keyusb/pgp/private_private.asc
```

3. Trust the keys locally (set ultimate trust if this is the primary keyring):

```sh
gpg --edit-key alchemist@userlandlab.org
gpg> trust
# select 5 = ultimate, confirm, then:
gpg> quit

gpg --edit-key private@example.invalid
gpg> trust
# select 5 = ultimate, confirm, then:
gpg> quit
```

4. Verify:

```sh
gpg --list-secret-keys --keyid-format long
```

5. Unmount Secrets USB:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: PGP keys restored and trusted locally.

---

## §5 Troubleshooting

### "No key available with this passphrase"

**Cause:** Wrong LUKS passphrase or USB corruption.

**Fix:**
1. Verify correct USB drive:
   ```sh
   sudo fdisk -l /dev/sdX
   ```

2. Try passphrase again (check password manager)

3. If corruption suspected, try reading backup header:
   ```sh
   sudo cryptsetup luksDump /dev/sdX1
   ```

4. If Secrets USB lost/corrupted: **THIS IS A DISASTER SCENARIO**
   - SSH keys may be in ~/.ssh (if still have access to old system)
   - Borg passphrase may be in ~/.config/borg/passphrase
   - Create new Secrets USB immediately after recovery

---

### "cannot mount: wrong fs type"

**Cause:** USB not decrypted or wrong device name.

**Fix:**
1. Ensure cryptsetup luksOpen succeeded:
   ```sh
   ls -l /dev/mapper/keyusb
   ```

2. If not, open it:
   ```sh
   sudo cryptsetup luksOpen /dev/sdX1 keyusb
   ```

3. Then mount:
   ```sh
   sudo mount /dev/mapper/keyusb /mnt/keyusb
   ```

---

### Secrets USB read-only or permission errors

**Cause:** Filesystem corruption or wrong permissions.

**Fix:**
1. Unmount and fsck:
   ```sh
   sudo umount /mnt/keyusb
   sudo e2fsck -f /dev/mapper/keyusb
   sudo mount /dev/mapper/keyusb /mnt/keyusb
   ```

2. Check filesystem health:
   ```sh
   sudo tune2fs -l /dev/mapper/keyusb
   ```

---

### Forgot Secrets USB encryption passphrase

**Cause:** Passphrase not in password manager or password manager lost.

**Fix:** **NO RECOVERY POSSIBLE** from encrypted USB without passphrase.

**Mitigation:**
1. Check password manager backups
2. Check physical notebook (if you wrote it down)
3. If truly lost, all secrets must be regenerated:
  - Generate new SSH keys (see §2.0)
   - Re-deploy to GitHub and Astute
   - Reset Borg repository (lose all backups) or recover passphrase from ~/.config/borg/passphrase if still have access
   - Create new Secrets USB with new secrets

---

## Appendix A: Secrets USB File Structure

Complete directory tree of Secrets USB:

```
/mnt/keyusb/
├── README.txt                          # Creation date and update log
├── QUICK-START.txt                     # Emergency recovery quick-start
├── ssh-backup/
│   ├── id_alchemist                    # Main SSH private key
│   ├── id_alchemist.pub                # Main SSH public key
│   ├── audacious-backup                # Borg SSH private key
│   ├── audacious-backup.pub            # Borg SSH public key
│   ├── id_ed25519_astute_nas           # NAS control SSH private key
│   ├── id_ed25519_astute_nas.pub       # NAS control SSH public key
│   ├── borgbase_offsite                # BorgBase SSH private key (for disaster recovery)
│   ├── config                          # SSH client configuration
│   └── PASSPHRASES.txt                 # SSH key passphrases and fingerprints
├── borg/
│   ├── passphrase                      # Local Borg repository passphrase
│   ├── patterns                        # Borg include/exclude patterns
│   ├── repo-key-export.txt             # Local Borg repository key export
│   ├── audacious-home-key.txt          # BorgBase repo key (audacious-home)
│   ├── audacious-home.passphrase       # BorgBase repo passphrase (audacious-home)
│   ├── astute-critical-key.txt         # BorgBase repo key (astute-critical)
│   ├── astute-critical.passphrase      # BorgBase repo passphrase (astute-critical)
│   └── REPOSITORY-INFO.txt             # Repository location and details
├── pgp/
│   ├── alchemist_public.asc            # Public PGP key (alchemist)
│   ├── alchemist_private.asc           # Private PGP key (alchemist)
│   ├── alchemist_revocation.asc        # Revocation cert (alchemist)
│   ├── private_public.asc                # Public PGP key (PRIVATE_NAME)
│   ├── private_private.asc               # Private PGP key (PRIVATE_NAME)
│   └── private_revocation.asc            # Revocation cert (PRIVATE_NAME)
├── tokens/
│   ├── jellyfin/
│   │   └── api.token                   # Jellyfin API token
│   └── README.txt                      # Token inventory
└── docs/                               # Recovery documentation copies
    ├── secrets-recovery.md
    ├── install.audacious.md
    ├── recovery.audacious.md
    ├── install.astute.md
    └── recovery.astute.md
```

**File permissions:**
- Directories: 755
- Secrets (private keys, passphrases, tokens): 600
- Public keys: 644
- Documentation: 644

---

## Appendix B: Cross-References

**Related documentation:**
- `secrets-recovery.md` — SSH key generation and recovery
- `docs/audacious/install.audacious.md` — Full Audacious installation
- `docs/audacious/recovery.audacious.md` — Audacious disaster recovery
- `docs/astute/install.astute.md` — Full Astute installation
- `docs/astute/recovery.astute.md` — Astute disaster recovery
- `borg-user-audacious/README.md` — Borg backup configuration

---

## Appendix C: Estate Planning

**In case of emergency (user incapacitated):**

The Secrets USB passphrase should be documented in password manager along with:
- GitHub credentials
- Hetzner credentials (for Artful)
- This dotfiles repository location

**Trusted person should:**
1. Use Secrets USB passphrase to unlock USB
2. Read QUICK-START.txt for recovery overview
3. Follow docs/audacious/recovery.audacious.md and docs/astute/recovery.astute.md for disaster recovery procedures
4. Access GitHub repository for latest dotfiles

**Consider documenting:**
- Location of Secrets USB
- Password manager master password (in will/safe deposit box)
- Contact for technical assistance if needed

---

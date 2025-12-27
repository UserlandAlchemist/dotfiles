# Secrets Recovery Guide

Complete procedures for creating, maintaining, and recovering from the Blue USB encrypted backup.

**Purpose:** The Blue USB contains all secrets needed to recover the Wolfpack after catastrophic failure: SSH keys, Borg passphrases, API tokens, and recovery documentation.

---

## Overview

**What is the Blue USB:**
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

Initial setup of Blue USB with LUKS encryption.

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
sudo mkdir -p /mnt/keyusb/{ssh-keys,borg,docs,tokens}
```

10. Set ownership to your user:

```sh
sudo chown -R $(id -u):$(id -g) /mnt/keyusb
```

11. Test write access:

```sh
echo "Blue USB Recovery - Created $(date)" > /mnt/keyusb/README.txt
cat /mnt/keyusb/README.txt
```

Expected result: Encrypted USB ready for secrets storage.

---

## §2 Initial Population

Populate Blue USB with all secrets and recovery documentation.

Prerequisites:
- Blue USB created and mounted at /mnt/keyusb (§1)
- All SSH keys generated (§2.0)
- Borg repository initialized with passphrase

Steps:

### §2.0 SSH Key Overview

**Key architecture:**

| Key Name | Purpose | Used By | Access To | Type |
|----------|---------|---------|-----------|------|
| `id_alchemist` | Main identity | Audacious, Astute | GitHub, Astute (full shell), Audacious (full shell) | ED25519 |
| `audacious-backup` | Borg backups | Audacious | Astute (borg user, restricted to borg serve) | ED25519 |
| `id_ed25519_astute_nas` | NAS control | Audacious | Astute (forced command: nas-inhibit only) | ED25519 |

**Key locations:**
- Audacious: `~/.ssh/id_alchemist`, `~/.ssh/audacious-backup`, `~/.ssh/id_ed25519_astute_nas`
- Astute: `/srv/backups/.ssh/authorized_keys` (borg), `~/.ssh/authorized_keys` (main + NAS)

**Generate keys (if missing):**

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_alchemist -C "alchemist@userlandlab.org"
ssh-keygen -t ed25519 -f ~/.ssh/audacious-backup -C "audacious-backup" -N ""
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_astute_nas -C "audacious-nas" -N ""
```

**Deployment notes:**
- Add `id_alchemist.pub` to GitHub.
- Install `audacious-backup.pub` in Astute borg user's `authorized_keys` with forced `borg serve`.
- Install `id_ed25519_astute_nas.pub` in Astute user `authorized_keys` with forced `astute-nas-inhibit` command.

### §2.1 SSH Keys

Copy all private SSH keys and config:

```sh
cp ~/.ssh/id_alchemist /mnt/keyusb/ssh-keys/
cp ~/.ssh/id_alchemist.pub /mnt/keyusb/ssh-keys/
cp ~/.ssh/audacious-backup /mnt/keyusb/ssh-keys/
cp ~/.ssh/audacious-backup.pub /mnt/keyusb/ssh-keys/
cp ~/.ssh/id_ed25519_astute_nas /mnt/keyusb/ssh-keys/
cp ~/.ssh/id_ed25519_astute_nas.pub /mnt/keyusb/ssh-keys/
cp ~/.ssh/config /mnt/keyusb/ssh-keys/
```

Document passphrases:

```sh
cat > /mnt/keyusb/ssh-keys/PASSPHRASES.txt <<EOF
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
nano /mnt/keyusb/ssh-keys/PASSPHRASES.txt
```

---

### §2.2 Borg Backup Passphrase

Copy Borg passphrase and repository keys:

```sh
cp ~/.config/borg/passphrase /mnt/keyusb/borg/
```

Export repository key:

```sh
borg key export borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

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

### §2.3 API Tokens

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

### §2.4 Recovery Documentation

Copy essential recovery docs (optional but recommended):

```sh
mkdir -p /mnt/keyusb/docs

# Key recovery procedures
cp ~/dotfiles/docs/SECRETS-RECOVERY.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/SECRETS-RECOVERY.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/audacious/INSTALL.audacious.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/audacious/RECOVERY.audacious.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/astute/INSTALL.astute.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/astute/RECOVERY.astute.md /mnt/keyusb/docs/
```

---

### §2.5 Recovery Quick-Start

Create quick-start guide for disaster recovery:

```sh
cat > /mnt/keyusb/QUICK-START.txt <<'EOF'
BLUE USB RECOVERY QUICK-START
=============================

This USB contains all secrets needed to recover the Wolfpack.

RECOVERY PROCEDURE:
===================

1. MOUNT THIS USB:
   sudo cryptsetup luksOpen /dev/sdX1 keyusb
   sudo mount /dev/mapper/keyusb /mnt/keyusb

2. RESTORE SSH KEYS:
   mkdir -p ~/.ssh
   cp /mnt/keyusb/ssh-keys/id_alchemist ~/.ssh/
   cp /mnt/keyusb/ssh-keys/audacious-backup ~/.ssh/
   cp /mnt/keyusb/ssh-keys/id_ed25519_astute_nas ~/.ssh/
   cp /mnt/keyusb/ssh-keys/config ~/.ssh/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_* ~/.ssh/audacious-backup
   chmod 644 ~/.ssh/config

3. RESTORE BORG PASSPHRASE:
   mkdir -p ~/.config/borg
   cp /mnt/keyusb/borg/passphrase ~/.config/borg/
   chmod 600 ~/.config/borg/passphrase

4. RESTORE API TOKENS:
   mkdir -p ~/.config/jellyfin
   cp /mnt/keyusb/tokens/jellyfin/api.token ~/.config/jellyfin/ 2>/dev/null || true

5. CLONE DOTFILES:
   cd ~
   git clone git@github.com:UserlandAlchemist/dotfiles.git

6. FOLLOW INSTALL DOCS:
   See /mnt/keyusb/docs/INSTALL.*.md for full install procedures
   See /mnt/keyusb/docs/RECOVERY.*.md for recovery scenarios

PASSPHRASES:
============

SSH key (id_alchemist): See ssh-keys/PASSPHRASES.txt
Borg repository: See borg/passphrase file
Blue USB encryption: [You know this - it unlocked this USB]

IMPORTANT:
==========

After recovery, update this USB if any secrets changed!
See docs/SECRETS-RECOVERY.md §3 for maintenance procedures.

Last updated: $(date)
Host: $(hostname)
EOF
```

---

### §2.6 Set Permissions and Sync

Protect all secrets with restrictive permissions:

```sh
chmod 600 /mnt/keyusb/ssh-keys/*
chmod 600 /mnt/keyusb/borg/*
chmod 600 /mnt/keyusb/tokens/* 2>/dev/null || true
chmod 644 /mnt/keyusb/README.txt
chmod 644 /mnt/keyusb/QUICK-START.txt
```

Sync to ensure all data is written:

```sh
sync
```

Expected result: Blue USB fully populated with all secrets and recovery docs.

---

## §3 Maintenance

Update Blue USB when secrets change.

### §3.1 When to Update

Update Blue USB whenever:
- SSH keys rotated or added
- Borg repository passphrase changed
- New API tokens created
- Recovery procedures updated
- After major system changes

**Frequency:** At minimum, verify quarterly that USB is still readable.

---

### §3.2 Update Procedure

Steps:
1. Mount Blue USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Update specific secrets:

**SSH keys changed:**
```sh
cp ~/.ssh/id_alchemist /mnt/keyusb/ssh-keys/
cp ~/.ssh/id_alchemist.pub /mnt/keyusb/ssh-keys/
# Update PASSPHRASES.txt if passphrase changed
nano /mnt/keyusb/ssh-keys/PASSPHRASES.txt
```

**Borg passphrase changed:**
```sh
cp ~/.config/borg/passphrase /mnt/keyusb/borg/
borg key export borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

**API tokens changed:**
```sh
cp ~/.config/jellyfin/api.token /mnt/keyusb/tokens/jellyfin/
```

**Recovery docs updated:**
```sh
cp ~/dotfiles/docs/SECRETS-RECOVERY.md /mnt/keyusb/docs/
cp ~/dotfiles/docs/SECRETS-RECOVERY.md /mnt/keyusb/docs/
# ... other docs as needed
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

Expected result: Blue USB contains latest secrets.

---

### §3.3 Verification Testing

Periodically verify Blue USB is readable and complete.

**Quarterly verification procedure:**

Steps:
1. Mount Blue USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Verify directory structure exists:

```sh
ls -la /mnt/keyusb
```

Should see: `ssh-keys/`, `borg/`, `docs/`, `tokens/`, `README.txt`, `QUICK-START.txt`

3. Verify SSH keys present:

```sh
ls -l /mnt/keyusb/ssh-keys/
```

Should see all private keys, public keys, config, PASSPHRASES.txt

4. Verify Borg passphrase:

```sh
cat /mnt/keyusb/borg/passphrase
```

Should contain passphrase (don't print to terminal in production)

5. Verify fingerprints match:

```sh
ssh-keygen -lf /mnt/keyusb/ssh-keys/id_alchemist.pub
ssh-keygen -lf ~/.ssh/id_alchemist.pub
```

Should match exactly.

6. Test read random file:

```sh
cat /mnt/keyusb/QUICK-START.txt
```

Should display without errors.

7. Record verification:

```sh
echo "Verified: $(date) - All secrets present and readable" >> /mnt/keyusb/README.txt
sync
```

8. Unmount:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: Confidence that Blue USB will work in recovery scenario.

---

## §4 Recovery Procedures

Use Blue USB to restore secrets after system reinstall or failure.

### §4.1 Full System Recovery

After clean install of Audacious or Astute.

Prerequisites:
- Fresh Debian install with sudo access
- Blue USB and encryption passphrase
- Network access

Steps:
1. Install required packages:

```sh
sudo apt update
sudo apt install -y cryptsetup git
```

2. Mount Blue USB:

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
cp /mnt/keyusb/ssh-keys/id_alchemist ~/.ssh/
cp /mnt/keyusb/ssh-keys/audacious-backup ~/.ssh/
cp /mnt/keyusb/ssh-keys/id_ed25519_astute_nas ~/.ssh/
cp /mnt/keyusb/ssh-keys/config ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/audacious-backup
chmod 644 ~/.ssh/config
```

5. Verify SSH key passphrase:

```sh
ssh-keygen -y -f ~/.ssh/id_alchemist
```

Enter passphrase from `/mnt/keyusb/ssh-keys/PASSPHRASES.txt`

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
```

9. Restore API tokens (if applicable):

```sh
mkdir -p ~/.config/jellyfin
cp /mnt/keyusb/tokens/jellyfin/api.token ~/.config/jellyfin/ 2>/dev/null || true
```

10. Unmount Blue USB:

```sh
sync
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

11. Continue with installation:

Follow `docs/audacious/INSTALL.audacious.md` or `docs/astute/INSTALL.astute.md`

Expected result: All secrets restored, ready to deploy dotfiles and restore data.

---

### §4.2 Partial Recovery (SSH Keys Only)

Restore just SSH keys after home directory corruption.

Steps:
1. Mount Blue USB:

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
cp /mnt/keyusb/ssh-keys/id_alchemist ~/.ssh/
cp /mnt/keyusb/ssh-keys/audacious-backup ~/.ssh/
cp /mnt/keyusb/ssh-keys/id_ed25519_astute_nas ~/.ssh/
cp /mnt/keyusb/ssh-keys/config ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/audacious-backup
chmod 644 ~/.ssh/config
```

4. Test SSH access:

```sh
ssh -T git@github.com
ssh astute 'echo "SSH to Astute works"'
```

5. Unmount Blue USB:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: SSH keys restored and functional.

---

### §4.3 Borg Repository Recovery

Restore Borg access after losing passphrase or repository key.

Steps:
1. Mount Blue USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Restore Borg passphrase:

```sh
mkdir -p ~/.config/borg
cp /mnt/keyusb/borg/passphrase ~/.config/borg/
chmod 600 ~/.config/borg/passphrase
```

3. Import repository key (if needed):

```sh
borg key import borg@astute:/srv/backups/audacious-borg /mnt/keyusb/borg/repo-key-export.txt
```

4. Test Borg access:

```sh
borg list borg@astute:/srv/backups/audacious-borg
```

5. Unmount Blue USB:

```sh
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: Borg repository accessible again.

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

4. If Blue USB lost/corrupted: **THIS IS A DISASTER SCENARIO**
   - SSH keys may be in ~/.ssh (if still have access to old system)
   - Borg passphrase may be in ~/.config/borg/passphrase
   - Create new Blue USB immediately after recovery

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

### Blue USB read-only or permission errors

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

### Forgot Blue USB encryption passphrase

**Cause:** Passphrase not in password manager or password manager lost.

**Fix:** **NO RECOVERY POSSIBLE** from encrypted USB without passphrase.

**Mitigation:**
1. Check password manager backups
2. Check physical notebook (if you wrote it down)
3. If truly lost, all secrets must be regenerated:
  - Generate new SSH keys (see §2.0)
   - Re-deploy to GitHub and Astute
   - Reset Borg repository (lose all backups) or recover passphrase from ~/.config/borg/passphrase if still have access
   - Create new Blue USB with new secrets

---

## §6 Best Practices

### Storage Location

**Where to keep Blue USB:**
- Secure physical location (safe, locked drawer)
- Not with laptop (defeats purpose if both stolen together)
- Consider offsite backup (second encrypted USB at different location)

**Where NOT to keep Blue USB:**
- Attached to computer daily (defeats encryption purpose)
- Cloud storage (encrypted, but adds attack surface)
- Shared locations

---

### Passphrase Management

**Blue USB passphrase should be:**
- Stored in password manager
- Different from login passwords
- 25+ characters (or 6+ word diceware)
- Known by trusted person for estate planning

**Never:**
- Written on the USB itself
- Stored in plaintext on computer
- Same as other system passwords

---

### Testing Schedule

**Recommended schedule:**
- **Quarterly:** Verification test (§3.3)
- **Annually:** Full recovery drill (§4.1 in VM or spare hardware)
- **After major changes:** Update immediately (§3.2)

**Why test:**
- Ensures USB still readable (flash corruption)
- Ensures you remember passphrase
- Ensures recovery docs are accurate
- Builds confidence for real disaster

---

### Offsite Backup

**Consider creating second Blue USB:**

```sh
# After creating and populating first USB
sudo cryptsetup luksOpen /dev/sdY1 keyusb2
sudo mount /dev/mapper/keyusb2 /mnt/keyusb2

# Copy all data
sudo rsync -av /mnt/keyusb/ /mnt/keyusb2/

# Verify
diff -r /mnt/keyusb/ /mnt/keyusb2/

sudo umount /mnt/keyusb2
sudo cryptsetup luksClose keyusb2
```

**Store second USB:**
- Different physical location (parent's house, bank deposit box)
- Same encryption passphrase (or document difference in password manager)
- Update both when secrets change

---

## Appendix A: Blue USB File Structure

Complete directory tree of Blue USB:

```
/mnt/keyusb/
├── README.txt                          # Creation date and update log
├── QUICK-START.txt                     # Emergency recovery quick-start
├── ssh-keys/
│   ├── id_alchemist                    # Main SSH private key
│   ├── id_alchemist.pub                # Main SSH public key
│   ├── audacious-backup                # Borg SSH private key
│   ├── audacious-backup.pub            # Borg SSH public key
│   ├── id_ed25519_astute_nas           # NAS control SSH private key
│   ├── id_ed25519_astute_nas.pub       # NAS control SSH public key
│   ├── config                          # SSH client configuration
│   └── PASSPHRASES.txt                 # SSH key passphrases and fingerprints
├── borg/
│   ├── passphrase                      # Borg repository passphrase
│   ├── repo-key-export.txt             # Borg repository key export
│   └── REPOSITORY-INFO.txt             # Repository location and details
├── tokens/
│   ├── jellyfin/
│   │   └── api.token                   # Jellyfin API token
│   └── README.txt                      # Token inventory
└── docs/                               # Recovery documentation copies
    ├── SECRETS-RECOVERY.md
    ├── INSTALL.audacious.md
    ├── RECOVERY.audacious.md
    ├── INSTALL.astute.md
    └── RECOVERY.astute.md
```

**File permissions:**
- Directories: 755
- Secrets (private keys, passphrases, tokens): 600
- Public keys: 644
- Documentation: 644

---

## Appendix B: Cross-References

**Related documentation:**
- `SECRETS-RECOVERY.md` — SSH key generation and recovery
- `docs/audacious/INSTALL.audacious.md` — Full Audacious installation
- `docs/audacious/RECOVERY.audacious.md` — Audacious disaster recovery
- `docs/astute/INSTALL.astute.md` — Full Astute installation
- `docs/astute/RECOVERY.astute.md` — Astute disaster recovery
- `borg-user-audacious/README.md` — Borg backup configuration

---

## Appendix C: Estate Planning

**In case of emergency (user incapacitated):**

The Blue USB passphrase should be documented in password manager along with:
- GitHub credentials
- Hetzner credentials (for Artful)
- This dotfiles repository location

**Trusted person should:**
1. Use Blue USB passphrase to unlock USB
2. Read QUICK-START.txt for recovery overview
3. Follow docs/RECOVERY.*.md for disaster recovery procedures
4. Access GitHub repository for latest dotfiles

**Consider documenting:**
- Location of Blue USB
- Password manager master password (in will/safe deposit box)
- Contact for technical assistance if needed

---

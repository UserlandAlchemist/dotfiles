#!/bin/bash
# Create GPG-encrypted recovery bundle for Google Drive storage
# This bundle contains all secrets needed to access BorgBase after catastrophic loss

set -e

BLUE_USB="/mnt/keyusb"
WORK_DIR="/tmp/recovery-bundle-$$"
OUTPUT_FILE="$HOME/borgbase-recovery-bundle-$(date +%Y%m%d).tar.gz.gpg"

echo "=== BorgBase Recovery Bundle Creation ==="
echo
echo "This creates an encrypted bundle with all secrets needed to access"
echo "BorgBase off-site backups after total on-premises loss."
echo

# Check Blue USB is mounted
if [ ! -d "$BLUE_USB" ]; then
  echo "ERROR: Blue USB not mounted at $BLUE_USB"
  echo "Mount first: cryptsetup luksOpen /dev/sdX keyusb && mount /dev/mapper/keyusb /mnt/keyusb"
  exit 1
fi

# Verify Blue USB has required files
echo "Verifying Blue USB contents..."
MISSING=0
for file in \
  "$BLUE_USB/borg/audacious-home-key.txt" \
  "$BLUE_USB/borg/astute-critical-key.txt" \
  "$BLUE_USB/borg/passphrase" \
  "$BLUE_USB/borg/audacious-home.passphrase" \
  "$BLUE_USB/borg/astute-critical.passphrase" \
  "$BLUE_USB/ssh-backup/borgbase_offsite"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Missing $file"
    MISSING=$((MISSING + 1))
  fi
done

if [ $MISSING -gt 0 ]; then
  echo "ERROR: Blue USB incomplete. Run verify-blue-usb-recovery.sh first."
  echo "See docs/secrets-recovery.md for BorgBase credential backup procedure."
  exit 1
fi

echo "✓ Blue USB verified"
echo

# Create working directory
mkdir -p "$WORK_DIR/recovery-bundle"
cd "$WORK_DIR/recovery-bundle"

echo "Gathering secrets from Blue USB..."

# Copy from Blue USB
cp "$BLUE_USB/borg/audacious-home-key.txt" .
cp "$BLUE_USB/borg/astute-critical-key.txt" .
cp "$BLUE_USB/borg/passphrase" local-borg-passphrase.txt
cp "$BLUE_USB/borg/audacious-home.passphrase" .
cp "$BLUE_USB/borg/astute-critical.passphrase" .
cp "$BLUE_USB/ssh-backup/borgbase_offsite" .
chmod 600 borgbase_offsite

# Create recovery instructions
cat > RECOVERY-INSTRUCTIONS.md << 'EOF'
# BorgBase Disaster Recovery

This bundle contains all secrets needed to access BorgBase off-site backups after total on-premises loss (Audacious + Astute + Blue USB destroyed).

## What's In This Bundle

1. `borgbase_offsite` - BorgBase SSH private key
2. `audacious-home.passphrase` - Off-site repo passphrase (audacious-home)
3. `astute-critical.passphrase` - Off-site repo passphrase (astute-critical)
4. `audacious-home-key.txt` - Repository key export (repokey-blake2)
5. `astute-critical-key.txt` - Repository key export (repokey-blake2)
6. `local-borg-passphrase.txt` - Local Borg repo passphrase (for two-step restore)

## BorgBase Account Info

- Account email: (check Bitwarden or email)
- Repositories:
  - audacious-home: ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo
  - astute-critical: ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo

## Recovery Procedure

### 1. Acquire New Computer

Install Debian/Ubuntu and BorgBackup:
```bash
sudo apt update && sudo apt install borgbackup
```

### 2. Decrypt This Bundle

```bash
gpg -d borgbase-recovery-bundle-YYYYMMDD.tar.gz.gpg | tar xzf -
cd recovery-bundle/
```

### 3. Install SSH Key

```bash
mkdir -p ~/.ssh
cp borgbase_offsite ~/.ssh/
chmod 600 ~/.ssh/borgbase_offsite
```

### 4. List Available Archives

For audacious-home repo:
```bash
export BORG_RSH="ssh -i ~/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes"
export BORG_PASSCOMMAND="cat audacious-home.passphrase"

borg list ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo
```

For astute-critical repo:
```bash
export BORG_RSH="ssh -i ~/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes"
export BORG_PASSCOMMAND="cat astute-critical.passphrase"

borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

### 5. Restore Data

#### Restore from astute-critical (direct restore):

```bash
export BORG_RSH="ssh -i ~/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes"
export BORG_PASSCOMMAND="cat astute-critical.passphrase"

# List archives
borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo

# Extract latest
borg extract ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo::astute-critical-YYYY-MM-DD
# This creates srv/nas/lucii and srv/nas/bitwarden-exports in current directory
```

#### Restore from audacious-home (two-step restore):

Step 1: Restore the local Borg repository directory
```bash
export BORG_RSH="ssh -i ~/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes"
export BORG_PASSCOMMAND="cat audacious-home.passphrase"

borg extract ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo::audacious-home-YYYY-MM-DD
# This creates srv/backups/audacious-borg in current directory
```

Step 2: Restore data from the local repository
```bash
export BORG_REPO=srv/backups/audacious-borg
export BORG_PASSCOMMAND="cat local-borg-passphrase.txt"

# List archives in local repo
borg list

# Extract home directory from latest backup
borg extract ::audacious-YYYY-MM-DD home/alchemist
# This creates home/alchemist in current directory
```

## Important Notes

- audacious-home is a backup of the Borg repository (two-step restore)
- astute-critical contains lucii and bitwarden-exports (direct restore)
- Repository keys are exported in case you need to recreate repo access
- This bundle should be re-created whenever SSH keys or passphrases change

## Support

If stuck, see:
- BorgBackup docs: https://borgbackup.readthedocs.io/
- BorgBase support: https://www.borgbase.com/support
EOF

# Create metadata file
cat > METADATA.txt << EOF
Recovery Bundle Created: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)
Created On: $(hostname)
Created By: $(whoami)

BorgBase Repositories:
- audacious-home (j6i5cke1): Daily snapshots of local Borg repo
- astute-critical (y7pc8k07): Critical data (lucii, bitwarden-exports)

Files Included:
$(ls -1)

Bundle Encryption:
- Algorithm: GPG AES256 symmetric encryption
- Passphrase: MEMORIZE THIS - not stored anywhere
- Recommendation: 6-8 word diceware passphrase

Update Schedule:
- When rotating BorgBase SSH key
- When changing any Borg passphrases
- Every 6 months when trusted person visits
- After any disaster recovery test
EOF

cd ..

echo "Creating encrypted tarball..."
tar czf recovery-bundle.tar.gz recovery-bundle/

echo
echo "=== Encryption ==="
echo "You will be prompted for a passphrase to encrypt the bundle."
echo
echo "CRITICAL: This passphrase must be:"
echo "  - Memorable (you'll need it post-disaster without password manager)"
echo "  - Strong (6-8 random words recommended)"
echo "  - Written down ONCE and stored in wallet (separate from house)"
echo
echo "DO NOT store this passphrase in Bitwarden or on Blue USB."
echo "It protects everything if those are lost."
echo

# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 recovery-bundle.tar.gz

# Move to home directory
mv recovery-bundle.tar.gz.gpg "$OUTPUT_FILE"

# Clean up
cd /
rm -rf "$WORK_DIR"

echo
echo "=== Success ==="
echo "Recovery bundle created: $OUTPUT_FILE"
echo "Size: $(stat -c%s "$OUTPUT_FILE" | numfmt --to=iec-i --suffix=B)"
echo
echo "Next steps:"
echo "1. Upload $OUTPUT_FILE to Google Drive"
echo "2. Store in 'Disaster Recovery' folder"
echo "3. Test decryption: gpg -d $OUTPUT_FILE | tar tzf -"
echo "4. Delete local copy after upload (it's on Google Drive now)"
echo
echo "Remember: This bundle is only as secure as the GPG passphrase you chose."
echo "Memorize the passphrase or store a single copy in your wallet."

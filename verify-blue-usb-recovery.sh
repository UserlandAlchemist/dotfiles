#!/bin/bash
# Verify Blue USB has all secrets needed for disaster recovery
set -e

BLUE_USB="/mnt/keyusb"
ERRORS=0

echo "=== Blue USB Recovery Verification ==="
echo

# Check if Blue USB is mounted
if [ ! -d "$BLUE_USB" ]; then
  echo "ERROR: Blue USB not mounted at $BLUE_USB"
  echo "Mount with: cryptsetup luksOpen /dev/sdX keyusb && mount /dev/mapper/keyusb /mnt/keyusb"
  exit 1
fi

echo "✓ Blue USB mounted at $BLUE_USB"
echo

# Function to check file exists
check_file() {
  local path="$1"
  local description="$2"

  if [ -f "$path" ]; then
    echo "✓ $description"
    echo "  → $path ($(stat -c%s "$path") bytes)"
  else
    echo "✗ MISSING: $description"
    echo "  → Expected: $path"
    ERRORS=$((ERRORS + 1))
  fi
}

# Function to check directory exists
check_dir() {
  local path="$1"
  local description="$2"

  if [ -d "$path" ]; then
    local count=$(find "$path" -type f | wc -l)
    echo "✓ $description"
    echo "  → $path ($count files)"
  else
    echo "✗ MISSING: $description"
    echo "  → Expected: $path"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "--- SSH Keys ---"
check_file "$BLUE_USB/ssh-backup/id_alchemist" "Main SSH private key"
check_file "$BLUE_USB/ssh-backup/id_alchemist.pub" "Main SSH public key"
check_file "$BLUE_USB/ssh-backup/audacious-backup" "Borg backup SSH private key"
check_file "$BLUE_USB/ssh-backup/audacious-backup.pub" "Borg backup SSH public key"
check_file "$BLUE_USB/ssh-backup/id_ed25519_astute_nas" "NAS control SSH private key"
check_file "$BLUE_USB/ssh-backup/id_ed25519_astute_nas.pub" "NAS control SSH public key"
check_file "$BLUE_USB/ssh-backup/borgbase_offsite" "BorgBase SSH private key"
echo

echo "--- BorgBase Off-Site Keys ---"
check_file "$BLUE_USB/borg/audacious-home-key.txt" "BorgBase audacious-home repository key"
check_file "$BLUE_USB/borg/astute-critical-key.txt" "BorgBase astute-critical repository key"
echo

echo "--- BorgBase Passphrases ---"
check_file "$BLUE_USB/borg/audacious-home.passphrase" "BorgBase audacious-home passphrase"
check_file "$BLUE_USB/borg/astute-critical.passphrase" "BorgBase astute-critical passphrase"
echo

echo "--- Borg Local Backup Keys ---"
check_file "$BLUE_USB/borg/passphrase" "Local Borg repository passphrase"
check_file "$BLUE_USB/borg/repo-key-export.txt" "Local Borg repository key"
echo

echo "--- Documentation ---"
check_file "$BLUE_USB/docs/secrets-recovery.md" "Secrets recovery procedures"
check_file "$BLUE_USB/borg/REPOSITORY-INFO.txt" "Repository information"
echo

echo "--- PGP Keys ---"
check_dir "$BLUE_USB/pgp" "PGP key exports directory"
echo

echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
  echo "✓ Blue USB has all required recovery files"
  echo
  echo "Safe to create copy for off-site trusted person storage."
  exit 0
else
  echo "✗ Blue USB is INCOMPLETE - $ERRORS files/directories missing"
  echo
  echo "Run the Blue USB population procedure from docs/secrets-recovery.md"
  echo "before creating off-site copies or Google Drive bundle."
  exit 1
fi

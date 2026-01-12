#!/bin/bash
# Verify Secrets USB has all secrets needed for disaster recovery
set -e

SECRETS_USB="${SECRETS_USB:-/mnt/keyusb}"
CHECKSUMS_FILE="$SECRETS_USB/.checksums.txt"
ERRORS=0
SAVE_CHECKSUMS=0

# Parse arguments
if [ "$1" = "--save-checksums" ]; then
  SAVE_CHECKSUMS=1
fi

echo "=== Secrets USB Recovery Verification ==="
echo

# Check if Secrets USB is mounted
if [ ! -d "$SECRETS_USB" ]; then
  echo "ERROR: Secrets USB not mounted at $SECRETS_USB"
  echo "Mount with: cryptsetup luksOpen /dev/sdX keyusb && mount /dev/mapper/keyusb /mnt/keyusb"
  exit 1
fi

echo "✓ Secrets USB mounted at $SECRETS_USB"
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
    local count
    count=$(find "$path" -type f | wc -l)
    echo "✓ $description"
    echo "  → $path ($count files)"
  else
    echo "✗ MISSING: $description"
    echo "  → Expected: $path"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "--- SSH Keys ---"
check_file "$SECRETS_USB/ssh-backup/id_alchemist" "Main SSH private key"
check_file "$SECRETS_USB/ssh-backup/id_alchemist.pub" "Main SSH public key"
check_file "$SECRETS_USB/ssh-backup/audacious-backup" "Borg backup SSH private key"
check_file "$SECRETS_USB/ssh-backup/audacious-backup.pub" "Borg backup SSH public key"
check_file "$SECRETS_USB/ssh-backup/id_ed25519_astute_nas" "NAS control SSH private key"
check_file "$SECRETS_USB/ssh-backup/id_ed25519_astute_nas.pub" "NAS control SSH public key"
check_file "$SECRETS_USB/ssh-backup/borgbase-offsite-audacious" "BorgBase SSH private key (audacious-home)"
check_file "$SECRETS_USB/ssh-backup/borgbase-offsite-astute" "BorgBase SSH private key (astute-critical)"
echo

echo "--- BorgBase Off-Site Keys ---"
check_file "$SECRETS_USB/borg/audacious-home-key.txt" "BorgBase audacious-home repository key"
check_file "$SECRETS_USB/borg/astute-critical-key.txt" "BorgBase astute-critical repository key"
echo

echo "--- BorgBase Passphrases ---"
check_file "$SECRETS_USB/borg/audacious-home.passphrase" "BorgBase audacious-home passphrase"
check_file "$SECRETS_USB/borg/astute-critical.passphrase" "BorgBase astute-critical passphrase"
echo

echo "--- Borg Local Backup Keys ---"
check_file "$SECRETS_USB/borg/passphrase" "Local Borg repository passphrase"
check_file "$SECRETS_USB/borg/repo-key-export.txt" "Local Borg repository key"
echo

echo "--- Documentation ---"
check_file "$SECRETS_USB/docs/secrets-recovery.md" "Secrets recovery procedures"
check_file "$SECRETS_USB/borg/REPOSITORY-INFO.txt" "Repository information"
echo

echo "--- PGP Keys ---"
check_dir "$SECRETS_USB/pgp" "PGP key exports directory"
echo

# If errors in file existence, stop here
if [ $ERRORS -gt 0 ]; then
  echo "=== Summary ==="
  echo "✗ Secrets USB is INCOMPLETE - $ERRORS files/directories missing"
  echo
  echo "Run the Secrets USB population procedure from docs/secrets-recovery.md"
  echo "before creating off-site copies or Google Drive bundle."
  exit 1
fi

# Checksum verification/saving
if [ $SAVE_CHECKSUMS -eq 1 ]; then
  echo "--- Saving Checksums ---"
  echo "Computing SHA256 checksums (this may take a minute)..."

  TEMP_CHECKSUMS="/tmp/checksums-$$.txt"
  (cd "$SECRETS_USB" && find . -type f -not -name '.checksums.txt' -exec sha256sum {} \; | sort -k2) > "$TEMP_CHECKSUMS"

  mv "$TEMP_CHECKSUMS" "$CHECKSUMS_FILE"
  chmod 600 "$CHECKSUMS_FILE"

  FILE_COUNT=$(wc -l < "$CHECKSUMS_FILE")
  echo "✓ Saved checksums for $FILE_COUNT files to $CHECKSUMS_FILE"
  echo
elif [ -f "$CHECKSUMS_FILE" ]; then
  echo "--- Verifying Checksums ---"
  echo "Verifying file integrity against saved checksums..."
  echo

  TEMP_CHECKSUMS="/tmp/checksums-$$.txt"
  (cd "$SECRETS_USB" && find . -type f -not -name '.checksums.txt' -exec sha256sum {} \; | sort -k2) > "$TEMP_CHECKSUMS"

  if diff -q "$CHECKSUMS_FILE" "$TEMP_CHECKSUMS" > /dev/null 2>&1; then
    echo "✓ All checksums MATCH - files are intact"
    FILE_COUNT=$(wc -l < "$CHECKSUMS_FILE")
    echo "  Verified $FILE_COUNT files"
  else
    echo "✗ Checksum verification FAILED - files have been modified or corrupted"
    echo
    echo "Differences:"
    diff "$CHECKSUMS_FILE" "$TEMP_CHECKSUMS" || true
    echo
    echo "To accept current state as correct:"
    echo "  sudo $0 --save-checksums"
    ERRORS=$((ERRORS + 1))
  fi

  rm "$TEMP_CHECKSUMS"
  echo
else
  echo "--- Checksums ---"
  echo "No checksums file found. To enable integrity verification:"
  echo "  sudo $0 --save-checksums"
  echo
fi

echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
  echo "✓ Secrets USB has all required recovery files"
  if [ -f "$CHECKSUMS_FILE" ] && [ $SAVE_CHECKSUMS -eq 0 ]; then
    echo "✓ All file checksums verified"
  fi
  echo
  echo "Safe to create copy for off-site trusted person storage."
  exit 0
else
  echo "✗ Verification FAILED - $ERRORS errors found"
  echo
  exit 1
fi

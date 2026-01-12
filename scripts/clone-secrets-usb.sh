#!/bin/bash
# Clone Secrets USB to trusted person's USB with verification
# This script creates/updates an encrypted backup USB with identical contents

set -e

SECRETS_USB="${SECRETS_USB:-/mnt/keyusb}"
TRUSTED_USB="${TRUSTED_USB:-/mnt/keyusb-trusted}"

echo "=== Secrets USB Clone Utility ==="
echo
echo "This creates an encrypted clone of Secrets USB for off-site storage."
echo "The clone will have:"
echo "  - Same LUKS passphrase as Secrets USB"
echo "  - Identical file contents (verified with checksums)"
echo "  - Independent UUID (safe to have both plugged in)"
echo

# Check Secrets USB is mounted
if [ ! -d "$SECRETS_USB" ]; then
  echo "ERROR: Secrets USB not mounted at $SECRETS_USB"
  echo "Mount first: sudo cryptsetup luksOpen /dev/sdX keyusb && sudo mount /dev/mapper/keyusb /mnt/keyusb"
  exit 1
fi

echo "✓ Secrets USB mounted at $SECRETS_USB"
echo

# Identify target device
echo "Available block devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS | grep -v loop
echo
read -r -p "Enter target USB device (e.g., sdc): " TARGET_DEV

if [ -z "$TARGET_DEV" ]; then
  echo "ERROR: No device specified"
  exit 1
fi

# Add /dev/ prefix if not present
if [[ ! "$TARGET_DEV" == /dev/* ]]; then
  TARGET_DEV="/dev/$TARGET_DEV"
fi

if [ ! -b "$TARGET_DEV" ]; then
  echo "ERROR: $TARGET_DEV is not a block device"
  exit 1
fi

# Safety check
echo
echo "WARNING: This will DESTROY all data on $TARGET_DEV"
lsblk "$TARGET_DEV"
echo
read -r -p "Type 'yes' to continue: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

echo
echo "=== Creating Encrypted USB ==="

# Wipe partition table
echo "Wiping partition table..."
sudo wipefs -a "$TARGET_DEV"

# Create single partition
echo "Creating partition..."
sudo parted "$TARGET_DEV" --script mklabel gpt
sudo parted "$TARGET_DEV" --script mkpart primary ext4 1MiB 100%

# Wait for kernel to recognize partition
sleep 2
PARTITION="${TARGET_DEV}1"

if [ ! -b "$PARTITION" ]; then
  # Some devices use p1 instead of 1
  PARTITION="${TARGET_DEV}p1"
fi

if [ ! -b "$PARTITION" ]; then
  echo "ERROR: Partition $PARTITION not found"
  exit 1
fi

echo "✓ Created partition: $PARTITION"

# Create LUKS container
echo
echo "Creating LUKS encryption..."
echo "Use the SAME passphrase as Secrets USB so both can be unlocked with one passphrase."
echo

sudo cryptsetup luksFormat --type luks2 "$PARTITION"

echo
echo "Opening encrypted partition..."
sudo cryptsetup luksOpen "$PARTITION" keyusb-trusted

# Create filesystem
echo "Creating ext4 filesystem..."
sudo mkfs.ext4 -L "keyusb-trusted" /dev/mapper/keyusb-trusted

# Mount
echo "Mounting..."
sudo mkdir -p "$TRUSTED_USB"
sudo mount /dev/mapper/keyusb-trusted "$TRUSTED_USB"

echo "✓ Encrypted USB ready at $TRUSTED_USB"
echo

# Copy data
echo "=== Copying Data ==="
echo "This may take a few minutes..."
echo

sudo rsync -aAX --info=progress2 "$SECRETS_USB/" "$TRUSTED_USB/"

echo
echo "✓ Copy complete"
echo

# Verify with checksums
echo "=== Verification ==="
echo "Computing checksums (this may take a minute)..."
echo

SECRETS_CHECKSUMS="/tmp/secrets-checksums-$$.txt"
TRUSTED_CHECKSUMS="/tmp/trusted-checksums-$$.txt"

echo "Computing Secrets USB checksums..."
(cd "$SECRETS_USB" && sudo find . -type f -exec sha256sum {} \; | sort -k2) > "$SECRETS_CHECKSUMS"

echo "Computing trusted USB checksums..."
(cd "$TRUSTED_USB" && sudo find . -type f -exec sha256sum {} \; | sort -k2) > "$TRUSTED_CHECKSUMS"

if diff -q "$SECRETS_CHECKSUMS" "$TRUSTED_CHECKSUMS" > /dev/null; then
  echo "✓ Verification PASSED - all files match"
  VERIFIED=1
else
  echo "✗ Verification FAILED - files differ"
  echo
  echo "Differences:"
  diff "$SECRETS_CHECKSUMS" "$TRUSTED_CHECKSUMS" || true
  VERIFIED=0
fi

rm "$SECRETS_CHECKSUMS" "$TRUSTED_CHECKSUMS"
echo

# Unmount
echo "=== Cleanup ==="
sudo umount "$TRUSTED_USB"
sudo cryptsetup luksClose keyusb-trusted
sudo rmdir "$TRUSTED_USB"

echo
if [ $VERIFIED -eq 1 ]; then
  echo "=== Success ==="
  echo "Trusted Copy created and verified."
  echo
  echo "Next steps:"
  echo "1. Document handoff date in maintenance log"
  echo "2. Label USB: 'Secrets USB - Trusted Copy - Updated $(date +%Y-%m-%d)'"
  echo "3. Hand off to trusted person"
  echo "4. Store off-site (different physical location)"
  echo
  echo "To unlock this USB in the future:"
  echo "  sudo cryptsetup luksOpen $PARTITION keyusb-trusted"
  echo "  sudo mount /dev/mapper/keyusb-trusted /mnt/keyusb-trusted"
else
  echo "=== FAILED ==="
  echo "Verification failed. Do not use this USB for disaster recovery."
  echo "Re-run this script to try again."
  exit 1
fi

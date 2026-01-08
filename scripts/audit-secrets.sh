#!/bin/bash
# Audit secrets across Audacious and Astute
# - Check for leftover temporary secret files
# - Verify permissions on legitimate secret files
# - Report any security issues

set -e

ERRORS=0
WARNINGS=0

echo "=== Secrets Security Audit ==="
echo

# Check current host
HOSTNAME=$(hostname)
echo "Running on: $HOSTNAME"
echo

check_file_not_exists() {
  local path="$1"
  local description="$2"

  if [ -f "$path" ]; then
    echo "✗ FOUND (should not exist): $description"
    echo "  → $path"
    echo "  → Run: rm \"$path\""
    ERRORS=$((ERRORS + 1))
  fi
}

check_file_permissions() {
  local path="$1"
  local expected_perms="$2"
  local description="$3"

  if [ ! -f "$path" ]; then
    return  # File doesn't exist, skip (not an error for this check)
  fi

  actual_perms=$(stat -c%a "$path")
  if [ "$actual_perms" != "$expected_perms" ]; then
    echo "✗ BAD PERMISSIONS: $description"
    echo "  → $path"
    echo "  → Current: $actual_perms, Expected: $expected_perms"
    echo "  → Run: chmod $expected_perms \"$path\""
    ERRORS=$((ERRORS + 1))
  else
    echo "✓ $description"
    echo "  → $path ($actual_perms)"
  fi
}

check_no_world_readable() {
  local path="$1"
  local description="$2"

  if [ ! -f "$path" ]; then
    return
  fi

  perms=$(stat -c%a "$path")
  other_perms=${perms:2:1}

  if [ "$other_perms" != "0" ]; then
    echo "⚠ WARNING: World-readable secret"
    echo "  → $path ($perms)"
    echo "  → Run: chmod o-rwx \"$path\""
    WARNINGS=$((WARNINGS + 1))
  fi
}

# === AUDACIOUS CHECKS ===
if [ "$HOSTNAME" = "audacious" ]; then
  echo "--- Audacious: Temporary Files (should not exist) ---"
  check_file_not_exists "$HOME/borgbase_offsite" "BorgBase SSH key (temporary)"
  check_file_not_exists "$HOME/borgbase-offsite-astute" "BorgBase SSH key (temporary, renamed)"
  check_file_not_exists "$HOME/audacious-home.passphrase" "Audacious home passphrase (temporary)"
  check_file_not_exists "$HOME/astute-critical.passphrase" "Astute critical passphrase (temporary)"
  check_file_not_exists "$HOME/borgbase-recovery-bundle-"*.tar.gz.gpg "Recovery bundle (should be on Google Drive)"
  echo

  echo "--- Audacious: SSH Key Permissions ---"
  check_file_permissions "$HOME/.ssh/id_alchemist" "600" "Main SSH private key"
  check_file_permissions "$HOME/.ssh/audacious-backup" "600" "Borg backup SSH private key"
  check_file_permissions "$HOME/.ssh/id_ed25519_astute_nas" "600" "NAS control SSH private key"
  echo

  echo "--- Audacious: Borg Credentials ---"
  check_file_permissions "$HOME/.config/borg/passphrase" "600" "Local Borg passphrase"
  echo
fi

# === ASTUTE CHECKS (via SSH) ===
if [ "$HOSTNAME" = "audacious" ]; then
  echo "--- Astute: Checking via SSH ---"

  # Check for leftover temp files
  if ssh astute "test -f ~/borgbase_offsite" 2>/dev/null; then
    echo "✗ FOUND on Astute: ~/borgbase_offsite (temporary file)"
    echo "  → Run on Astute: rm ~/borgbase_offsite"
    ERRORS=$((ERRORS + 1))
  fi

  if ssh astute "test -f ~/borgbase-offsite-astute" 2>/dev/null; then
    echo "✗ FOUND on Astute: ~/borgbase-offsite-astute (temporary file)"
    echo "  → Run on Astute: rm ~/borgbase-offsite-astute"
    ERRORS=$((ERRORS + 1))
  fi

  if ssh astute "test -f ~/audacious-home.passphrase" 2>/dev/null; then
    echo "✗ FOUND on Astute: ~/audacious-home.passphrase (temporary file)"
    echo "  → Run on Astute: rm ~/audacious-home.passphrase"
    ERRORS=$((ERRORS + 1))
  fi

  if ssh astute "test -f ~/astute-critical.passphrase" 2>/dev/null; then
    echo "✗ FOUND on Astute: ~/astute-critical.passphrase (temporary file)"
    echo "  → Run on Astute: rm ~/astute-critical.passphrase"
    ERRORS=$((ERRORS + 1))
  fi

  if [ $ERRORS -eq 0 ]; then
    echo "✓ No temporary files found on Astute"
  fi
  echo

  echo "--- Astute: Root Credentials (cannot verify remotely) ---"
  echo "⚠ Manual check required on Astute:"
  echo "  - /root/.ssh/borgbase-offsite-astute should be 600"
  echo "  - /root/.config/borg-offsite/*.passphrase should be 600"
  echo "  - /root/.config/borg/passphrase should be 600"
  echo "  Run: sudo ls -la /root/.ssh/borgbase-offsite-astute /root/.config/borg-offsite/ /root/.config/borg/"
  echo
fi

# === ASTUTE LOCAL CHECKS ===
if [ "$HOSTNAME" = "astute" ]; then
  echo "--- Astute: Temporary Files (should not exist) ---"
  check_file_not_exists "$HOME/borgbase_offsite" "BorgBase SSH key (temporary)"
  check_file_not_exists "$HOME/borgbase-offsite-astute" "BorgBase SSH key (temporary, renamed)"
  check_file_not_exists "$HOME/audacious-home.passphrase" "Audacious home passphrase (temporary)"
  check_file_not_exists "$HOME/astute-critical.passphrase" "Astute critical passphrase (temporary)"
  echo

  echo "--- Astute: Root Credentials (need sudo) ---"
  echo "Checking root-owned secrets..."

  if [ -f /root/.ssh/borgbase-offsite-astute ]; then
    sudo stat -c "%a %U:%G %n" /root/.ssh/borgbase-offsite-astute 2>/dev/null || echo "⚠ Cannot check /root/.ssh/borgbase-offsite-astute (need sudo)"
  fi

  if [ -f /root/.config/borg-offsite/audacious-home.passphrase ]; then
    sudo stat -c "%a %U:%G %n" /root/.config/borg-offsite/audacious-home.passphrase 2>/dev/null || echo "⚠ Cannot check passphrases (need sudo)"
  fi

  if [ -f /root/.config/borg/passphrase ]; then
    sudo stat -c "%a %U:%G %n" /root/.config/borg/passphrase 2>/dev/null || echo "⚠ Cannot check local Borg passphrase (need sudo)"
  fi
  echo
fi

# === DOTFILES REPO CHECKS ===
echo "--- Dotfiles Repository Checks ---"
echo "Checking for accidentally committed secrets..."

cd ~/dotfiles
# Check for actual secret files (not scripts mentioning them)
SECRET_FILES=$(git ls-files | grep -E '\.(passphrase|secret|token)$|/borgbase_offsite$|/borgbase-offsite-(audacious|astute)$|\.checksums\.txt$|recovery-bundle.*\.tar\.gz\.gpg$' || true)

if [ -n "$SECRET_FILES" ]; then
  echo "✗ SECRETS FOUND IN GIT:"
  echo "$SECRET_FILES"
  echo
  echo "These files should be in .gitignore!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ No secrets found in git index"
fi
echo

# === SUMMARY ===
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✓ All checks passed"
  echo "✓ No leftover temporary secrets"
  echo "✓ No accidentally committed secrets"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "⚠ $WARNINGS warnings (review recommended)"
  exit 0
else
  echo "✗ $ERRORS errors found"
  if [ $WARNINGS -gt 0 ]; then
    echo "⚠ $WARNINGS warnings"
  fi
  echo
  echo "Fix the errors above before proceeding."
  exit 1
fi

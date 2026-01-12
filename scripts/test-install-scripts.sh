#!/bin/bash
# Test all root-* install scripts to verify no regressions after refactoring

set -e

HOSTNAME=$(hostname)
DOTFILES_DIR="$HOME/dotfiles"
FAILURES=0
SUCCESSES=0
SUDO=()

if [ "$(id -u)" -ne 0 ]; then
  SUDO=(sudo)
fi

echo "=== Testing Install Scripts on $HOSTNAME ==="
echo

# Determine which packages to test based on hostname
if [ "$HOSTNAME" = "audacious" ]; then
  PACKAGES=(
    root-borg-audacious
    root-cachyos-audacious
    root-efisync-audacious
    root-firewall-audacious
    root-network-audacious
    root-power-audacious
    root-proaudio-audacious
    root-sudoers-audacious
    root-journald-audacious
  )
elif [ "$HOSTNAME" = "astute" ]; then
  PACKAGES=(
    root-firewall-astute
    root-borg-astute
    root-power-astute
    root-ssh-astute
  )
else
  echo "ERROR: Unknown hostname $HOSTNAME"
  exit 1
fi

test_package() {
  PKG="$1"
  INSTALL_SCRIPT="$DOTFILES_DIR/$PKG/install.sh"

  if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "✗ $PKG - install.sh not found"
    FAILURES=$((FAILURES + 1))
    return 1
  fi

  echo "Testing: $PKG"
  echo "---"

  # Run install script and capture output
  if "${SUDO[@]}" "$INSTALL_SCRIPT" 2>&1; then
    echo "✓ $PKG - installed successfully"
    SUCCESSES=$((SUCCESSES + 1))
    echo
    return 0
  else
    EXIT_CODE=$?
    echo "✗ $PKG - FAILED with exit code $EXIT_CODE"
    FAILURES=$((FAILURES + 1))
    echo
    return 1
  fi
}

# Test all packages for this host
for PKG in "${PACKAGES[@]}"; do
  test_package "$PKG"
  sleep 1  # Brief pause between tests
done

# Summary
echo "=== Test Summary ==="
echo "Successes: $SUCCESSES"
echo "Failures: $FAILURES"
echo

if [ $FAILURES -eq 0 ]; then
  echo "✓ All install scripts passed!"
  exit 0
else
  echo "✗ $FAILURES install script(s) failed"
  echo "Review output above for details"
  exit 1
fi

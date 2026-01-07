#!/bin/sh
# Shared installation library for root-* packages
# Source this from package install.sh scripts

set -eu

# Verify running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: must run as root" >&2
  exit 1
fi

# Setup standard paths
# PKG_DIR must be set by calling script before sourcing this library
if [ -z "${PKG_DIR:-}" ]; then
  echo "ERROR: PKG_DIR not set (set before sourcing lib/install.sh)" >&2
  exit 1
fi

DOTFILES_DIR="$(dirname "$PKG_DIR")"
export PKG_DIR DOTFILES_DIR

#
# Standard installation functions
# All are idempotent - safe to run multiple times
#

# Install systemd unit file
# Usage: install_unit unitname.service
install_unit() {
  UNIT="$1"
  SOURCE="$PKG_DIR/etc/systemd/system/$UNIT"
  TARGET="/etc/systemd/system/$UNIT"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: unit not found: $SOURCE" >&2
    return 1
  fi

  install -m 0644 "$SOURCE" "$TARGET"
  echo "  → $UNIT"
}

# Install executable script
# Usage: install_script usr/local/bin/myscript.sh
install_script() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: script not found: $SOURCE" >&2
    return 1
  fi

  mkdir -p "$TARGETDIR"
  install -m 0755 "$SOURCE" "$TARGET"
  echo "  → /$RELPATH"
}

# Install configuration file (non-executable)
# Usage: install_config etc/myapp/config.conf
install_config() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: config not found: $SOURCE" >&2
    return 1
  fi

  mkdir -p "$TARGETDIR"
  install -m 0644 "$SOURCE" "$TARGET"
  echo "  → /$RELPATH"
}

# Install udev rule
# Usage: install_udev_rule 50-myrule.rules
install_udev_rule() {
  RULE="$1"
  SOURCE="$PKG_DIR/etc/udev/rules.d/$RULE"
  TARGET="/etc/udev/rules.d/$RULE"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: udev rule not found: $SOURCE" >&2
    return 1
  fi

  mkdir -p /etc/udev/rules.d
  install -m 0644 "$SOURCE" "$TARGET"
  echo "  → $RULE"
}

# Install modprobe configuration
# Usage: install_modprobe mymodule.conf
install_modprobe() {
  CONF="$1"
  SOURCE="$PKG_DIR/etc/modprobe.d/$CONF"
  TARGET="/etc/modprobe.d/$CONF"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: modprobe config not found: $SOURCE" >&2
    return 1
  fi

  mkdir -p /etc/modprobe.d
  install -m 0644 "$SOURCE" "$TARGET"
  echo "  → $CONF"
}

# Install libexec script
# Usage: install_libexec myscript.sh
install_libexec() {
  SCRIPT="$1"
  SOURCE="$PKG_DIR/usr/local/libexec/$SCRIPT"
  TARGET="/usr/local/libexec/$SCRIPT"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: libexec script not found: $SOURCE" >&2
    return 1
  fi

  mkdir -p /usr/local/libexec
  install -m 0755 "$SOURCE" "$TARGET"
  echo "  → $SCRIPT"
}

# Install sshd drop-in configuration
# Usage: install_sshd_dropin 10-myconfig.conf
install_sshd_dropin() {
  CONF="$1"
  SOURCE="$PKG_DIR/etc/ssh/sshd_config.d/$CONF"
  TARGET="/etc/ssh/sshd_config.d/$CONF"

  if [ ! -f "$SOURCE" ]; then
    echo "ERROR: sshd config not found: $SOURCE" >&2
    return 1
  fi

  mkdir -p /etc/ssh/sshd_config.d
  install -m 0644 "$SOURCE" "$TARGET"
  echo "  → $CONF"
}

# Reload systemd manager configuration
reload_systemd() {
  echo "→ Reloading systemd"
  systemctl daemon-reload
}

# Reload udev rules
reload_udev() {
  echo "→ Reloading udev"
  udevadm control --reload-rules
  udevadm trigger
}

# Enable and start a systemd unit (idempotent)
# Usage: enable_unit myservice.service
enable_unit() {
  UNIT="$1"
  echo "→ Enabling $UNIT"
  systemctl enable "$UNIT"
}

# Enable and start a systemd timer (idempotent)
# Usage: enable_timer mytimer.timer
enable_timer() {
  TIMER="$1"
  echo "→ Enabling timer $TIMER"
  systemctl enable "$TIMER"
}

# Standard success message
install_success() {
  PKG_NAME="$(basename "$PKG_DIR")"
  echo "✓ $PKG_NAME installed successfully"
}

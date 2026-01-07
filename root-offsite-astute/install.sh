#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

install_unit() {
  UNIT="$1"
  SOURCE="$PKG_DIR/etc/systemd/system/$UNIT"
  TARGET="/etc/systemd/system/$UNIT"

  install -m 0644 "$SOURCE" "$TARGET"
}

install_script() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  mkdir -p "$TARGETDIR"
  install -m 0755 "$SOURCE" "$TARGET"
}

install_config() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  mkdir -p "$TARGETDIR"
  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-offsite-astute (systemd units as real files)"

install_unit borg-offsite-audacious.service
install_unit borg-offsite-audacious.timer
install_unit borg-offsite-astute-critical.service
install_unit borg-offsite-astute-critical.timer
install_unit borg-offsite-check.service
install_unit borg-offsite-check.timer

install_script usr/local/lib/borg-offsite/run-audacious-home.sh
install_script usr/local/lib/borg-offsite/run-astute-critical.sh
install_script usr/local/lib/borg-offsite/run-check.sh
install_config etc/borg-offsite/audacious-home.patterns
install_config etc/borg-offsite/astute-critical.patterns

# Note: stow not used - all files installed directly above
# Patterns files are legacy/unused but kept for potential future use

echo "→ Reloading systemd"
systemctl daemon-reload

echo "✓ root-offsite-astute installed successfully"

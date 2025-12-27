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

echo "Installing root-backup-audacious (systemd units as real files)"

install_unit borg-backup.service
install_unit borg-backup.timer
install_unit borg-check.service
install_unit borg-check.timer
install_unit borg-check-deep.service
install_unit borg-check-deep.timer
install_script usr/local/lib/borg/run-backup.sh
install_script usr/local/lib/borg/run-backup-with-logging.sh
install_script usr/local/lib/borg/run-deep-check.sh
install_script usr/local/lib/borg/wait-for-astute.sh

echo "→ Stowing package (excluding systemd units)"
cd "$DOTFILES_DIR"
stow -t / \
  --ignore='^install\.sh$' \
  --ignore='^\.stow-local-ignore$' \
  --ignore='^README\.md$' \
  --ignore='^etc/systemd/system' \
  --ignore='^usr/local/lib' \
  root-backup-audacious

echo "→ Reloading systemd"
systemctl daemon-reload

echo "✓ root-backup-audacious installed successfully"

#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"
BACKUP_DIR="/var/backups/systemd/root-backup-audacious"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

backup_conflict() {
  TARGET="$1"
  SOURCE="$2"

  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    if [ -L "$TARGET" ]; then
      RESOLVED="$(readlink -f "$TARGET" 2>/dev/null || true)"
      if [ "$RESOLVED" = "$SOURCE" ]; then
        return 0
      fi
    fi

    TS="$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    BASE="$(basename "$TARGET")"
    BACKUP="${BACKUP_DIR}/${BASE}.bak-${TS}"
    echo "→ Backing up $TARGET to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
}

install_unit() {
  UNIT="$1"
  SOURCE="$PKG_DIR/etc/systemd/system/$UNIT"
  TARGET="/etc/systemd/system/$UNIT"

  backup_conflict "$TARGET" "$SOURCE"
  install -m 0644 "$SOURCE" "$TARGET"
}

echo "Installing root-backup-audacious (systemd units as real files)"

install_unit borg-backup.service
install_unit borg-backup.timer
install_unit borg-check.service
install_unit borg-check.timer
install_unit borg-check-deep.service
install_unit borg-check-deep.timer

echo "→ Stowing package (excluding systemd units)"
cd "$DOTFILES_DIR"
stow -t / \
  --ignore='^install\.sh$' \
  --ignore='^\.stow-local-ignore$' \
  --ignore='^README\.md$' \
  --ignore='^etc/systemd/system' \
  root-backup-audacious

echo "→ Reloading systemd"
systemctl daemon-reload

echo "✓ root-backup-audacious installed successfully"

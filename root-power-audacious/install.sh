#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"
BACKUP_DIR="/var/backups/systemd/root-power-audacious"

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

install_udev_rule() {
  RULE="$1"
  SOURCE="$PKG_DIR/etc/udev/rules.d/$RULE"
  TARGET="/etc/udev/rules.d/$RULE"

  mkdir -p /etc/udev/rules.d
  backup_conflict "$TARGET" "$SOURCE"
  install -m 0644 "$SOURCE" "$TARGET"
}

install_script() {
  RELPATH="$1"
  SOURCE="$PKG_DIR/$RELPATH"
  TARGET="/$RELPATH"
  TARGETDIR="$(dirname "$TARGET")"

  mkdir -p "$TARGETDIR"
  backup_conflict "$TARGET" "$SOURCE"
  install -m 0755 "$SOURCE" "$TARGET"
}

echo "Installing root-power-audacious (systemd units as real files)"

install_unit powertop.service
install_unit usb-nosuspend.service
install_script usr/local/sbin/usb-nosuspend.sh
install_udev_rule 50-sata-power.rules
install_udev_rule 61-webcam-nosuspend.rules
install_udev_rule 69-hdparm.rules
install_udev_rule 99-input-nosuspend.rules

echo "→ Stowing package (excluding systemd units)"
cd "$DOTFILES_DIR"
stow -t / \
  --ignore='^install\.sh$' \
  --ignore='^\.stow-local-ignore$' \
  --ignore='^README\.md$' \
  --ignore='^etc/systemd/system' \
  --ignore='^etc/udev' \
  --ignore='^usr/local/sbin' \
  root-power-audacious

echo "→ Reloading systemd"
systemctl daemon-reload

echo "✓ root-power-audacious installed successfully"

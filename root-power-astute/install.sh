#!/bin/sh
set -eu

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$PKG_DIR")"

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
    BACKUP="${TARGET}.bak-${TS}"
    echo "→ Backing up $TARGET to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
}

install_unit() {
  UNIT="$1"
  SOURCE="$PKG_DIR/etc/systemd/system/$UNIT"
  TARGET="/etc/systemd/system/$UNIT"

  mkdir -p /etc/systemd/system
  backup_conflict "$TARGET" "$SOURCE"
  install -m 0644 "$SOURCE" "$TARGET"
}

install_modprobe() {
  CONF="$1"
  SOURCE="$PKG_DIR/etc/modprobe.d/$CONF"
  TARGET="/etc/modprobe.d/$CONF"

  mkdir -p /etc/modprobe.d
  backup_conflict "$TARGET" "$SOURCE"
  install -m 0644 "$SOURCE" "$TARGET"
}

install_libexec() {
  SCRIPT="$1"
  SOURCE="$PKG_DIR/usr/local/libexec/$SCRIPT"
  TARGET="/usr/local/libexec/$SCRIPT"

  mkdir -p /usr/local/libexec
  backup_conflict "$TARGET" "$SOURCE"
  install -m 0755 "$SOURCE" "$TARGET"
}

echo "Installing root-power-astute (Astute power policy)"

install_unit astute-idle-suspend.service
install_unit astute-idle-suspend.timer
install_unit nas-inhibit.service
install_unit powertop.service

install_modprobe blacklist-gpu.conf
install_modprobe blacklist-watchdog.conf

install_libexec astute-idle-check.sh
install_libexec astute-nas-inhibit.sh

echo "→ Installing sudoers rule (nas-inhibit)"
backup_conflict /etc/sudoers.d/nas-inhibit \
  "$PKG_DIR/etc/sudoers.d/nas-inhibit.sudoers"
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-inhibit.sudoers" \
  /etc/sudoers.d/nas-inhibit

echo "→ Reloading systemd"
systemctl daemon-reload

echo "→ Validating sudoers"
visudo -c

echo "✓ root-power-astute installed successfully"

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

install_udev_rule() {
  RULE="$1"
  SOURCE="$PKG_DIR/etc/udev/rules.d/$RULE"
  TARGET="/etc/udev/rules.d/$RULE"

  mkdir -p /etc/udev/rules.d
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

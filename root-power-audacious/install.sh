#!/bin/sh
# Install root-power-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

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

reload_systemd
install_success

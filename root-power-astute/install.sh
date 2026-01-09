#!/bin/sh
# Install root-power-astute package

PKG_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

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
install -o root -g root -m 0440 \
  "$PKG_DIR/etc/sudoers.d/nas-inhibit.sudoers" \
  /etc/sudoers.d/nas-inhibit

reload_systemd

echo "→ Validating sudoers"
visudo -c

install_success

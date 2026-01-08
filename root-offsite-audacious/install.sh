#!/bin/sh
# Install root-offsite-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-offsite-audacious (systemd units as real files)"

install_unit borg-offsite-audacious.service
install_unit borg-offsite-audacious.timer
install_unit borg-offsite-check.service
install_unit borg-offsite-check.timer

install_script usr/local/lib/borg-offsite/run-audacious-home.sh
install_script usr/local/lib/borg-offsite/run-check.sh

reload_systemd
install_success

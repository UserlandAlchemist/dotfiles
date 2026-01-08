#!/bin/sh
# Install root-offsite-astute package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-offsite-astute (systemd units as real files)"

install_unit borg-offsite-astute-critical.service
install_unit borg-offsite-astute-critical.timer
install_unit borg-offsite-check.service
install_unit borg-offsite-check.timer

install_script usr/local/lib/borg-offsite/run-astute-critical.sh
install_script usr/local/lib/borg-offsite/run-check.sh
install_config etc/borg-offsite/astute-critical.patterns

# Note: stow not used - all files installed directly above
# Patterns files are legacy/unused but kept for potential future use

reload_systemd
install_success

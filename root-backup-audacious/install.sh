#!/bin/sh
# Install root-backup-audacious package

PKG_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

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

reload_systemd
install_success

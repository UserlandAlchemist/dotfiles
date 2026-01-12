#!/bin/sh
# Install root-journald-audacious package

PKG_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-journald-audacious (general system configuration)"

# Install systemd configs as real files (no symlinks to /home)
# This overrides Debian's /usr/lib/systemd/journald.conf.d/syslog.conf
install_config etc/systemd/journald.conf.d/syslog.conf

# Ensure journald waits for /var mount (separate ZFS dataset)
install_config etc/systemd/system/systemd-journald.service.d/wait-for-var.conf

echo "→ Stowing package (excluding systemd configs)"
cd "$DOTFILES_DIR"
stow -t / \
	--ignore='^install\.sh$' \
	--ignore='^\.stow-local-ignore$' \
	--ignore='^README\.md$' \
	--ignore='^etc/systemd' \
	root-journald-audacious

reload_systemd
install_success

echo ""
echo "Changes applied:"
echo "  - journald ForwardToSyslog override"
echo "  - journald waits for /var mount (ZFS dataset)"
echo ""
echo "Reboot to verify journald persistent storage at boot:"
echo "  sudo reboot"

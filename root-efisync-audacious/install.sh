#!/bin/sh
# Install root-efisync-audacious package

PKG_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$(dirname "$PKG_DIR")/lib/install.sh"

echo "Installing root-efisync-audacious (systemd units as real files)"

install_unit efi-sync.service
install_unit efi-sync.path

echo "→ Stowing package (excluding systemd units)"
cd "$DOTFILES_DIR"
stow -t / \
	--ignore='^install\.sh$' \
	--ignore='^\.stow-local-ignore$' \
	--ignore='^README\.md$' \
	--ignore='^etc/systemd/system' \
	root-efisync-audacious

reload_systemd
install_success
